import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/app_storage.dart';
import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/seller_product_repository.dart';
import '../data/session_store.dart';
import '../data/supabase_product_api.dart';
import '../data/wallet_store.dart';
import '../services/auth_flow.dart';
import '../theme/app_colors.dart';
import '../screens/bank_detaile.dart';
import '../screens/business_details_screen.dart';
import '../screens/location_confirm_screen.dart';
import '../screens/seller_home_screen.dart';
import '../screens/verify_detaile.dart';
import '../screens/welcome_seller_screen.dart';

/// First screen shown when the app opens — static replica of Zeplin
/// "Android Compact - 192" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad7318de3f9d49c8cec78ca).
///
/// The artwork is a single full-bleed export (the STEP lockup, smiley and
/// tomato photo are part of the illustration), with the design's status-bar
/// strip trimmed off so the real platform status bar sits on the empty
/// background instead. The image is anchored to the top and scaled to cover
/// the area below the status bar, so the bottom of the photo still bleeds off
/// the screen like the design.
///
/// The circular arrow button in the bottom-right is a real widget (a black
/// disc with a white arrow) rather than a bare hit target: the artwork no
/// longer paints an arrow, so the button has to be drawn by the app itself.
///
/// There is no auto-advance on a first run: the splash stays up until the
/// seller taps that button, which continues to [WelcomeSellerScreen]. The
/// navigation uses `pushReplacement`, so the splash never stays in the back
/// stack.
///
/// On cold start, [_SplashScreenState] restores the locally persisted
/// session ([SessionStore]) — the record that the Login (OTP) and Sign Up
/// flows both write and that only Logout removes. A session opened by
/// **login** resumes straight on the home page — the same destination the
/// OTP flow uses — while a session opened by **sign-up** resumes at the
/// first incomplete onboarding section, read from the flags saved on this
/// device, so a pending page is never skipped in favour of Home. Without a
/// session the splash remains and tapping the arrow opens the login flow.
///
/// The splash is shown only once per install: the first launch after
/// installing. Tapping the arrow (or an automatic session resume) persists
/// [StorageKeys.splashSeenKey]; every later launch renders a plain background
/// — no artwork, no tap required — and routes straight to the last reached
/// destination. Uninstalling the app clears the preference, so the splash
/// returns on the next fresh install.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String splashAsset = 'assets/splash/splash.png';

  /// The design's top 44px status-bar strip was cropped from [splashAsset].
  static const double designWidth = 412;
  static const double designHeight = 873;

  /// Test seam: when set, the splash treats this seller as the signed-in
  /// session instead of asking Firebase Auth, so widget tests can exercise
  /// the session-restore routing without a Firebase app.
  @visibleForTesting
  static ({String uid, String phone})? debugSignedInSeller;

  /// Whether the one-time splash has already been dismissed on this install.
  ///
  /// Read synchronously from the preferences hydrated in `main()`, so
  /// [SellerApp] can decide at build time whether to show the splash at all.
  static bool get hasSeenSplash =>
      AppStorage.current?.readString(StorageKeys.splashSeenKey) == 'true';

  /// Records that the splash has been shown, so the next launch skips it.
  /// Fire-and-forget like the other stores; a failed write only means the
  /// splash shows again on the next launch.
  static void markSplashSeen() {
    AppStorage.current
        ?.writeString(StorageKeys.splashSeenKey, 'true')
        .ignore();
  }

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// True when this launch is the very first one after installing: only then
  /// are the artwork and its arrow button painted. Later launches render a
  /// plain background and route on their own, so the splash never reappears.
  late final bool _firstRun = !SplashScreen.hasSeenSplash;

  /// True while the cold-start Firebase session check runs; the arrow stays
  /// hidden until the check decides whether to resume automatically.
  bool _checking = true;

  /// Recovery flag: an unexpected error during the session check brings the
  /// artwork and its button back — even on a later launch — so the seller can
  /// always tap through instead of being stranded on a blank screen.
  bool _holdForRetry = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// Guards the cold-start check: whatever happens while restoring the
  /// session, the seller always ends up somewhere tappable.
  Future<void> _checkSession() async {
    try {
      await _restoreSession();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _holdForRetry = true;
      });
    }
  }

  /// On cold start, decide where this launch continues.
  ///
  /// The locally persisted [SessionStore] is the authority: it is written by
  /// both the OTP login flow and the Sign Up form, and removed only by
  /// Logout, so an authenticated seller is never sent back to the Welcome
  /// screen. Firebase Auth is consulted only to enrich that record with the
  /// live UID and verified phone number — a sign-up session has no Firebase
  /// user, and a Firebase session that failed to restore is not a logout.
  ///
  /// A session opened by **login** (OTP) continues straight on Home — exactly
  /// like the OTP flow — after that seller's rows have been re-fetched. A
  /// session opened by **sign-up** resumes at the first incomplete onboarding
  /// section, decided from the flags persisted on this device (merged with
  /// Supabase when a UID exists to query it with), so a pending page cannot
  /// be skipped. Without a session a first run stays on the splash so the
  /// user can tap to log in; a later run skips the artwork and opens Welcome.
  Future<void> _restoreSession() async {
    if (!mounted) return;

    final SessionStore session = SessionStore.instance;
    final ({String uid, String phone})? debugSeller =
        SplashScreen.debugSignedInSeller;

    // No persisted record means there is nothing to resume — Logout deletes
    // that record, which is exactly what makes signing out stick across
    // restarts.
    if (!session.isAuthenticated && debugSeller == null) {
      if (_firstRun) {
        // First run without a session: the artwork stays up and the arrow
        // button opens the login flow.
        setState(() => _checking = false);
      } else {
        // Later launch without a session: no artwork at all — continue on
        // the Welcome / login screen as soon as the first frame is on
        // screen.
        WidgetsBinding.instance.addPostFrameCallback((_) => _openWelcome());
      }
      return;
    }

    // UID and phone: the live Firebase user when there is one, otherwise the
    // values the session recorded when the seller signed in.
    String uid = session.uid.trim();
    String phone = session.phone;
    if (debugSeller != null) {
      uid = debugSeller.uid.trim();
      phone = debugSeller.phone;
    } else {
      final User? firebaseUser = await _firebaseUser();
      if (firebaseUser != null) {
        uid = firebaseUser.uid.trim();
        phone = firebaseUser.phoneNumber ?? phone;
      }
    }

    if (!mounted) return;

    // A resumed session means the one-time splash has been served, so the
    // next launch goes straight to the destination instead of the artwork.
    SplashScreen.markSplashSeen();

    if (uid.isNotEmpty) {
      AuthFlow.instance.firebaseUid = uid;
      AuthFlow.instance.verified = true;
    }

    final SellerProfileStore store = SellerProfileStore.instance;

    // Capture what this device has already finished *before* the flags are
    // cleared below: the clear stops stale in-memory state leaking into the
    // refetch, and a refetch that never arrives (offline start) must not
    // wipe a section the seller has completed.
    bool locationComplete = store.locationComplete;
    bool profileComplete = store.profileComplete;
    bool bankComplete = store.bankComplete;
    bool verificationComplete = store.verificationComplete;
    bool personalComplete = store.personalComplete;

    // Clear any stale data from a previous login session.
    store.resetCompletionFlags();
    ProductStore.instance.clear();
    WalletStore.instance.reset();

    // Set the user_id for product queries and all user-scoped lookups.
    ProductStore.instance.userId = uid;
    store.userId = uid;

    if (uid.isNotEmpty) {
      // Retry a location write that failed while offline (marker left by
      // LocationConfirmScreen). Runs in the background; the store hydration
      // below still shows the last-known address meanwhile.
      LocationConfirmScreen.retryPendingLocation(uid: uid, phone: phone);

      // Always re-fetch this user's products from Supabase so they persist
      // across app restarts.
      try {
        await SellerProductRepository().refresh(ProductStore.instance);
      } catch (_) {
        // Home still opens with whatever products are cached locally.
      }

      // Pull the wallet ledger in the background — Profile reads it later.
      unawaited(WalletStore.instance.refresh());

      // Look up this seller's Supabase rows by the verified phone number.
      // Number-agnostic: exact E.164 -> last 10 digits -> Firebase UID, and
      // bank/KYC are always checked under both candidate ids.
      //
      // A sign-up session usually has neither a UID nor a Firebase user, and
      // then no lookup runs at all: its route comes from the flags persisted
      // on this device, and a phone-only match could land on somebody else's
      // row.
      if (mounted) {
        try {
          final api = SupabaseProductApi();
          api.userId = uid;
          final profile = await api.getProfileByPhone(phone, userId: uid);

          final String profileUserId =
              (profile?['user_id'] ?? '').toString().trim();

          // Products live under the Firebase UID; profile/bank/KYC rows may
          // also carry a legacy backend id, so check both.
          final List<String> candidateIds = <String>{
            uid,
            profileUserId,
          }.where((String id) => id.trim().isNotEmpty).toList();

          Map<String, dynamic>? bankDetails;
          Map<String, dynamic>? verificationDetails;
          if (candidateIds.isNotEmpty) {
            final accounts = await api.getBankDetailsForUsers(candidateIds);
            // Most complete row, never `first`: older builds saved a
            // half-filled row per attempt, and the oldest one wrongly kept
            // bankComplete false — sending sellers back to the bank page
            // even when a complete row existed.
            bankDetails = SupabaseProductApi.mostCompleteBankAccount(accounts);
            // Publish every row to the store so Profile / Bank screens show
            // the saved account immediately instead of a placeholder.
            store.setBankAccounts(accounts);
            verificationDetails =
                await api.getVerificationForUsers(candidateIds);

            // Load active bank account ID from seller_profiles
            if (store.userId.isNotEmpty) {
              final activeBankId = await api.getActiveBankAccountId(
                store.userId,
              );
              store.setActiveBankAccountId(activeBankId);
            }
          }

          final bool foundAnyRow = profile != null ||
              bankDetails != null ||
              verificationDetails != null;

          if (foundAnyRow && mounted) {
            if (profile != null) {
              _populateProfileStore(profile);
            }

            // Merge with what this device already recorded: a section the
            // seller finished here is never asked for again, even when the
            // backend row lags behind (the same rule
            // SellerBackendSync.mergeCompletion applies).
            locationComplete = locationComplete ||
                (profile != null && _isLocationComplete(profile));
            profileComplete = profileComplete ||
                (profile != null && _isProfileComplete(profile));
            personalComplete = personalComplete ||
                (profile != null && _isPersonalComplete(profile));
            bankComplete =
                bankComplete || (bankDetails != null && _isBankComplete(bankDetails));
            verificationComplete = verificationComplete ||
                (verificationDetails != null &&
                    _isVerificationComplete(verificationDetails));
          }
        } catch (_) {
          // Supabase lookup failed — the flags saved on this device still
          // decide the route below.
        }
      }
    }

    if (!mounted) return;

    // Persist the merged answer so the next launch resumes from exactly
    // here, even when the backend could not be reached on this one.
    store.setCompletion(
      profileComplete: profileComplete,
      bankComplete: bankComplete,
      verificationComplete: verificationComplete,
      personalComplete: personalComplete,
    );
    store.setLocationComplete(locationComplete);

    // A login session continues straight on Home (the OTP flow sends the
    // seller to the same place); a sign-up session — and a record saved by
    // an older build, which stored no method — still walks the onboarding
    // steps so no pending page is skipped in favour of Home.
    if (session.method == SessionStore.loginMethod) {
      _openHome();
    } else {
      _navigateBasedOnCompletion(
        profileComplete: profileComplete,
        bankComplete: bankComplete,
        verificationComplete: verificationComplete,
        personalComplete: personalComplete,
        locationComplete: locationComplete,
      );
    }
  }

  /// Returns the Firebase user for this device, or null.
  ///
  /// Waits for the first auth-state event before reading [currentUser]: on a
  /// cold start Firebase may still be restoring its own persisted user while
  /// the splash is building, and mistaking that instant for "signed out"
  /// would send a logged-in seller back to the Welcome screen. A missing
  /// Firebase app, an error or a timeout all just mean "no Firebase user" —
  /// the local session still decides the route.
  Future<User?> _firebaseUser() async {
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

  /// Determines whether the seller profile (Business Details) section is
  /// complete based on required Supabase fields being non-empty.
  bool _isProfileComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['business_name'] ?? '',
      profile['location'] ?? '',
      profile['business_address'] ?? '',
    ];
    return fields.every(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Determines whether the Personal Details section is complete based on
  /// required Supabase fields being non-empty.
  bool _isPersonalComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['display_name'] ?? '',
      profile['phone_number'] ?? '',
    ];
    return fields.every(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Determines whether the Location section is complete based on
  /// location/address being non-empty.
  bool _isLocationComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['location'] ?? '',
      profile['business_address'] ?? '',
    ];
    return fields.every(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Determines whether bank details are complete based on required fields.
  bool _isBankComplete(Map<String, dynamic> bank) {
    final fields = <String>[
      bank['account_houlder_name'] ?? '',
      bank['bank_name'] ?? '',
      bank['account_number'] ?? '',
      bank['IFSC_code'] ?? '',
    ];
    return fields.every(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Determines whether verification/KYC is complete based on at least one
  /// document URL being present.
  bool _isVerificationComplete(Map<String, dynamic> verification) {
    final fields = <String>[
      verification['aadhaar_card'] ?? '',
      verification['pan_card'] ?? '',
      verification['business_registration'] ?? '',
    ];
    return fields.any(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Navigates to the first incomplete onboarding step:
  /// [Location Confirm] -> [Seller Type / Business Details] -> [Verify (KYC)] -> [Bank Details] -> Home
  void _navigateBasedOnCompletion({
    required bool profileComplete,
    required bool bankComplete,
    required bool verificationComplete,
    required bool personalComplete,
    bool locationComplete = true,
  }) {
    if (!mounted) return;

    if (!locationComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LocationConfirmScreen(),
        ),
      );
      return;
    }

    if (!profileComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const Step03BusinessDetailsScreen(),
        ),
      );
      return;
    }

    if (!verificationComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const VerifyDetaileScreen(),
        ),
      );
      return;
    }

    if (!bankComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const BankDetaileScreen(),
        ),
      );
      return;
    }

    // All sections complete — go straight to Home.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SellerHomeScreen()),
    );
  }

  /// Populate the in-memory profile store from a Supabase profile record.
  void _populateProfileStore(Map<String, dynamic> profile) {
    final String name = (profile['display_name'] ?? '').toString().trim();
    final String mobile = (profile['phone_number'] ?? '').toString().trim();
    // The seller's chosen location travels with the profile row: it must be
    // restored, otherwise every screen falls back to a placeholder city and
    // the place picked during login disappears (BUG_SELLER_023).
    final String location =
        (profile['location'] ?? '').toString().trim();
    final String address =
        (profile['business_address'] ?? '').toString().trim();
    final String business =
        (profile['business_name'] ?? '').toString().trim();
    final String sellerTypeStr =
        (profile['seller_type'] ?? 'farmer').toString().trim().toLowerCase();
    SellerType sellerType;
    switch (sellerTypeStr) {
      case 'trader':
        sellerType = SellerType.trader;
      case 'fpo':
        sellerType = SellerType.fpo;
      default:
        sellerType = SellerType.farmer;
    }
    // Set location even when no name exists yet so the address shows up
    // regardless of how far onboarding has progressed.
    SellerProfileStore.instance.setBusinessLocation(
      location: location,
      address: address,
    );
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

  /// Records that the one-time splash has been served, then opens the
  /// Welcome / login screen. This is the only place a tap dismisses the
  /// splash, so it is also what makes later launches skip the artwork.
  void _continueToLogin() {
    SplashScreen.markSplashSeen();
    _openWelcome();
  }

  /// Opens the Welcome / login screen, clearing the splash from the stack.
  void _openWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WelcomeSellerScreen()),
    );
  }

  /// Opens the home page, clearing the splash from the stack.
  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SellerHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Later launches skip the artwork entirely: a plain background with a
    // small spinner while the session check runs, so the splash itself is
    // only ever seen once per install.
    if (!_firstRun && !_holdForRetry) {
      return Scaffold(
        backgroundColor: AppColors.splashBg,
        body: Center(
          child: _checking
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                SplashScreen.splashAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                semanticLabel: 'A small step for your big growth',
              ),
            ),
            // The artwork no longer paints an arrow, so the continue button
            // is a real widget: a black disc with a white arrow in the
            // bottom-right corner. It appears once the session check has
            // decided the seller has to tap through to the login flow.
            if (!_checking)
              Positioned(
                right: 24,
                bottom: 24,
                child: Material(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: InkWell(
                    key: const Key('splashTap'),
                    customBorder: const CircleBorder(),
                    onTap: _continueToLogin,
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.arrow_forward,
                        color: Color.fromARGB(255, 255, 255, 255),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
