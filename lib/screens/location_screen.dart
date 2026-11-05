import 'dart:async';

import 'package:flutter/material.dart';

import '../services/seller_backend_sync.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/hover_press.dart';
import '../widgets/keyboard_aware_canvas.dart';
import 'seller_type_screen.dart';

/// "STEP 01 — Choose your location" — static replica of Zeplin
/// "Android Compact - 51" (project 6a8d49709e27bd8b35213d35,
/// screen 6aad20511aa5f163d7b36543).
///
/// Built against a 412x917 artboard. Every offset below is taken straight from
/// the design PNG, so on a matching viewport the layout renders 1:1; on other
/// sizes it scales down uniformly instead of overflowing. Both the primary
/// button and the "Select it Manually" link open the STEP 02 screen.
class Step01LocationScreen extends StatelessWidget {
  const Step01LocationScreen({super.key});

  static const String illustrationAsset = 'assets/step01/illustration.png';
  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: KeyboardAwareCanvas(
        designWidth: designWidth,
        designHeight: designHeight,
        child: Stack(
          children: const [
            Positioned(left: -94.2, top: -159.5, child: _PaleCircle()),
            Positioned(left: 0, top: 151, child: _Illustration()),
            Positioned(right: 28, top: 76.4, child: _StepLabel()),
            Positioned(left: 0, right: 8, top: 488.4, child: _Title()),
            Positioned(left: 0, right: 8, top: 541.5, child: _Description()),
            Positioned(left: 22, top: 731, child: _LocationButton()),
            Positioned(left: 0, right: 10, top: 818.5, child: _ManualLink()),
          ],
        ),
      ),
    );
  }
}

class _PaleCircle extends StatelessWidget {
  const _PaleCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paleCircle,
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Step01LocationScreen.illustrationAsset,
      width: 412,
      height: 270,
      fit: BoxFit.fill,
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return const Text('STEP 01', style: AppTextStyles.stepLabel);
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Choose your location',
      textAlign: TextAlign.center,
      style: AppTextStyles.heading,
    );
  }
}

class _Description extends StatelessWidget {
  const _Description();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Set your location to help us\n'
      'connect you with the right buyers\n'
      'and delivery options,',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyCentered,
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton();

  void _openSellerTypePage(BuildContext context) {
    FocusScope.of(context).unfocus();
    unawaited(SellerBackendSync.saveLocation());
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step02SellerTypeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSellerTypePage(context),
      behavior: HitTestBehavior.opaque,
      child: HoverPress.button(
        child: Container(
          width: 368,
          height: 54,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: const Text(
            'Use my current Location',
            style: AppTextStyles.locationButton,
          ),
        ),
      ),
    );
  }
}

class _ManualLink extends StatelessWidget {
  const _ManualLink();

  void _openSellerTypePage(BuildContext context) {
    unawaited(SellerBackendSync.saveLocation());
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step02SellerTypeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('manualLocationLink'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _openSellerTypePage(context),
      child: const Text(
        'Select it Manually',
        textAlign: TextAlign.center,
        style: AppTextStyles.manualLink,
      ),
    );
  }
}
