import 'dart:async';

import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/seller_product_repository.dart';
import '../data/session_store.dart';
import '../data/supabase_product_api.dart';
import '../services/auth_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_deco.dart';
import '../widgets/hover_press.dart';
import '../widgets/keyboard_aware_canvas.dart';
import '../widgets/otp_field_row.dart';
import 'bank_detaile.dart';
import 'location_screen.dart';
import 'seller_home_screen.dart';
import 'verify_detaile.dart';

/// "Enter OTP" screen — replica of Zeplin "Android Compact - 50".
///
/// Built against a 412x917 artboard. Every offset below is taken straight from
/// the design, so on a matching device the layout renders 1:1; on shorter or
/// wider viewports it scales down uniformly instead of overflowing.
///
/// Nothing here advances on its own: Verify only navigates after
/// [AuthFlow.verifyOtp] confirms the code with Firebase (or Android
/// auto-retrieves it and [_enterStep01] fires from the auto-verify handler).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  /// The number the code was sent to, e.g. `+91 9876543210` — shown under
  /// "We've sent a 6-digit code to".
  final String phone;

  static const double designWidth = 412;
  static const double designHeight = 917;

  static const String illustrationAsset = 'assets/otp/illustration.png';

  /// Seconds before "Resend OTP" becomes tappable (Firebase's SMS resend
  /// window is 60s).
  static const int resendSeconds = 60;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final GlobalKey<OtpFieldRowState> _rowKey = GlobalKey<OtpFieldRowState>();

  String _code = '';
  bool _verifying = false;
  bool _entered = false;
  int _secondsLeft = OtpScreen.resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AuthFlow.instance.autoVerified = () {
      _routeAfterVerification();
    };
    _startResendCountdown();
  }

  @override
  void dispose() {
    AuthFlow.instance.autoVerified = null;
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _timer?.cancel();
    _secondsLeft = OtpScreen.resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer tick) {
      if (!mounted) {
        tick.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        tick.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    if (_verifying || _code.length != OtpFieldRow.boxCount) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    final String? error = await AuthFlow.instance.verifyOtp(_code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (error != null) {
      _showError(error);
      setState(() {
        _code = '';
        _rowKey.currentState?.clear();
      });
      return;
    }
    _routeAfterVerification();
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _verifying) return;
    await AuthFlow.instance.resendOtp(
      onCodeSent: () {
        if (!mounted) return;
        setState(_startResendCountdown);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('New code sent.')));
      },
      onError: (String message) {
        if (!mounted) return;
        _showError(message);
      },
    );
  }

  /// After successful OTP verification, fetch all existing seller data from
  /// Supabase using the authenticated mobile number, determine which
  /// onboarding sections are already complete, skip those pages, and navigate
  /// to the first incomplete step or directly to Home.
  Future<void> _routeAfterVerification() async {
    if (_entered) return;
    _entered = true;
    AuthFlow.instance.autoVerified = null;

    // Firebase has verified this phone for real — open the local session
    // cache that requireSession() and the profile screens read after login.
    // It is only ever populated from here, never on its own.
    SessionStore.instance.startSession(
      phone: AuthFlow.instance.currentUserPhone ?? widget.phone,
      userName: SellerProfileStore.instance.name,
      method: 'login',
    );

    // Clear any stale data from a previous login session.
    SellerProfileStore.instance.resetCompletionFlags();
    ProductStore.instance.clear();

    // Get the verified phone number from Firebase Auth (null-safe in tests).
    final String? firebasePhone = AuthFlow.instance.currentUserPhone;
    final String firebaseUid = AuthFlow.instance.firebaseUid ?? '';

    // Set the user_id for product queries and all user-scoped lookups.
    ProductStore.instance.userId = firebaseUid;
    SellerProfileStore.instance.userId = firebaseUid;

    // Always re-fetch this user's products from Supabase so they persist
    // across app restarts.
    try {
      await SellerProductRepository().refresh(ProductStore.instance);
    } catch (_) {
      // Home still opens with whatever products are cached locally.
    }

    SellerProfileStore.instance.mobile = firebasePhone ?? widget.phone;

    // Look up the seller's Supabase rows for whatever phone number was just
    // verified. Nothing here is specific to one number: the profile match
    // tries the exact E.164 value, then the last 10 digits (display format),
    // then the Firebase UID, and bank/KYC are always checked under both the
    // Firebase UID and the profile row's id.
    if (mounted) {
      try {
        final api = SupabaseProductApi();
        api.userId = firebaseUid;
        final profile = await api.getProfileByPhone(
          firebasePhone ?? widget.phone,
          userId: firebaseUid,
        );

        final String profileUserId =
            (profile?['user_id'] ?? '').toString().trim();

        // Products are written under the Firebase UID, so keep that as the
        // store's user_id. Profile/bank/KYC rows may live under a legacy
        // backend id, so look those up under both ids.
        final List<String> candidateIds = <String>{
          firebaseUid,
          profileUserId,
        }.where((String id) => id.trim().isNotEmpty).toList();

        if (profile != null) {
          _populateProfileStore(profile);
          // Refresh the cached session display name with the Supabase row.
          SessionStore.instance.startSession(
            phone: AuthFlow.instance.currentUserPhone ?? widget.phone,
            userName: SellerProfileStore.instance.name,
            method: 'login',
          );
        }

        // Bank and KYC are fetched even when the profile row is missing: a
        // seller who finished those sections but lost the profile row must
        // not be sent through them again.
        Map<String, dynamic>? bankDetails;
        Map<String, dynamic>? verificationDetails;
        if (candidateIds.isNotEmpty) {
          bankDetails = await api.getBankDetailsForUsers(candidateIds);
          verificationDetails =
              await api.getVerificationForUsers(candidateIds);
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

        if (!mounted) return;
        _navigateBasedOnCompletion(
          profileComplete: profileComplete,
          bankComplete: bankComplete,
          verificationComplete: verificationComplete,
        );
        return;
      } catch (_) {
        // Supabase lookup failed — fall through to onboarding.
      }
    }

    // No Supabase data found for this number — new user, onboarding STEP 01.
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step01LocationScreen()),
    );
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
  /// sections are complete. Pushes (not replacement) so the user can navigate
  /// back through the flow if needed.
  void _navigateBasedOnCompletion({
    required bool profileComplete,
    required bool bankComplete,
    required bool verificationComplete,
  }) {
    if (!mounted) return;

    if (!profileComplete) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Step01LocationScreen(),
        ),
      );
      return;
    }

    // The onboarding flow is STEP 01-03 (profile) -> Verify -> Bank -> Home,
    // so the first incomplete section after the profile is verification.
    if (!verificationComplete) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const VerifyDetaileScreen(),
        ),
      );
      return;
    }

    if (!bankComplete) {
      Navigator.of(context).push(
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

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    // Design places the illustration at y=123 on the artboard.
    final double topGap = (123 - topInset).clamp(0, 240).toDouble();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const Positioned(left: 0, right: 0, bottom: 0, child: BottomDeco()),
          SafeArea(
            top: true,
            bottom: false,
            child: KeyboardAwareCanvas(
              designWidth: OtpScreen.designWidth,
              keyboardDesignHeight: 917,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, topGap, 24, 132),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        OtpScreen.illustrationAsset,
                        width: 290,
                        height: 210,
                        fit: BoxFit.fill,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text('Enter OTP', style: AppTextStyles.title),
                    const SizedBox(height: 12),
                    const Text(
                      'We\u2019ve sent a 6-digit code to',
                      style: AppTextStyles.subtitle,
                      softWrap: false,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Text(widget.phone, style: AppTextStyles.phone),
                    const SizedBox(height: 42),
                    OtpFieldRow(
                      key: _rowKey,
                      onChanged: (String value) =>
                          setState(() => _code = value),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        key: const Key('otpResendLabel'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _secondsLeft == 0 ? _resend : null,
                        child: Text(
                          _secondsLeft > 0
                              ? 'Resent OTP in 00:'
                                  '${_secondsLeft.toString().padLeft(2, '0')}'
                              : 'Resend OTP',
                          style: AppTextStyles.resend,
                        ),
                      ),
                    ),
                    const SizedBox(height: 112),
                    _VerifyButton(
                      enabled: _code.length == OtpFieldRow.boxCount,
                      verifying: _verifying,
                      onTap: _verify,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.enabled,
    required this.verifying,
    required this.onTap,
  });

  /// Six digits typed — otherwise the tap would ask Firebase to verify a
  /// partial code.
  final bool enabled;

  final bool verifying;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: GestureDetector(
        onTap: enabled && !verifying ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: HoverPress.button(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: verifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : const Text('Verify', style: AppTextStyles.button),
            ),
          ),
        ),
      ),
    );
  }
}
