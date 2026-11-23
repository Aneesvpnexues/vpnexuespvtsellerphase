import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../data/seller_product_repository.dart';
import '../data/seller_profile_store.dart';
import '../data/session_store.dart';
import '../data/supabase_product_api.dart';
import '../data/wallet_store.dart';
import '../screens/location_confirm_screen.dart';
import '../screens/seller_home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_seller_screen.dart';
import 'auth_flow.dart';
import 'onboarding_flow.dart';
import 'session_guard.dart';

/// Where a cold start continues.
enum ColdStart {
  /// Fresh install: the splash artwork, tapped once, then Welcome.
  firstRunSplash,

  /// No session — Welcome / Login / Sign Up.
  welcome,

  /// Signed in through Login (OTP), or with every onboarding section
  /// finished — Home.
  home,

  /// A Sign Up session whose registration is still unfinished: resume that
  /// step. Login sessions never resolve here.
  onboardingStep,
}

/// The single place that decides what the app opens on, and the background
/// work that keeps that decision correct over time.
///
/// The decision itself is **synchronous** and runs before the first frame
/// (from [SellerApp.build], using the stores hydrated in `main()`), so a
/// signed-in seller lands on Home with no splash, no Welcome and no spinner
/// in between, and a fresh install lands on the splash artwork before
/// anything else exists to land on.
///
/// Everything slow — Firebase's session restore, a token refresh, the
/// Supabase profile/bank/KYC merge, product and wallet refreshes — happens
/// afterwards in [restoreSessionInBackground]. That work enriches the stores
/// already on screen; it never navigates, so a slow or unreachable backend
/// can only affect what the current screen shows, never where the app put
/// the seller.
class ColdStartRouter {
  const ColdStartRouter._();

  /// Where this launch continues, decided purely from what this device has
  /// persisted. No awaits, no network.
  ///
  /// The order matters:
  ///  1. the one-time splash flag wins outright — it is only false right
  ///     after installation (or if the preferences were wiped), which is
  ///     exactly when the artwork must show;
  ///  2. without a session the destination is Welcome, whether the seller
  ///     logged out or has never signed in;
  ///  3. a session opened by Login (OTP) always continues on Home — its
  ///     onboarding completion flags never send it back to an unfinished
  ///     step;
  ///  4. a Sign Up session resumes from the persisted flags: the first
  ///     unfinished step, or Home when there is none.
  ///
  /// Those flags are written the moment each step succeeds and are re-merged
  /// from Supabase in the background, so they are a faithful resume point for
  /// a sign-up session on this device. A *reinstall* has no local session at
  /// all — it is routed by the OTP flow instead, which always opens Home.
  static ColdStart resolve() {
    if (!SplashScreen.hasSeenSplash) return ColdStart.firstRunSplash;

    final SessionStore session = SessionStore.instance;
    if (!session.isAuthenticated) return ColdStart.welcome;

    // Login (OTP) sessions — and any session from an older build that
    // recorded no method — open Home outright: a seller who signed in is
    // never walked back through onboarding, however incomplete their
    // registration is. Only an explicit Sign Up session may resume a step.
    if (session.method != SessionStore.signupMethod) return ColdStart.home;

    return OnboardingFlow.isComplete(SellerProfileStore.instance)
        ? ColdStart.home
        : ColdStart.onboardingStep;
  }

  /// The screen for [start].
  static Widget screenFor(ColdStart start) {
    switch (start) {
      case ColdStart.firstRunSplash:
        return const SplashScreen();
      case ColdStart.welcome:
        return const WelcomeSellerScreen();
      case ColdStart.home:
        return const SellerHomeScreen();
      case ColdStart.onboardingStep:
        return OnboardingFlow.firstIncompleteStep(
          SellerProfileStore.instance,
        );
    }
  }

  /// Navigates to [resolve]'s destination, dropping everything on screen.
  static void route(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => screenFor(resolve())),
      (Route<dynamic> _) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND SESSION RESTORE
  // ---------------------------------------------------------------------------

  /// Brings this seller's data back after the destination is already on
  /// screen, and checks that the session is still alive.
  ///
  /// Ported from the old splash-screen restore minus its navigation: the
  /// route was chosen before the first frame from the same persisted state,
  /// so everything here is enrichment (identity wiring, cached rows, server
  /// merge) plus the one exception that may still navigate — an
  /// [AuthHealth.invalid] answer, which means Firebase itself said the
  /// account is gone.
  static Future<void> restoreSessionInBackground() async {
    final SessionStore session = SessionStore.instance;
    if (!session.isAuthenticated) return;

    try {
      // --- identity -------------------------------------------------------
      String uid = session.uid.trim();
      String phone = session.phone;

      final User? user = await _firebaseUser();
      if (user != null) {
        uid = user.uid.trim();
        phone = user.phoneNumber ?? phone;
      }

      // A session opened by Sign Up has no Firebase uid yet; keeping the
      // pending registration id recorded at sign-up (rather than wiping it)
      // is what keeps every pre-OTP write keyed to the same seller.
      if (uid.isNotEmpty) {
        AuthFlow.instance.firebaseUid = uid;
        AuthFlow.instance.verified = true;
      }

      final SellerProfileStore store = SellerProfileStore.instance;
      ProductStore.instance.userId = uid;
      if (uid.isNotEmpty) store.userId = uid;

      // --- is the session still real? ------------------------------------
      // Runs after the route is set: a failure to refresh may only send the
      // seller to Welcome when the server *proved* the account is gone.
      final AuthHealth health = await SessionGuard.instance.validate();
      if (health == AuthHealth.invalid) {
        await SessionGuard.instance.endInvalidSession();
        return;
      }

      // Pre-OTP Sign Up session: local rows and flags are the whole truth
      // and there is no Firebase identity to query anything with. Wiring the
      // registration id above is all that is needed — a phone-only match
      // could land on somebody else's row.
      if (uid.isEmpty) return;

      // --- refresh this seller's data ------------------------------------
      // No pre-clear: `refresh` replaces the remote rows and keeps the
      // device-only ones, so the listings already on screen stay put until
      // the fetch answers instead of flashing empty. Products saved on this
      // device are re-hydrated inside `refresh`, so an unreachable backend
      // still costs the seller nothing.
      WalletStore.instance.reset();

      LocationConfirmScreen.retryPendingLocation(uid: uid, phone: phone);

      try {
        await SellerProductRepository().refresh(ProductStore.instance);
      } catch (_) {
        // Offline start: Home keeps whatever is cached locally.
      }

      // Pull the wallet ledger in the background — Profile reads it later.
      unawaited(WalletStore.instance.refresh());

      if (phone.trim().isNotEmpty) {
        await _mergeServerCompletion(uid: uid, phone: phone, store: store);
      }
    } catch (error, stack) {
      // Whatever went wrong, the seller is already on their destination and
      // the persisted state is untouched, so the next launch simply tries
      // again.
      debugPrint('[ColdStartRouter] background restore failed: $error\n$stack');
    }
  }

  /// Reads this seller's Supabase rows and folds them into the flags already
  /// on this device.
  ///
  /// The merge is one-way: a section this device has finished stays finished
  /// even if the backend row lags behind (the same rule
  /// [SellerBackendSync.mergeCompletion] applies), and nothing is ever reset
  /// first — a merge that dies half way must not be able to send a finished
  /// seller back through onboarding on the next launch.
  static Future<void> _mergeServerCompletion({
    required String uid,
    required String phone,
    required SellerProfileStore store,
  }) async {
    try {
      final SupabaseProductApi api = SupabaseProductApi();
      api.userId = uid;
      final Map<String, dynamic>? profile =
          await api.getProfileByPhone(phone, userId: uid);

      final String profileUserId =
          (profile?['user_id'] ?? '').toString().trim();

      // Products live under the Firebase UID; profile/bank/KYC rows may also
      // carry a legacy backend id, so check both.
      final List<String> candidateIds = <String>{
        uid,
        profileUserId,
      }.where((String id) => id.trim().isNotEmpty).toList();

      Map<String, dynamic>? bankDetails;
      Map<String, dynamic>? verificationDetails;
      if (candidateIds.isNotEmpty) {
        final List<Map<String, dynamic>> accounts =
            await api.getBankDetailsForUsers(candidateIds);
        // Most complete row, never `first`: older builds saved a half-filled
        // row per attempt, and the oldest one wrongly kept bankComplete false
        // — sending sellers back to the bank page even when a complete row
        // existed.
        bankDetails = SupabaseProductApi.mostCompleteBankAccount(accounts);
        // Publish every row so Profile / Bank show the saved account
        // immediately instead of a placeholder.
        store.setBankAccounts(accounts);
        verificationDetails = await api.getVerificationForUsers(candidateIds);

        if (store.userId.isNotEmpty) {
          store.setActiveBankAccountId(
            await api.getActiveBankAccountId(store.userId),
          );
        }
      }

      if (profile != null) _populateProfileStore(profile);

      final bool locationComplete = store.locationComplete ||
          (profile != null && _isLocationComplete(profile));
      final bool profileComplete = store.profileComplete ||
          (profile != null && _isProfileComplete(profile));
      final bool personalComplete = store.personalComplete ||
          (profile != null && _isPersonalComplete(profile));
      final bool bankComplete =
          store.bankComplete || (bankDetails != null && _isBankComplete(bankDetails));
      final bool verificationComplete = store.verificationComplete ||
          (verificationDetails != null &&
              _isVerificationComplete(verificationDetails));

      // Persist the merged answer so the next launch resumes from exactly
      // here, even when this backend could not be reached on that one.
      store.setCompletion(
        profileComplete: profileComplete,
        bankComplete: bankComplete,
        verificationComplete: verificationComplete,
        personalComplete: personalComplete,
      );
      store.setLocationComplete(locationComplete);
      // STEP 02 (seller type) has no Supabase column of its own, but it can
      // only have been passed once STEP 03 business details exist — so a
      // restored profile marks it answered too.
      store.setSellerTypeComplete(store.sellerTypeComplete || profileComplete);
    } catch (_) {
      // Supabase unreachable — the flags saved on this device stay exactly
      // as they were, and the next launch merges again.
    }
  }

  /// Returns the Firebase user for this device, or null.
  ///
  /// Waits for the first auth-state event before reading [currentUser]: on a
  /// cold start Firebase may still be restoring its own persisted user while
  /// the first frame builds, and mistaking that instant for "signed out"
  /// would drop the uid every user-scoped lookup depends on. A missing
  /// Firebase app, an error or a timeout all just mean "no Firebase user" —
  /// the local session still decides everything.
  static Future<User?> _firebaseUser() async {
    try {
      await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Whether the seller profile (Business Details) section is complete based
  /// on required Supabase fields being non-empty.
  static bool _isProfileComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['business_name'] ?? '',
      profile['location'] ?? '',
      profile['business_address'] ?? '',
    ];
    return fields.every((value) => value.toString().trim().isNotEmpty);
  }

  /// Whether STEP 01 (Location) has been answered: the profile row carries
  /// both the label and the full address.
  static bool _isLocationComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['location'] ?? '',
      profile['business_address'] ?? '',
    ];
    return fields.every((value) => value.toString().trim().isNotEmpty);
  }

  /// Whether the Personal Details section is complete based on required
  /// Supabase fields being non-empty.
  static bool _isPersonalComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['display_name'] ?? '',
      profile['phone_number'] ?? '',
    ];
    return fields.every((value) => value.toString().trim().isNotEmpty);
  }

  /// Whether bank details are complete based on required fields.
  static bool _isBankComplete(Map<String, dynamic> bank) {
    final fields = <String>[
      bank['account_houlder_name'] ?? '',
      bank['bank_name'] ?? '',
      bank['account_number'] ?? '',
      bank['IFSC_code'] ?? '',
    ];
    return fields.every((value) => value.toString().trim().isNotEmpty);
  }

  /// Whether verification/KYC is complete based on at least one document URL
  /// **or** file name being present (the metadata-only path writes file names
  /// when nothing is uploaded to Cloudinary yet).
  static bool _isVerificationComplete(Map<String, dynamic> verification) {
    final fields = <String>[
      verification['aadhaar_card'] ?? '',
      verification['pan_card'] ?? '',
      verification['business_registration'] ?? '',
      verification['aadhaar_file_name'] ?? '',
      verification['pan_file_name'] ?? '',
      verification['business_file_name'] ?? '',
    ];
    return fields.any((value) => value.toString().trim().isNotEmpty);
  }

  /// Populates the in-memory profile store from a Supabase profile record.
  static void _populateProfileStore(Map<String, dynamic> profile) {
    final String name = (profile['display_name'] ?? '').toString().trim();
    final String mobile = (profile['phone_number'] ?? '').toString().trim();
    // Location/address live on the profile row too — without them every
    // home/profile/order screen shows the hardcoded placeholder forever.
    final String location = (profile['location'] ?? '').toString().trim();
    final String address =
        (profile['business_address'] ?? '').toString().trim();
    final String business =
        (profile['business_name'] ?? '').toString().trim();
    final String sellerTypeStr =
        (profile['seller_type'] ?? '').toString().trim().toLowerCase();

    SellerProfileStore.instance.setBusinessLocation(
      location: location,
      address: address,
    );
    // A seller type stored on the row means STEP 02 was answered — restore
    // it so Profile / Personal Details show the saved choice instead of the
    // default. An empty (legacy) value leaves whatever this device knows.
    if (sellerTypeStr.isNotEmpty) {
      switch (sellerTypeStr) {
        case 'trader':
          SellerProfileStore.instance.setSellerType(SellerType.trader);
        case 'fpo':
          SellerProfileStore.instance.setSellerType(SellerType.fpo);
        case 'farmer':
          SellerProfileStore.instance.setSellerType(SellerType.farmer);
      }
    }
    if (name.isNotEmpty) {
      SellerProfileStore.instance.saveBusinessDetails(
        name: name,
        business: business.isNotEmpty ? business : name,
        phone: mobile,
        location: location,
        address: address,
        farmSize: '',
      );
    } else {
      SellerProfileStore.instance.mobile = mobile;
    }
  }
}
