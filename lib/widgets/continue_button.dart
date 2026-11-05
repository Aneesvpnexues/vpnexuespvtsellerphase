import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'hover_press.dart';

/// Primary onboarding CTA shared by the location/seller/business/verify/bank
/// steps so "Continue" keeps the same size, style and bottom placement on
/// every page.
class ContinueButton extends StatelessWidget {
  const ContinueButton({
    super.key,
    required this.onTap,
    this.buttonKey,
    this.enabled = true,
  });

  /// Design width of the pill on the 412-wide artboards.
  static const double designWidth = 364;
  static const double horizontalMargin = 24;
  static const double height = 54;
  static const double bottomMargin = 16;

  /// Space to reserve above this pinned CTA while the keyboard is open.
  static const double keyboardInset = height + bottomMargin;

  final VoidCallback onTap;
  final Key? buttonKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: horizontalMargin,
          right: horizontalMargin,
          bottom: bottomMargin,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? onTap : null,
              child: HoverPress.button(
                enabled: enabled,
                child: Container(
                  key: buttonKey,
                  width: math.min(constraints.maxWidth, designWidth),
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: enabled
                          ? const [
                              AppColors.continueGradientStart,
                              AppColors.continueGradientEnd,
                            ]
                          : const [
                              AppColors.continueDisabledGradientStart,
                              AppColors.continueDisabledGradientEnd,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: enabled
                        ? const [
                            BoxShadow(
                              color: AppColors.continueGlow,
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: const Text('Continue', style: AppTextStyles.button),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
