import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import '../widgets/bottom_deco.dart';
import '../widgets/otp_field_row.dart';
import 'location_screen.dart';

/// "Enter OTP" screen — replica of Zeplin "Android Compact - 50".
///
/// Built against a 412x917 artboard; every offset below is taken from the
/// design PNG. The six boxes reuse [OtpFieldRow] (tap-to-focus, numeric-only
/// entry and the blinking caret) and the pale wash under the button reuses
/// [BottomDeco]. "Verify" continues into the STEP 01 onboarding screen.
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;

  static const String illustrationAsset = 'assets/otp/illustration.png';

  void _verify(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step01LocationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Artboard(
        designWidth: designWidth,
        designHeight: designHeight,
        child: Stack(
          children: [
            // Pale wash + corner leaves sit behind everything, at the bottom.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(child: BottomDeco()),
            ),
            const Positioned(left: 62, top: 126, child: _Illustration()),
            const Positioned(left: 24, top: 373, child: _Title()),
            const Positioned(left: 24, top: 425, child: _Subtitle()),
            const Positioned(left: 24, top: 455, child: _PhoneNumber()),
            const Positioned(
              left: 24,
              right: 24,
              top: 521,
              child: OtpFieldRow(),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 599,
              child: _ResendLine(),
            ),
            Positioned(
              left: 24,
              top: 731,
              child: _VerifyButton(onTap: () => _verify(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      OtpScreen.illustrationAsset,
      width: 287,
      height: 207,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text('Enter OTP', style: AppTextStyles.heading);
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'We\u2019ve sent a 6-digit code to',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _PhoneNumber extends StatelessWidget {
  const _PhoneNumber();

  @override
  Widget build(BuildContext context) {
    return const Text('+91 1234567890', style: AppTextStyles.phone);
  }
}

class _ResendLine extends StatelessWidget {
  const _ResendLine();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Resent OTP in 00:12', style: AppTextStyles.resend),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('otpVerify'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 364,
        height: 54,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.all(Radius.circular(27)),
          boxShadow: [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Text('Verify', style: AppTextStyles.button),
      ),
    );
  }
}
