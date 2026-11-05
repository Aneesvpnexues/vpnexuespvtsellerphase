import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/seller_product_repository.dart';
import '../data/supabase_product_api.dart';
import '../services/auth_flow.dart';
import '../services/seller_backend_sync.dart';
import '../theme/app_colors.dart';
import '../screens/bank_detaile.dart';
import '../screens/business_details_screen.dart';
import '../screens/seller_home_screen.dart';
import '../screens/verify_detaile.dart';
import '../screens/welcome_seller_screen.dart';

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
/// On cold start, [_SplashScreenState] checks whether a Firebase Auth session
/// already exists. A signed-in seller resumes at the first incomplete
/// onboarding section — or straight on the home page when every section is
/// already saved — while a seller with no saved rows restarts onboarding at
/// Step 01, exactly like the OTP and welcome login paths, so a pending page
/// is never skipped in favour of Home. Without a session the splash remains
/// and tapping the arrow opens the login flow.
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

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
  /// rows restarts onboarding at Verify Your Details — never Home — so a
  /// pending page cannot be skipped. Otherwise stay on the splash so the
  /// user can tap to log in.
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
          final profile = await api.getProfileByPhone(phone ?? '', userId: uid);

          final String profileUserId = (profile?['user_id'] ?? '')
              .toString()
              .trim();

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
            verificationDetails = await api.getVerificationForUsers(
              candidateIds,
            );
          }

          if (profile != null) {
            _populateProfileStore(profile);
          }

          final bool profileComplete =
              profile != null && _isProfileComplete(profile);
          final bool bankComplete =
              bankDetails != null && _isBankComplete(bankDetails);
          final bool verificationComplete =
              verificationDetails != null &&
              _isVerificationComplete(verificationDetails);

          SellerProfileStore.instance.setCompletion(
            profileComplete: profileComplete,
            bankComplete: bankComplete,
            verificationComplete: verificationComplete,
          );

          final bool supabaseHasProgress =
              profileComplete || bankComplete || verificationComplete;
          if (supabaseHasProgress) {
            // Supabase already knows this seller; sync the backend in the
            // background so a cold Render instance does not delay startup.
            unawaited(SellerBackendSync.mergeCompletion());
          } else {
            await SellerBackendSync.mergeCompletion();
          }

          if (!mounted) return;
          final SellerProfileStore merged = SellerProfileStore.instance;
          final bool foundAnyRow =
              merged.profileComplete ||
              merged.bankComplete ||
              merged.verificationComplete;

          if (foundAnyRow) {
            _navigateBasedOnCompletion(
              profileComplete: merged.profileComplete,
              bankComplete: merged.bankComplete,
              verificationComplete: merged.verificationComplete,
            );
            return;
          }
        } catch (_) {
          // Supabase lookup failed — try the backend before falling back.
          await SellerBackendSync.mergeCompletion();
          if (!mounted) return;
          final SellerProfileStore merged = SellerProfileStore.instance;
          if (merged.profileComplete ||
              merged.bankComplete ||
              merged.verificationComplete) {
            _navigateBasedOnCompletion(
              profileComplete: merged.profileComplete,
              bankComplete: merged.bankComplete,
              verificationComplete: merged.verificationComplete,
            );
            return;
          }
        }
      }

      // No Supabase data found for this seller — resume at Verify Your
      // Details exactly like the OTP and welcome login paths, so a pending
      // onboarding page is never skipped in favour of Home.
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const VerifyDetaileScreen()),
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
    return fields.every((value) => value.toString().trim().isNotEmpty);
  }

  /// Determines whether bank details are complete based on required fields.
  bool _isBankComplete(Map<String, dynamic> bank) {
    final fields = <String>[
      bank['account_houlder_name'] ?? '',
      bank['bank_name'] ?? '',
      bank['account_number'] ?? '',
      bank['IFSC_code'] ?? '',
    ];
    return fields.every((value) => value.toString().trim().isNotEmpty);
  }

  /// Determines whether verification/KYC is complete based on at least one
  /// document URL being present.
  bool _isVerificationComplete(Map<String, dynamic> verification) {
    final fields = <String>[
      verification['aadhaar_card'] ?? '',
      verification['pan_card'] ?? '',
      verification['business_registration'] ?? '',
    ];
    return fields.any((value) => value.toString().trim().isNotEmpty);
  }

  /// Navigates to the first incomplete onboarding step (Verify Your Details ->
  /// Registration -> Bank Details), or to Home if all sections are complete.
  void _navigateBasedOnCompletion({
    required bool profileComplete,
    required bool bankComplete,
    required bool verificationComplete,
  }) {
    if (!mounted) return;

    // Onboarding order is Verify -> Registration (STEP 03) -> Bank -> Home,
    // so verification is always the first section to check.
    if (!verificationComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const VerifyDetaileScreen()),
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
        MaterialPageRoute<void>(builder: (_) => const BankDetaileScreen()),
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
    final String sellerTypeStr = (profile['seller_type'] ?? 'farmer')
        .toString()
        .trim()
        .toLowerCase();
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

  /// Used when the user taps the splash arrow while not signed in.
  Future<void> _continueToLogin() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WelcomeSellerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double scale = math.max(
              constraints.maxWidth / SplashScreen.designWidth,
              constraints.maxHeight / SplashScreen.designHeight,
            );
            final double imageLeft =
                (constraints.maxWidth - SplashScreen.designWidth * scale) / 2;
            return Stack(
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
                if (!_checking)
                  Positioned(
                    left: imageLeft + SplashScreen.arrowHitArea.left * scale,
                    top: SplashScreen.arrowHitArea.top * scale,
                    width: SplashScreen.arrowHitArea.width * scale,
                    height: SplashScreen.arrowHitArea.height * scale,
                    child: GestureDetector(
                      key: const Key('splashTap'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _continueToLogin(),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
