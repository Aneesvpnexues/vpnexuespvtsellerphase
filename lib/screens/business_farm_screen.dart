import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

/// Business & Farm ΓÇö static replica of Zeplin "Android Compact - 160"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1af840e9c872e246edf7e).
///
/// Built against a 412x1103 artboard. Same zoom-scroll pattern as
/// 117/123/132/135/151/159: fit width, scroll vertically. Visual only.
class BusinessFarmScreen extends StatelessWidget {
  const BusinessFarmScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1103;
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
                  'Business & Farm',
                  AppTextStyles.orderTitle,
                  width: 200,
                ),
              ),
              Positioned(left: 24, top: 132, child: _HeroCard()),
              Positioned(left: 24, top: 307, child: _FormCard()),
              Positioned(left: 24, top: 609, child: _AddressCard()),
              Positioned(left: 24, top: 850, child: _OrdersCard()),
              Positioned(left: 24, top: 1036, child: _SaveBar()),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 364,
      height: 161,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage('assets/business/farm_hero.png'),
                fit: BoxFit.fill,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 105,
              child: LabelText(
                'Kumar Organic Farm',
                AppTextStyles.businessHeroTitle,
                width: 190,
              ),
            ),
            Positioned(
              left: 22,
              top: 132,
              child: Container(
                width: 129,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.businessPillBg,
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  border: Border.all(color: AppColors.businessPillBorder),
                ),
              ),
            ),
            const Positioned(
              left: 42,
              top: 135,
              child: LabelText(
                'Salem, Tamil Nadu',
                AppTextStyles.businessHeroPill,
                width: 100,
                height: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 288,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Color(0x14000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 22,
            top: 17,
            child: LabelText(
              'Farm / Business Name',
              AppTextStyles.businessLabel,
              width: 160,
            ),
          ),
          const Positioned(left: 22, top: 43, child: _InputField()),
          const Positioned(
            left: 36,
            top: 55,
            child: Image(
              image: AssetImage('assets/profile/ic_leaf.png'),
              width: 16,
              height: 16,
            ),
          ),
          const Positioned(
            left: 68,
            top: 51,
            child: LabelText(
              'Kumar Organic Farm',
              AppTextStyles.personalValue,
              width: 160,
            ),
          ),
          const Positioned(
            left: 22,
            top: 93,
            child: LabelText(
              'Farm Size',
              AppTextStyles.businessLabel,
              width: 80,
            ),
          ),
          const Positioned(left: 22, top: 119, child: _InputField()),
          const Positioned(
            left: 36,
            top: 131,
            child: Image(
              image: AssetImage('assets/profile/ic_leaf.png'),
              width: 16,
              height: 16,
            ),
          ),
          const Positioned(
            left: 68,
            top: 127,
            child: LabelText('5', AppTextStyles.personalValue, width: 20),
          ),
          const Positioned(
            left: 296,
            top: 127,
            child: LabelText('acres', AppTextStyles.businessUnit, width: 40),
          ),
          const Positioned(
            left: 22,
            top: 169,
            child: LabelText(
              'What you grow',
              AppTextStyles.businessLabel,
              width: 100,
            ),
          ),
          const Positioned(
            left: 22,
            top: 195,
            child: _Chip(
              width: 91,
              text: 'Tomatoes',
              selected: true,
              bold: true,
            ),
          ),
          const Positioned(
            left: 121,
            top: 195,
            child: _Chip(width: 80, text: 'Spinach', selected: true),
          ),
          const Positioned(
            left: 212,
            top: 195,
            child: _Chip(width: 84, text: 'Carrots', selected: true),
          ),
          const Positioned(
            left: 20,
            top: 235,
            child: _Chip(width: 78, text: 'Onions', selected: false),
          ),
          const Positioned(
            left: 107,
            top: 235,
            child: _Chip(width: 112, text: 'Green Chillies', selected: false),
          ),
          const Positioned(
            left: 229,
            top: 235,
            child: _Chip(width: 88, text: 'Potatoes', selected: false),
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.width,
    required this.text,
    required this.selected,
    this.bold = false,
  });

  final double width;
  final String text;
  final bool selected;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.orderDark : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(
          color: selected ? const Color(0x12000000) : const Color(0x14000000),
        ),
      ),
      child: Text(
        text,
        style: selected
            ? (bold
                  ? AppTextStyles.businessChipActiveBold
                  : AppTextStyles.businessChipActive)
            : AppTextStyles.businessChipIdle,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 227,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Color(0x14000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 22,
            top: 13,
            child: LabelText(
              'Address & Location',
              AppTextStyles.orderCardTitle,
              width: 180,
            ),
          ),
          const Positioned(left: 22, top: 51, child: _InputField()),
          const Positioned(
            left: 36,
            top: 64,
            child: Image(
              image: AssetImage('assets/business/ic_location.png'),
              width: 15,
              height: 15,
            ),
          ),
          const Positioned(
            left: 68,
            top: 59,
            child: LabelText(
              'Salem, Tamil Nadu',
              AppTextStyles.personalValue,
              width: 160,
            ),
          ),
          Positioned(
            left: 22,
            top: 105,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: const Image(
                image: AssetImage('assets/business/map.png'),
                width: 322,
                height: 102,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersCard extends StatelessWidget {
  const _OrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 167,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Color(0x14000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 22,
            top: 13,
            child: LabelText(
              'How buyers get orders',
              AppTextStyles.orderCardTitle,
              width: 200,
            ),
          ),
          const Positioned(
            left: 21,
            top: 56,
            child: _OrderTile(icon: 'assets/business/ic_download.png'),
          ),
          const Positioned(
            left: 66,
            top: 53,
            child: LabelText(
              'Buyer Pickup',
              AppTextStyles.profileMenuTitle,
              width: 120,
            ),
          ),
          const Positioned(
            left: 66,
            top: 68,
            child: LabelText(
              'Buyers collect from your location',
              AppTextStyles.profileMenuSub,
              width: 180,
            ),
          ),
          const Positioned(
            left: 22,
            top: 102,
            child: SizedBox(
              width: 322,
              height: 1,
              child: ColoredBox(color: Color(0x12000000)),
            ),
          ),
          const Positioned(
            left: 21,
            top: 114,
            child: _OrderTile(icon: 'assets/business/ic_truck.png'),
          ),
          const Positioned(
            left: 66,
            top: 111,
            child: LabelText(
              'Delivery',
              AppTextStyles.profileMenuTitle,
              width: 100,
            ),
          ),
          const Positioned(
            left: 66,
            top: 126,
            child: LabelText(
              'You delivery to the buyer',
              AppTextStyles.profileMenuSub,
              width: 160,
            ),
          ),
          const Positioned(left: 304, top: 63, child: _Toggle()),
          const Positioned(left: 304, top: 122, child: _Toggle()),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.orderTile,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Image(image: AssetImage(icon), width: 16, height: 16),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 18,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.businessToggle,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
          ),
          Positioned(
            left: 24,
            top: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
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
