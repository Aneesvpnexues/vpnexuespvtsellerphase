import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/seller_product_repository.dart';
import '../data/supabase_product_api.dart';
import '../services/auth_flow.dart';
import '../services/backend_service.dart';
import '../theme/app_colors.dart';
import '../screens/bank_detaile.dart';
import '../screens/business_details_screen.dart';
import '../screens/location_screen.dart';
import '../screens/seller_home_screen.dart';
import '../screens/seller_type_screen.dart';
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
/// already exists. If the user is signed in, the app goes straight to the home
/// page; otherwise the splash remains and tapping the arrow opens the login
/// flow.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String splashAsset = 'assets/splash/splash.png';

  /// The design's top 44px status-bar strip was cropped from [splashAsset].
  static const double designWidth = 412;
  static const double designHeight = 873;

  /// Design-space hit target around the arrow at the bottom-right of the
  /// artwork. The visible disc is 36px, padded to a 56px tap target.
  static const Rect arrowHitArea = Rect.fromLTWH(340, 794, 56, 56);

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
  /// are complete, and route accordingly. Otherwise stay on the splash so the
  /// user can tap to log in.
  Future<void> _checkSession() async {
    if (!mounted) return;
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      currentUser = null;
    }
    if (!mounted) return;
    if (currentUser != null) {
      AuthFlow.instance.firebaseUid = currentUser.uid;
      AuthFlow.instance.verified = true;

      // Clear any stale data from a previous login session.
      SellerProfileStore.instance.resetCompletionFlags();
      ProductStore.instance.clear();

      // Set the user_id for product queries and all user-scoped lookups.
      ProductStore.instance.userId = currentUser.uid;
      SellerProfileStore.instance.userId = currentUser.uid;

      // Always re-fetch this user's products from Supabase so they persist
      // across app restarts.
      try {
        await SellerProductRepository().refresh(ProductStore.instance);
      } catch (_) {
        // Home still opens with whatever products are cached locally.
      }

      // Get the verified phone number from Firebase Auth for profile lookup.
      final String? firebasePhone = currentUser.phoneNumber;

      // Look up this seller's Supabase rows by the verified phone number.
      // Number-agnostic: exact E.164 -> last 10 digits -> Firebase UID, and
      // bank/KYC are always checked under both candidate ids.
      if (mounted) {
        try {
          final api = SupabaseProductApi();
          api.userId = currentUser.uid;
          final profile = await api.getProfileByPhone(
            firebasePhone ?? '',
            userId: currentUser.uid,
          );

          final String profileUserId =
              (profile?['user_id'] ?? '').toString().trim();

          // Products live under the Firebase UID; profile/bank/KYC rows may
          // also carry a legacy backend id, so check both.
          final List<String> candidateIds = <String>{
            currentUser.uid,
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
          // Supabase lookup failed — fall through to backend status check.
        }
      }

      // No Supabase profile found — check backend onboarding status for
      // returning sellers with partial data, or go straight to Home.
      try {
        final idToken = await AuthFlow.instance.getIdToken();
        if (idToken != null && mounted) {
          await BackendService.openSession(idToken);
          if (!mounted) return;
          final status = await BackendService.onboardingStatus(idToken);
          if (!mounted) return;
          final step = (status['onboardingStep'] as String? ?? '')
              .toString()
              .trim()
              .toUpperCase();
          if (step.isNotEmpty &&
              step != 'COMPLETE' &&
              step != 'DONE' &&
              step != 'FINISHED') {
            _navigateToStep(step);
            return;
          }
        }
      } catch (_) {
        // Backend unavailable — go straight to Home.
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const SellerHomeScreen()),
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

  /// Navigate to the onboarding step indicated by the backend, or Home if
  /// onboarding is complete.
  void _navigateToStep(String step) {
    if (!mounted) return;
    switch (step) {
      case 'LOCATION':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const Step01LocationScreen()),
        );
        break;
      case 'SELLER_TYPE':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const Step02SellerTypeScreen(),
          ),
        );
        break;
      case 'BUSINESS':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const Step03BusinessDetailsScreen(),
          ),
        );
        break;
      case 'BANK':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const BankDetaileScreen()),
        );
        break;
      default:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const SellerHomeScreen()),
        );
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
