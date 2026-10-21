import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width artwork pinned to the bottom of the OTP screen: the pale green
/// corner circle plus the soft wash under the Verify button.
///
/// Drawn from a 824x262 (@2x) export, so the aspect ratio is what keeps its
/// height at 131px on the 412px artboard (412 * 262 / 824 = 131).
class BottomDeco extends StatelessWidget {
  const BottomDeco({super.key});

  static const String assetName = 'assets/otp/bottom_deco.png';
  static const double aspectRatio = 824 / 262;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Image.asset(assetName, fit: BoxFit.fill),
    );
  }
}

/// Small green caret shown in the first OTP box, mirroring the design.
class OtpCaret extends StatelessWidget {
  const OtpCaret({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 2, height: 28.5, color: AppColors.otpActiveBorder);
  }
}
