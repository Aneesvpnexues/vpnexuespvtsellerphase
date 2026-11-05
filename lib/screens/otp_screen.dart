import 'dart:async';
import 'dart:math' as math; // <-- Add this line
import 'package:flutter/material.dart';

import '../data/seller_profile_store.dart';
import '../data/session_store.dart';
import '../data/user_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_deco.dart';
import '../widgets/inline_error.dart';
import '../widgets/otp_field_row.dart';
import 'seller_home_screen.dart';

/// Enter OTP screen — static replica of Zeplin "Android Compact - 50"
/// (project 6a8d49709e27bd8b35213d35, screen 6aad063196da349aa4dae3c4).
///
/// Built against a 412x917 artboard. Every offset below is taken straight from
/// the design, so on a matching device the layout renders 1:1; on shorter or
/// wider viewports it scales down uniformly instead of overflowing.
///
/// [dialCode] + [phoneNumber] are the values typed on the Welcome screen (the
/// Zeplin mockup's placeholder number only shows when the screen is pumped on
/// its own). The resend label counts down for [resendCountdown] seconds and
/// turns into a tappable "Resend OTP" that restarts the timer, and Verify only
/// succeeds once all 6 digits are entered and match the fixed test code
/// [SessionStore.validOtp]; a wrong code is rejected inline. A successful
/// verify opens the session and continues to the home page.
class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    this.dialCode = '+91',
    this.phoneNumber = '1234567890',
  });

  static const String illustrationAsset = 'assets/otp/illustration.png';
  static const double designWidth = 412;
  static const double designHeight = 917; // <-- Add this line

  /// Country dial code shown under the "sent a 6-digit code" copy.
  final String dialCode;

  /// Phone number the code was sent to.
  final String phoneNumber;

  /// How long the "Resend OTP in MM:SS" countdown runs.
  static const Duration resendCountdown = Duration(seconds: 12);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  Timer? _resendTimer;
  int _secondsLeft = OtpScreen.resendCountdown.inSeconds;
  String _otp = '';

  /// Inline error shown under the OTP boxes when "Verify" is tapped before
  /// all six digits are entered; cleared as soon as the row changes.
  String _otpError = '';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
        if (_secondsLeft == 0) {
          _resendTimer?.cancel();
          _resendTimer = null;
        }
      });
    });
  }

  void _onOtpChanged(String value) {
    setState(() {
      _otp = value;
      if (_otpError.isNotEmpty && _otp.length == OtpFieldRow.boxCount) {
        _otpError = '';
      }
    });
  }

  void _resend() {
    setState(() => _secondsLeft = OtpScreen.resendCountdown.inSeconds);
    _startResendTimer();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('A new OTP has been sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Requires all six digits and the fixed test code [SessionStore.validOtp];
  /// a missing code or a wrong code is reported inline, in red, directly
  /// under the OTP boxes and never grants access. The correct code opens the
  /// session for this phone number and goes straight to the home page — no
  /// further OTP or phone entry afterwards.
  void _verify() {
    if (_otp.length != OtpFieldRow.boxCount) {
      setState(() => _otpError = 'Enter the 6-digit OTP');
      return;
    }
    if (_otp.trim() != SessionStore.validOtp) {
      setState(() => _otpError = 'Invalid OTP. Please try again.');
      return;
    }
    FocusScope.of(context).unfocus();

    final String phone = '${widget.dialCode} ${widget.phoneNumber}';
    // The session's display name comes from the registered account for this
    // number when one exists, so a returning seller sees their own name.
    final SellerAccount? account = UserStore.instance.findByPhone(phone);
    SessionStore.instance.startSession(
      phone: phone,
      userName: account?.name ?? SellerProfileStore.instance.name,
      method: 'login',
    );

    // A successful login also lands on the home page; the stack is cleared
    // so back never returns to the OTP screen.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SellerHomeScreen()),
      (route) => false,
    );
  }

  String get _phoneLabel => '${widget.dialCode} ${widget.phoneNumber}';

  /// "Resend OTP in MM:SS" while counting down, plain "Resend OTP" at 0.
  String get _resendLabel {
    if (_secondsLeft <= 0) return 'Resend OTP';
    final String minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return 'Resend OTP in $minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double scale = math.min(
      1.0,
      math.min(
        screenSize.width / OtpScreen.designWidth,
        screenSize.height / OtpScreen.designHeight,
      ),
    );
    final double topInset = MediaQuery.paddingOf(context).top;
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Design places the illustration at y=123 on the artboard.
    final double topGap = (123 - topInset).clamp(0, 240).toDouble();

    return Scaffold(
      resizeToAvoidBottomInset: true, // <-- Changed from false to true
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const Positioned(left: 0, right: 0, bottom: 0, child: BottomDeco()),
          SafeArea(
            top: true,
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: OtpScreen.designWidth * scale,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: OtpScreen.designWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          keyboardOpen ? 24 : topGap,
                          24,
                          keyboardOpen ? 24 : 132,
                        ),
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
                            Text(_phoneLabel, style: AppTextStyles.phone),
                            const SizedBox(height: 42),
                            OtpFieldRow(onChanged: _onOtpChanged),
                            if (_otpError.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              InlineErrorText(_otpError),
                            ],
                            const SizedBox(height: 16),
                            Center(
                              child: _secondsLeft > 0
                                  ? Text(
                                      _resendLabel,
                                      style: AppTextStyles.resend,
                                    )
                                  : GestureDetector(
                                      key: const Key('resendOtp'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _resend,
                                      child: Text(
                                        'Resend OTP',
                                        style: AppTextStyles.resend,
                                      ),
                                    ),
                            ),
                            // Shrinks the 112px gap to 32px while the keyboard
                            // is open so the Verify button sits right below the
                            // OTP row and stays immediately reachable.
                            SizedBox(height: keyboardOpen ? 16 : 60),
                            _VerifyButton(onTap: _verify),
                          ],
                        ),
                      ),
                    ),
                  ),
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
  const _VerifyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('Verify', style: AppTextStyles.button),
          ),
        ),
      ),
    );
  }
}
