import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'label_text.dart';

/// The white order hero shared by the pickup flow pages.
///
/// It holds the order id, the pickup-state pill, the title and the integrated
/// five-step progress strip. [currentStep] is the index of the step the order
/// currently sits on (0 = Active ... 4 = Completed); everything before it is
/// drawn as completed, everything after it as idle. Passing a value past the
/// last step draws the whole strip as completed.
class OrderProgressHero extends StatelessWidget {
  const OrderProgressHero({
    super.key,
    required this.pillLabel,
    required this.pillLeft,
    required this.pillWidth,
    required this.currentStep,
    this.currentIcon,
  });

  final String pillLabel;
  final double pillLeft;
  final double pillWidth;
  final int currentStep;

  /// The glyph shown inside the dark-green current step (a package, a download
  /// arrow or a flag, depending on the page).
  final Widget? currentIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 173,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(0, 5),
            blurRadius: 5,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 11),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0x03000000),
            offset: Offset(0, 20),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 10,
            child: LabelText(
              'ORDER #NX4582',
              _inter(
                const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                  color: AppColors.orderIdGreen,
                ),
              ),
              width: 113,
              height: 15,
            ),
          ),
          Positioned(
            left: pillLeft,
            top: 11,
            child: Container(
              width: pillWidth,
              height: 18.5,
              decoration: const BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: BorderRadius.all(Radius.circular(9.25)),
              ),
            ),
          ),
          Positioned(
            left: pillLeft + 11.5,
            top: 17.75,
            child: const _Dot(size: 5, color: AppColors.orderDivider),
          ),
          Positioned(
            left: pillLeft + 19.5,
            top: 10.25,
            child: LabelText(
              pillLabel,
              _inter(AppTextStyles.orderPillLabel),
              width: pillWidth - 24.5,
              height: 20,
            ),
          ),
          Positioned(
            left: 15,
            top: 30.5,
            child: LabelText(
              'Ready for Pickup',
              _inter(
                const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.35,
                  color: AppColors.orderDark,
                ),
              ),
              width: 260,
              height: 34,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _HeroSteps(
              currentStep: currentStep,
              currentIcon: currentIcon,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _inter(TextStyle style) => style.copyWith(fontFamily: 'Inter');

class _HeroSteps extends StatelessWidget {
  const _HeroSteps({required this.currentStep, this.currentIcon});

  final int currentStep;
  final Widget? currentIcon;

  static const List<_StepSpec> specs = [
    _StepSpec(
      label: 'Active',
      center: 34,
      labelLeft: 19,
      labelWidth: 30,
      icon: 'assets/order/ic_step_tick_white.png',
      iconSize: 18,
    ),
    _StepSpec(
      label: 'Accepted',
      center: 104,
      labelLeft: 81,
      labelWidth: 44,
      icon: 'assets/order/ic_step_tick_white.png',
      iconSize: 18,
    ),
    _StepSpec(
      label: 'Ready',
      center: 174,
      labelLeft: 163,
      labelWidth: 23,
      icon: 'assets/order/ic_step_package.png',
      iconSize: 16,
    ),
    _StepSpec(
      label: 'Pickup',
      center: 244,
      labelLeft: 231,
      labelWidth: 24,
      icon: 'assets/order/ic_step_download.png',
      iconSize: 19,
    ),
    _StepSpec(
      label: 'Completed',
      center: 313,
      labelLeft: 293,
      labelWidth: 40,
      icon: 'assets/order/ic_step_flag.png',
      iconSize: 18,
    ),
  ];

  static const double _circleSize = 36;
  static const double _circleTop = 92;
  static const double _lineTop = 110;

  @override
  Widget build(BuildContext context) {
    final bool allComplete = currentStep >= specs.length;
    final int last = specs.length - 1;
    final int lineEnd = allComplete ? last : currentStep.clamp(0, last);
    return SizedBox(
      width: 362,
      height: 173,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (lineEnd > 0)
            Positioned(
              left: specs[0].center,
              top: _lineTop,
              child: Container(
                width: specs[lineEnd].center - specs[0].center,
                height: 1,
                color: AppColors.orderDark,
              ),
            ),
          if (!allComplete && currentStep < specs.length - 1)
            Positioned(
              left: specs[currentStep].center,
              top: _lineTop,
              child: Container(
                width: specs[4].center - specs[currentStep].center,
                height: 1,
                color: const Color(0xFFDCDADA),
              ),
            ),
          for (int i = 0; i < specs.length; i++)
            Positioned(
              left: specs[i].center - _circleSize / 2,
              top: _circleTop,
              child: _StepCircle(
                spec: specs[i],
                first: i == 0,
                done: allComplete || i < currentStep,
                current: !allComplete && i == currentStep,
                currentIcon: currentIcon,
              ),
            ),
          for (int i = 0; i < specs.length; i++)
            Positioned(
              left: specs[i].labelLeft,
              top: 131,
              child: LabelText(
                specs[i].label,
                _inter(
                  allComplete || i <= currentStep
                      ? AppTextStyles.orderStepLabel
                      : AppTextStyles.orderStepLabelIdle,
                ),
                width: specs[i].labelWidth,
                height: 15,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepSpec {
  const _StepSpec({
    required this.label,
    required this.center,
    required this.labelLeft,
    required this.labelWidth,
    required this.icon,
    required this.iconSize,
  });

  final String label;
  final double center;
  final double labelLeft;
  final double labelWidth;
  final String icon;
  final double iconSize;
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.spec,
    required this.first,
    required this.done,
    required this.current,
    required this.currentIcon,
  });

  final _StepSpec spec;
  final bool first;
  final bool done;
  final bool current;
  final Widget? currentIcon;

  @override
  Widget build(BuildContext context) {
    final Color fill = current
        ? AppColors.orderDark
        : done
        ? AppColors.orderStepGreen
        : Colors.white;
    final Color ring = current
        ? AppColors.limeLight
        : done
        ? (first ? AppColors.orderStepActiveRing : AppColors.limeLight)
        : AppColors.orderStepRing;
    final Widget glyph = current
        ? (currentIcon ??
              const Image(
                image: AssetImage('assets/order/ic_step_tick_white.png'),
                width: 18,
                height: 18,
              ))
        : Image(
            image: AssetImage(
              done ? 'assets/order/ic_step_tick_white.png' : spec.icon,
            ),
            width: done ? 18 : spec.iconSize,
            height: done ? 18 : spec.iconSize,
          );
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: glyph,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
