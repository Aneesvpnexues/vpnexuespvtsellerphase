import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

/// Personal Details â€” static replica of Zeplin "Android Compact - 159"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1af843d0244e28bb51c66).
///
/// Built against a 412x917 artboard. Same zoom-scroll pattern as 117/123/132/135:
/// fit width, scroll vertically. Visual only.
class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: designWidth,
          designHeight: designHeight,
          trimTop: trimTop,
          child: Stack(
            children: const [
              Positioned(left: 24, top: 73, child: _BackCircle()),
              Positioned(
                left: 68,
                top: 73,
                width: 200,
                height: 25,
                child: LabelText(
                  'Personal Details',
                  AppTextStyles.orderTitle,
                  width: 200,
                ),
              ),
              Positioned(left: 153, top: 148, child: _Avatar()),
              Positioned(left: 25, top: 287, child: _FormCard()),
              Positioned(left: 25, top: 850, child: _SaveBar()),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        alignment: Alignment.center,
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: const Image(
          image: AssetImage('assets/order/ic_back.png'),
          width: 15,
          height: 15,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 105,
      height: 105,
      child: Stack(
        children: [
          Container(
            width: 105,
            height: 105,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.personalAvatarStart,
                  AppColors.personalAvatarEnd,
                ],
              ),
            ),
            child: const Text('RK', style: AppTextStyles.personalInitials),
          ),
          Positioned(
            left: 71,
            top: 70,
            child: Container(
              width: 33,
              height: 33,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.personalCameraBorder),
              ),
              child: const Image(
                image: AssetImage('assets/personal/ic_camera.png'),
                width: 17,
                height: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 324,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Color(0x14000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 21,
            top: 17,
            child: LabelText(
              'Full Name',
              AppTextStyles.personalLabel,
              width: 120,
            ),
          ),
          const Positioned(left: 21, top: 43, child: _InputField()),
          const Positioned(
            left: 14,
            top: 55,
            child: Image(
              image: AssetImage('assets/personal/ic_user.png'),
              width: 16,
              height: 16,
            ),
          ),
          const Positioned(
            left: 67,
            top: 51,
            child: LabelText(
              'Ramesh Kumar',
              AppTextStyles.personalValue,
              width: 150,
            ),
          ),
          const Positioned(
            left: 21,
            top: 93,
            child: LabelText(
              'Mobile Number',
              AppTextStyles.personalLabel,
              width: 140,
            ),
          ),
          const Positioned(left: 21, top: 119, child: _InputField()),
          const Positioned(
            left: 15,
            top: 130,
            child: Image(
              image: AssetImage('assets/personal/ic_phone.png'),
              width: 14,
              height: 18,
            ),
          ),
          const Positioned(
            left: 67,
            top: 127,
            child: LabelText(
              '+91 12345 67890',
              AppTextStyles.personalValue,
              width: 150,
            ),
          ),
          const Positioned(
            left: 21,
            top: 169,
            child: LabelText('Email', AppTextStyles.personalLabel, width: 60),
          ),
          const Positioned(
            left: 55,
            top: 170,
            child: LabelText(
              '(optional)',
              AppTextStyles.personalOptional,
              width: 80,
            ),
          ),
          const Positioned(left: 21, top: 195, child: _InputField()),
          const Positioned(
            left: 14,
            top: 207,
            child: Image(
              image: AssetImage('assets/personal/ic_mail.png'),
              width: 16,
              height: 16,
            ),
          ),
          const Positioned(
            left: 67,
            top: 207,
            child: LabelText(
              'you@example.com',
              AppTextStyles.personalPlaceholder,
              width: 160,
            ),
          ),
          const Positioned(
            left: 21,
            top: 245,
            child: LabelText(
              'Seller Type',
              AppTextStyles.personalLabel,
              width: 120,
            ),
          ),
          Positioned(
            left: 21,
            top: 271,
            child: Container(
              width: 77,
              height: 31,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: const Text(
                'Farmer',
                style: AppTextStyles.personalPillActive,
              ),
            ),
          ),
          Positioned(
            left: 119,
            top: 271,
            child: Container(
              width: 89,
              height: 31,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.homeBg,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                border: Border.all(color: Color(0x12000000)),
              ),
              child: const Text(
                'Trader',
                style: AppTextStyles.personalPillIdle,
              ),
            ),
          ),
          Positioned(
            left: 228,
            top: 271,
            child: Container(
              width: 111,
              height: 31,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.homeBg,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                border: Border.all(color: Color(0x12000000)),
              ),
              child: const Text(
                'FPO / Group',
                style: AppTextStyles.personalPillIdle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 319,
      height: 41,
      decoration: const BoxDecoration(
        color: AppColors.orderPale,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 53,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.orderDark,
        borderRadius: BorderRadius.all(Radius.circular(26)),
      ),
      child: const Text('Save changes', style: AppTextStyles.personalSave),
    );
  }
}
