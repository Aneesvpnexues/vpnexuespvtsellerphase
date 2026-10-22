import 'dart:async';

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
///
/// Blinks like a native text cursor: visible for 500ms, hidden for 500ms.
/// Driven by a [Timer] rather than an [AnimationController] so it never
/// blocks `pumpAndSettle` in tests.
class OtpCaret extends StatefulWidget {
  const OtpCaret({super.key});

  /// Same half-period Flutter's own text cursor uses.
  static const Duration blinkInterval = Duration(milliseconds: 500);

  @override
  State<OtpCaret> createState() => _OtpCaretState();
}

class _OtpCaretState extends State<OtpCaret> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(OtpCaret.blinkInterval, (_) {
      setState(() => _visible = !_visible);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _visible ? 1 : 0,
      child: Container(
        width: 2,
        height: 28.5,
        color: AppColors.otpActiveBorder,
      ),
    );
  }
}
