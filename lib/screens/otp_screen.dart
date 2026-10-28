import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_deco.dart';
import '../widgets/hover_press.dart';
import '../widgets/keyboard_aware_canvas.dart';
import '../widgets/otp_field_row.dart';
import 'location_screen.dart';

/// Enter OTP screen — static replica of Zeplin "Android Compact - 50"
/// (project 6a8d49709e27bd8b35213d35, screen 6aad063196da349aa4dae3c4).
///
/// Built against a 412x917 artboard. Every offset below is taken straight from
/// the design, so on a matching device the layout renders 1:1; on shorter or
/// wider viewports it scales down uniformly instead of overflowing.
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  static const String illustrationAsset = 'assets/otp/illustration.png';
  static const double designWidth = 412;

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
              designWidth: designWidth,
              keyboardDesignHeight: 917,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, topGap, 24, 132),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        illustrationAsset,
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
                    const Text('+91 1234567890', style: AppTextStyles.phone),
                    const SizedBox(height: 42),
                    const OtpFieldRow(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Resent OTP in 00:12',
                        style: AppTextStyles.resend,
                      ),
                    ),
                    const SizedBox(height: 112),
                    const _VerifyButton(),
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
  const _VerifyButton();

  void _openLocationPage(BuildContext context) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step01LocationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: GestureDetector(
        onTap: () => _openLocationPage(context),
        behavior: HitTestBehavior.opaque,
        child: HoverPress.button(
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
      ),
    );
  }
}
