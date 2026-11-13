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
import '../screens/location_screen.dart';
import '../screens/personal_details_screen.dart';
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
/// On cold start, [_SplashScreenState] checks whether a Firebase Auth session
/// already exists. A session opened by **login** (OTP) resumes straight on the
/// home page — the same destination the OTP flow uses — while a session opened
/// by **sign-up** resumes at the first incomplete onboarding section (or STEP
/// 01 when nothing has been saved yet), so a pending page is never skipped in
/// favour of Home. Without a session the splash remains and tapping the arrow
/// opens the login flow.
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

  /// On cold start, check whether a Firebase Auth session already exists.
  /// If signed in, restore [AuthFlow.instance.firebaseUid], re-fetch that
  /// user's products from Supabase and check Supabase for an existing profile
  /// matching the verified phone number. A session opened by login (OTP)
  /// continues straight on Home — exactly like the OTP flow — while a
  /// sign-up session resumes at the first incomplete onboarding section (or
  /// STEP 01 when nothing has been saved yet), so a pending page cannot be
  /// skipped. Without a session a first run stays on the splash so the user
  /// can tap to log in; a later run skips the artwork and opens Welcome.
  Future<void> _restoreSession() async {
    if (!mounted) return;

    String? uid;
    String? phone;
    final ({String uid, String phone})? debugSeller =
        SplashScreen.debugSignedInSeller;
    if (debugSeller != null) {
      uid = debugSeller.uid;
      phone = debugSeller.phone;
    } else {
      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
      } catch (_) {
        currentUser = null;
      }
      uid = currentUser?.uid;
      phone = currentUser?.phoneNumber;
    }

    if (!mounted) return;
    if (uid != null && uid.isNotEmpty) {
      AuthFlow.instance.firebaseUid = uid;
      AuthFlow.instance.verified = true;

      // A resumed session means the one-time splash has been served, so the
      // next launch goes straight to the destination instead of the artwork.
      SplashScreen.markSplashSeen();

      // Clear any stale data from a previous login session.
      SellerProfileStore.instance.resetCompletionFlags();
      ProductStore.instance.clear();
      WalletStore.instance.reset();

      // Set the user_id for product queries and all user-scoped lookups.
      ProductStore.instance.userId = uid;
      SellerProfileStore.instance.userId = uid;

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
      if (mounted) {
        try {
          final api = SupabaseProductApi();
          api.userId = uid;
          final profile = await api.getProfileByPhone(
            phone ?? '',
            userId: uid,
          );

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
            bankDetails = accounts.isNotEmpty ? accounts.first : null;
            verificationDetails =
                await api.getVerificationForUsers(candidateIds);

            // Load active bank account ID from seller_profiles
            if (SellerProfileStore.instance.userId.isNotEmpty) {
              final activeBankId = await api.getActiveBankAccountId(
                SellerProfileStore.instance.userId,
              );
              SellerProfileStore.instance.setActiveBankAccountId(
                activeBankId,
              );
            }
          }

          final bool foundAnyRow = profile != null ||
              bankDetails != null ||
              verificationDetails != null;

          if (foundAnyRow && mounted) {
            if (profile != null) {
              _populateProfileStore(profile);
            }

          final bool profileComplete =
              profile != null && _isProfileComplete(profile);
          final bool personalComplete =
              profile != null && _isPersonalComplete(profile);
          final bool bankComplete =
              bankDetails != null && _isBankComplete(bankDetails);
          final bool verificationComplete = verificationDetails != null &&
              _isVerificationComplete(verificationDetails);

          SellerProfileStore.instance.setCompletion(
            profileComplete: profileComplete,
            bankComplete: bankComplete,
            verificationComplete: verificationComplete,
            personalComplete: personalComplete,
          );

          // A login session continues straight on Home (the OTP flow sends
          // the seller to the same place); a sign-up session still walks the
          // onboarding steps so no pending page is skipped.
          if (SessionStore.instance.method == SessionStore.loginMethod) {
            _openHome();
          } else {
            _navigateBasedOnCompletion(
              profileComplete: profileComplete,
              bankComplete: bankComplete,
              verificationComplete: verificationComplete,
              personalComplete: personalComplete,
            );
          }
          return;
          }
        } catch (_) {
          // Supabase lookup failed — treat the seller as having no saved
          // rows and restart onboarding below.
        }
      }

      // No Supabase data found for this seller. A login session lands on
      // Home — the OTP flow sends the seller to the same place — while a
      // sign-up session restarts the onboarding steps at STEP 01. A session
      // with no recorded method (saved by an older build) keeps the original
      // behavior and restarts at Verify Your Details, so a pending onboarding
      // page is never skipped in favour of Home.
      if (!mounted) return;
      final String method = SessionStore.instance.method;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => method == SessionStore.loginMethod
              ? const SellerHomeScreen()
              : method == SessionStore.signupMethod
                  ? const Step01LocationScreen()
                  : const VerifyDetaileScreen(),
        ),
      );
    } else if (_firstRun) {
      // First run without a session: the artwork stays up and the arrow
      // button opens the login flow.
      setState(() => _checking = false);
    } else {
      // Later launch without a session: no artwork at all — continue on the
      // Welcome / login screen as soon as the first frame is on screen.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openWelcome());
    }
  }

  /// Determines whether the seller profile section is complete based on
  /// required Supabase fields being non-empty.
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

  /// Navigates to the first incomplete onboarding step (Verify Your Details ->
  /// Personal Details -> Registration -> Bank Details), or to Home if all
  /// sections are complete.
  void _navigateBasedOnCompletion({
    required bool profileComplete,
    required bool bankComplete,
    required bool verificationComplete,
    required bool personalComplete,
  }) {
    if (!mounted) return;

    // Onboarding order is Verify -> Personal Details -> Registration
    // (STEP 03) -> Bank -> Home, so verification is always the first section
    // to check.
    if (!verificationComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const VerifyDetaileScreen(),
        ),
      );
      return;
    }

    if (!personalComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const PersonalDetailsScreen(),
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
    if (name.isNotEmpty) {
    SellerProfileStore.instance.saveBusinessDetails(
      name: name,
      business: name,
      phone: mobile,
      location: '',
      address: '',
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
