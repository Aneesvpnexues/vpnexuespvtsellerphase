import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/app_storage.dart';
import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/seller_product_repository.dart';
import '../data/session_store.dart';
import '../data/supabase_product_api.dart';
import '../services/auth_flow.dart';
import 'bank_detaile.dart';
import 'location_screen.dart';
import 'seller_home_screen.dart';
import 'verify_detaile.dart';
import 'welcome_seller_screen.dart';

/// First screen shown when the app opens — static replica of Zeplin
/// "Android Compact - 192" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad7318de3f9d49c8cec78ca).
///
/// The artwork is a single full-bleed export (the STEP lockup, smiley, tomato
/// photo and arrow are all part of the illustration), with the design's
/// status-bar strip trimmed off so the real platform status bar sits on the
/// empty background instead. The image is anchored to the top and scaled to
/// cover the area below the status bar, so the bottom of the photo still
/// bleeds off the screen like the design.
///
/// There is no auto-advance: the splash stays up until the user taps the
/// circular arrow button in the bottom-right corner, which continues to
/// [WelcomeSellerScreen]. The navigation uses `pushReplacement`, so the
/// splash never stays in the back stack.
///
/// On cold start, [_SplashScreenState._checkSession] also checks whether a
/// Firebase Auth session already exists. A signed-in seller resumes at the
/// first incomplete onboarding section — or straight on the home page when
/// every section is already saved — while a seller with no saved rows
/// restarts onboarding at Step 01, exactly like the OTP and welcome login
/// paths, so a pending page is never skipped in favour of Home. Without a
/// session the splash remains and tapping the arrow opens the login flow.
///
/// The splash is shown only once per install: the first launch after
/// installing. Tapping the arrow (or an automatic session resume) persists
/// [StorageKeys.splashSeenKey], and [SellerApp] skips straight to the home
/// (signed in) or welcome (signed out) screen on every later launch.
/// Uninstalling the app clears the preference, so the splash returns on the
/// next fresh install.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String splashAsset = 'assets/splash/splash.png';

  /// The design's top 44px status-bar strip was cropped from [splashAsset].
  static const double designWidth = 412;
  static const double designHeight = 873;

  /// Design-space hit target around the arrow at the bottom-right of the
  /// artwork. The visible disc is 36px, padded to a 56px tap target.
  static const Rect arrowHitArea = Rect.fromLTWH(340, 794, 56, 56);

  /// Test seam: when set, the splash treats this seller as the signed-in
  /// session instead of asking Firebase Auth, so widget tests can exercise
  /// the session-restore routing without a Firebase app.
  @visibleForTesting
  static ({String uid, String phone})? debugSignedInSeller;

  /// Whether the one-time splash has already been dismissed on this install.
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
  /// True while the cold-start Firebase session check runs; the arrow stays
  /// hidden until the check decides whether to resume automatically.
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// On cold start, check whether a Firebase Auth session already exists.
  /// If signed in, restore [AuthFlow.instance.firebaseUid], re-fetch that
  /// user's products from Supabase, check Supabase for an existing profile
  /// matching the verified phone number, determine which onboarding sections
  /// are complete, and route accordingly: the first incomplete section, or
  /// Home when everything is already saved. A signed-in seller with no saved
  /// rows restarts onboarding at Step 01 — never Home — so a pending page
  /// cannot be skipped. Otherwise stay on the splash so the user can tap to
  /// log in.
  Future<void> _checkSession() async {
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

      // Firebase still knows this seller — open the local session cache so
      // main() and requireSession() see a signed-in state after this check,
      // and record that the one-time splash has been served.
      SessionStore.instance.startSession(
        phone: phone ?? '',
        userName: SellerProfileStore.instance.name,
        method: 'login',
      );
      SplashScreen.markSplashSeen();

      // Clear any stale data from a previous login session.
      SellerProfileStore.instance.resetCompletionFlags();
      ProductStore.instance.clear();

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
            bankDetails = await api.getBankDetailsForUsers(candidateIds);
            verificationDetails =
                await api.getVerificationForUsers(candidateIds);
          }

          final bool foundAnyRow = profile != null ||
              bankDetails != null ||
              verificationDetails != null;

          if (foundAnyRow && mounted) {
            if (profile != null) {
              _populateProfileStore(profile);
              // Refresh the cached session display name with the Supabase
              // row.
              SessionStore.instance.startSession(
                phone: phone ?? SellerProfileStore.instance.mobile,
                userName: SellerProfileStore.instance.name,
                method: 'login',
              );
            }

            final bool profileComplete =
                profile != null && _isProfileComplete(profile);
            final bool bankComplete =
                bankDetails != null && _isBankComplete(bankDetails);
            final bool verificationComplete = verificationDetails != null &&
                _isVerificationComplete(verificationDetails);

            SellerProfileStore.instance.setCompletion(
              profileComplete: profileComplete,
              bankComplete: bankComplete,
              verificationComplete: verificationComplete,
            );

            _navigateBasedOnCompletion(
              profileComplete: profileComplete,
              bankComplete: bankComplete,
              verificationComplete: verificationComplete,
            );
            return;
          }
        } catch (_) {
          // Supabase lookup failed — treat the seller as having no saved
          // rows and restart onboarding below.
        }
      }

      // No Supabase data found for this seller — resume at Step 01 exactly
      // like the OTP and welcome login paths, so a pending onboarding page
      // is never skipped in favour of Home.
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const Step01LocationScreen()),
      );
    } else {
      setState(() => _checking = false);
    }
  }

  /// Determines whether the seller profile section is complete based on
  /// required Supabase fields being non-empty.
  bool _isProfileComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['display_name'] ?? '',
      profile['business_name'] ?? '',
      profile['phone_number'] ?? '',
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

  /// Navigates to the first incomplete onboarding step, or to Home if all
  /// sections are complete.
  void _navigateBasedOnCompletion({
    required bool profileComplete,
    required bool bankComplete,
    required bool verificationComplete,
  }) {
    if (!mounted) return;

    if (!profileComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const Step01LocationScreen(),
        ),
      );
      return;
    }

    // Flow order is STEP 01-03 (profile) -> Verify -> Bank -> Home, so the
    // first incomplete section after the profile is verification.
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
      SellerProfileStore.instance.save(
        name: name,
        mobile: mobile,
        email: '',
        sellerType: sellerType,
      );
    } else {
      SellerProfileStore.instance.mobile = mobile;
    }
  }

  /// The arrow continues to the last reached destination: a seller with an
  /// active session (signed up or logged in on a previous run) resumes at the
  /// home page, everyone else lands on the Welcome / login screen.
  ///
  /// This is the only place the splash is dismissed, so it also records that
  /// the one-time splash has been shown and later launches skip it.
  void _continue() {
    SplashScreen.markSplashSeen();
    final bool authenticated = SessionStore.instance.isAuthenticated;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => authenticated
            ? const SellerHomeScreen()
            : const WelcomeSellerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF3F8EF),
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
            Positioned(
              right: 24,
              bottom: 24,
              child: _checking
                  ? const SizedBox.shrink()
                  : Material(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      shape: const CircleBorder(),
                      elevation: 0,
                      child: InkWell(
                        key: const Key('splashTap'),
                        customBorder: const CircleBorder(),
                        onTap: _continue,
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: const Icon(
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
