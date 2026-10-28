import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_deco.dart';
import '../widgets/otp_field_row.dart';
import 'location_screen.dart';

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
/// navigates once all 6 digits are entered.
class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    this.dialCode = '+91',
    this.phoneNumber = '1234567890',
  });

  static const String illustrationAsset = 'assets/otp/illustration.png';
  static const double designWidth = 412;

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

  void _verify() {
    if (_otp.length != OtpFieldRow.boxCount) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Enter the 6-digit OTP'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step01LocationScreen()),
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
    final double topInset = MediaQuery.of(context).padding.top;
    // Design places the illustration at y=123 on the artboard.
    final double topGap = (123 - topInset).clamp(0, 240).toDouble();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const Positioned(left: 0, right: 0, bottom: 0, child: BottomDeco()),
          SafeArea(
            top: true,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.topCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: OtpScreen.designWidth,
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
                          Text(_phoneLabel, style: AppTextStyles.phone),
                          const SizedBox(height: 42),
                          OtpFieldRow(
                            onChanged: (value) => setState(() => _otp = value),
                          ),
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
                          const SizedBox(height: 112),
                          _VerifyButton(onTap: _verify),
                        ],
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
