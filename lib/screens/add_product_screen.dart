import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

/// Add Products (step 1 of 5 — Product Photos) — static replica of Zeplin
/// "Android Compact - 124" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae18783597fd3b9a332f).
///
/// Built against a 412x1397 artboard. Every offset below is taken from the
/// Zeplin latest-version layers, so on a matching viewport the layout renders
/// 1:1; on other sizes it scales down uniformly instead of overflowing.
/// Visual only — no network, no state.
class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1397;
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
          child: const Stack(
            children: [
              Positioned(left: 24, top: 111, child: _StepBanner()),
              Positioned(left: 24, top: 182, child: _PhotosCard()),
              Positioned(left: 24, top: 440, child: _BasicInfoCard()),
              Positioned(left: 24, top: 671, child: _PricingCard()),
              Positioned(left: 24, top: 915, child: _DescriptionCard()),
              Positioned(left: 24, top: 1155, child: _StatusCard()),
              Positioned(left: 0, top: 1317, child: _AddProductNav()),
              Positioned(left: 24, top: 73, child: _BackCircle()),
              Positioned(
                left: 66,
                top: 73,
                child: LabelText(
                  'Add Products',
                  AppTextStyles.productsTitle,
                  width: 134,
                ),
              ),
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

class _StepBanner extends StatelessWidget {
  const _StepBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1AB0B0B0),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x17B0B0B0),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x0DB0B0B0),
            offset: Offset(0, 9),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Color(0x03B0B0B0),
            offset: Offset(0, 16),
            blurRadius: 7,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 17,
            child: Container(
              width: 334,
              height: 4,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFC5FF24),
                    Color(0xFFEDFFB8),
                    Color(0xFFF3F3F3),
                  ],
                  stops: [0.0, 0.3173, 0.4279],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 14,
            top: 30,
            child: LabelText('Step1', AppTextStyles.addStep, width: 34),
          ),
          const Positioned(
            left: 51,
            top: 25,
            child: LabelText('of 5', AppTextStyles.addMeta12, width: 23),
          ),
          Positioned(
            left: 79,
            top: 36,
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: Color(0x9E000000),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 86,
            top: 25,
            child: LabelText(
              'Product Photos',
              AppTextStyles.addMeta12,
              width: 90,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 232,
      shadow: _shadowPhotos,
      children: [
        const Positioned(
          left: 14,
          top: 16,
          child: _IconTile(
            icon: 'assets/add_product/ic_add_photo.png',
            iconSize: 22,
          ),
        ),
        const Positioned(
          left: 69,
          top: 18,
          child: LabelText(
            'Product Photos',
            AppTextStyles.addSectionTitle,
            width: 152,
            height: 16,
          ),
        ),
        const Positioned(
          left: 69,
          top: 33,
          child: LabelText(
            'Add clear photos of your product',
            AppTextStyles.addMeta12,
            width: 200,
          ),
        ),
        Positioned(
          left: 315,
          top: 17,
          child: Container(
            width: 33,
            height: 29,
            decoration: const BoxDecoration(
              color: AppColors.orderDark,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            child: const Center(
              child: LabelText('1/5', AppTextStyles.addCount, width: 19),
            ),
          ),
        ),
        // Left peek of the previous photo.
        Positioned(
          left: 0,
          top: 76.96,
          child: Container(
            width: 73,
            height: 132.977,
            decoration: const BoxDecoration(
              color: Color(0xFF7BAE5A),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
        // Empty slot in the middle.
        Positioned(
          left: 86,
          top: 71,
          child: Container(
            width: 191,
            height: 125,
            decoration: BoxDecoration(
              color: const Color(0xFFF3FFD2),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(color: const Color(0x12000000)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A707070),
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
                BoxShadow(
                  color: Color(0x17707070),
                  offset: Offset(0, 10),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: Color(0x0D707070),
                  offset: Offset(0, 23),
                  blurRadius: 14,
                ),
                BoxShadow(
                  color: Color(0x03707070),
                  offset: Offset(0, 40),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
        // Right peek of the next photo.
        Positioned(
          left: 290,
          top: 77,
          child: Container(
            width: 74,
            height: 133.112,
            decoration: const BoxDecoration(
              color: Color(0xFFF3FFD2),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
        ),
        const Positioned(
          left: 172,
          top: 116,
          child: Image(
            image: AssetImage('assets/add_product/ic_photo_add.png'),
            width: 19,
            height: 19,
          ),
        ),
        const Positioned(
          left: 156,
          top: 133,
          child: LabelText('Add photo', AppTextStyles.addPhotoLabel, width: 52),
        ),
        // Remove handle of the current photo.
        Positioned(
          left: 39,
          top: 86,
          child: Container(
            width: 14,
            height: 14,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 6, color: Colors.black),
          ),
        ),
        // Carousel arrows.
        Positioned(
          left: 6,
          top: 121,
          child: Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: AppColors.orderDark,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Positioned(
          left: 15,
          top: 128,
          child: Image(
            image: AssetImage('assets/add_product/ic_arrow_left.png'),
            width: 5,
            height: 11,
          ),
        ),
        Positioned(
          left: 332,
          top: 121,
          child: Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: AppColors.orderDark,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Positioned(
          left: 343,
          top: 128,
          child: Image(
            image: AssetImage('assets/add_product/ic_arrow_right.png'),
            width: 5,
            height: 11,
          ),
        ),
        const Positioned(left: 159, top: 210, child: _Dot(color: _dotIdle)),
        const Positioned(left: 169, top: 210, child: _Dot(color: _dotIdle)),
        const Positioned(left: 179, top: 210, child: _Dot(color: _dotActive)),
        const Positioned(left: 189, top: 210, child: _Dot(color: _dotIdle)),
        const Positioned(left: 199, top: 210, child: _Dot(color: _dotIdle)),
      ],
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 217,
      shadow: _shadowCards,
      children: [
        const Positioned(
          left: 13,
          top: 12,
          child: _IconTile(
            icon: 'assets/add_product/ic_basic.png',
            iconSize: 24,
          ),
        ),
        const Positioned(
          left: 68,
          top: 11,
          child: LabelText(
            'Basic Information',
            AppTextStyles.addCardTitle,
            width: 200,
          ),
        ),
        const Positioned(
          left: 68,
          top: 29,
          child: LabelText(
            'Tell us about your product',
            AppTextStyles.profileMenuSub,
            width: 150,
          ),
        ),
        const Positioned(
          left: 14,
          top: 61,
          child: LabelText(
            'Product Name',
            AppTextStyles.profileMenuTitle,
            width: 84,
          ),
        ),
        Positioned(
          left: 13,
          top: 86,
          child: Container(
            width: 337,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.addFieldBg,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: const Color(0x12000000)),
            ),
            child: Stack(
              children: [
                const Positioned(
                  left: 13,
                  top: 14,
                  child: Image(
                    image: AssetImage('assets/add_product/ic_tag.png'),
                    width: 15,
                    height: 15,
                  ),
                ),
                const Positioned(
                  left: 34,
                  top: 8,
                  child: LabelText(
                    'e.g Fresh Tomates',
                    AppTextStyles.addPlaceholder,
                    width: 108,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 14,
          top: 140,
          child: LabelText(
            'Category',
            AppTextStyles.profileMenuTitle,
            width: 55,
          ),
        ),
        Positioned(
          left: 13,
          top: 165,
          child: _CategoryChip(
            width: 102,
            left: 17.5,
            text: 'Vegetables',
            textWidth: 67,
          ),
        ),
        Positioned(
          left: 123,
          top: 165,
          child: _CategoryChip(
            width: 72,
            left: 19,
            text: 'Fruits',
            textWidth: 34,
          ),
        ),
        Positioned(
          left: 203,
          top: 165,
          child: _CategoryChip(
            width: 121,
            left: 14.5,
            text: 'Grains & pulses',
            textWidth: 100,
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 230,
      shadow: _shadowCards,
      children: [
        const Positioned(
          left: 13,
          top: 12,
          child: _IconTile(
            icon: 'assets/add_product/ic_rupee_lg.png',
            iconSize: 24,
          ),
        ),
        const Positioned(
          left: 68,
          top: 11,
          child: LabelText(
            'Pricing & Quantity',
            AppTextStyles.addCardTitle,
            width: 200,
          ),
        ),
        const Positioned(
          left: 68,
          top: 29,
          child: LabelText(
            'et your price and available quantity',
            AppTextStyles.profileMenuSub,
            width: 200,
          ),
        ),
        const Positioned(
          left: 14,
          top: 61,
          child: LabelText(
            'Price per unit',
            AppTextStyles.profileMenuTitle,
            width: 130,
          ),
        ),
        Positioned(
          left: 13,
          top: 86,
          child: Container(
            width: 244,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.addFieldBg,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: const Color(0x12000000)),
            ),
            child: const Stack(
              children: [
                Positioned(
                  left: 13,
                  top: 15,
                  child: Image(
                    image: AssetImage('assets/add_product/ic_rupee_sm.png'),
                    width: 14,
                    height: 14,
                  ),
                ),
                Positioned(
                  left: 33,
                  top: 8,
                  child: LabelText(
                    'e.g. 48',
                    AppTextStyles.addPlaceholder,
                    width: 50,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 267,
          top: 61,
          child: LabelText('Unit', AppTextStyles.profileMenuTitle, width: 35),
        ),
        Positioned(
          left: 266,
          top: 86,
          child: Container(
            width: 84,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orderDark,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: const Color(0x12000000)),
            ),
            child: const Stack(
              children: [
                Positioned(
                  left: 25,
                  top: 9,
                  child: LabelText(
                    'Unit',
                    AppTextStyles.addUnitValue,
                    width: 35,
                  ),
                ),
                Positioned(
                  left: 54,
                  top: 16,
                  child: Image(
                    image: AssetImage('assets/add_product/ic_unit_chevron.png'),
                    width: 11,
                    height: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 14,
          top: 140,
          child: LabelText(
            'Available Quantity',
            AppTextStyles.profileMenuTitle,
            width: 140,
          ),
        ),
        Positioned(
          left: 13,
          top: 165,
          child: Container(
            width: 337,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orderDark,
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              border: Border.all(color: const Color(0x12000000)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 7,
                  top: 5,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.limeCard,
                      shape: BoxShape.circle,
                    ),
                    child: const Stack(
                      children: [
                        Positioned(
                          left: 8,
                          top: 9,
                          child: Image(
                            image: AssetImage(
                              'assets/add_product/ic_minus.png',
                            ),
                            width: 15,
                            height: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 138,
                  top: 9,
                  child: LabelText(
                    'e.g. 50',
                    AppTextStyles.addQtyHint,
                    width: 70,
                  ),
                ),
                const Positioned(
                  left: 194,
                  top: 10,
                  child: LabelText('kg', AppTextStyles.addUnitValue, width: 15),
                ),
                Positioned(
                  left: 298,
                  top: 5,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.limeCard,
                      shape: BoxShape.circle,
                    ),
                    child: const Image(
                      image: AssetImage('assets/add_product/ic_plus.png'),
                      width: 17,
                      height: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 221,
      shadow: _shadowCards,
      children: [
        const Positioned(
          left: 13,
          top: 12,
          child: _IconTile(
            icon: 'assets/add_product/ic_notes.png',
            iconSize: 24,
          ),
        ),
        const Positioned(
          left: 68,
          top: 11,
          child: LabelText(
            'Product Descrption',
            AppTextStyles.addCardTitle,
            width: 200,
          ),
        ),
        const Positioned(
          left: 68,
          top: 29,
          child: LabelText(
            'Help buyers know more about your product.',
            AppTextStyles.profileMenuSub,
            width: 212,
          ),
        ),
        Positioned(
          left: 13,
          top: 73,
          child: Container(
            width: 337,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.addFieldBg,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: const Color(0x12000000)),
            ),
            child: const Stack(
              children: [
                Positioned(
                  left: 13,
                  top: 11,
                  child: LabelText(
                    'Tell buyers about your product',
                    AppTextStyles.addPlaceholder,
                    width: 180,
                  ),
                ),
                Positioned(
                  left: 300,
                  top: 103,
                  child: LabelText(
                    '0/500',
                    AppTextStyles.addCounter,
                    width: 37,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 123,
      shadow: _shadowCards,
      children: [
        const Positioned(
          left: 13,
          top: 12,
          child: _IconTile(icon: 'assets/add_product/ic_eye.png', iconSize: 24),
        ),
        const Positioned(
          left: 68,
          top: 11,
          child: LabelText(
            'Product Descrption',
            AppTextStyles.addCardTitle,
            width: 200,
          ),
        ),
        const Positioned(
          left: 68,
          top: 29,
          child: LabelText(
            'Help buyers know more about your product.',
            AppTextStyles.profileMenuSub,
            width: 212,
          ),
        ),
        Positioned(
          left: 13,
          top: 68,
          child: _StatusChip(
            width: 94,
            filled: true,
            dotLeft: 21,
            dotColor: AppColors.primary,
            textLeft: 32,
            text: 'Active',
            textWidth: 38,
            style: AppTextStyles.addStatusActive,
          ),
        ),
        Positioned(
          left: 121,
          top: 68,
          child: _StatusChip(
            width: 132,
            filled: false,
            dotLeft: 23,
            dotColor: AppColors.addOrange,
            textLeft: 34,
            text: 'Out of stock',
            textWidth: 90,
            style: AppTextStyles.addStatusIdle,
          ),
        ),
        Positioned(
          left: 266,
          top: 68,
          child: _StatusChip(
            width: 84,
            filled: false,
            dotLeft: 21,
            dotColor: AppColors.orderDark,
            textLeft: 32,
            text: 'Draft',
            textWidth: 40,
            style: AppTextStyles.addStatusIdle,
          ),
        ),
      ],
    );
  }
}

class _AddProductNav extends StatelessWidget {
  const _AddProductNav();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 412,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 412,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0x24000000))),
              ),
            ),
          ),
          const Positioned(
            left: 36,
            top: 47,
            child: Text('Home', style: AppTextStyles.profileNavLabel),
          ),
          const Positioned(
            left: 102,
            top: 47,
            child: Text('Products', style: AppTextStyles.profileNavLabel),
          ),
          const Positioned(
            left: 266,
            top: 47,
            child: Text('Orders', style: AppTextStyles.profileNavLabel),
          ),
          const Positioned(
            left: 346,
            top: 47,
            child: Text('Profile', style: AppTextStyles.profileNavLabel),
          ),
          const Positioned(
            left: 42,
            top: 19,
            child: Icon(
              Icons.home_outlined,
              size: 21,
              color: AppColors.profileNavIdle,
            ),
          ),
          const Positioned(
            left: 116,
            top: 19,
            child: Icon(
              Icons.grid_view,
              size: 22,
              color: AppColors.profileNavIdle,
            ),
          ),
          const Positioned(
            left: 276,
            top: 20,
            child: Icon(
              Icons.receipt_long_outlined,
              size: 21,
              color: AppColors.profileNavIdle,
            ),
          ),
          const Positioned(
            left: 353,
            top: 20,
            child: Icon(
              Icons.person_outline,
              size: 21,
              color: AppColors.profileNavIdle,
            ),
          ),
          Positioned(
            left: 178,
            top: -8,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.limeLight,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 7),
                ),
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
                    offset: Offset(0, 19),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 24, color: AppColors.darkCard),
            ),
          ),
          Positioned(
            left: 24,
            top: 10,
            child: BottomNavTab(onTap: () => goToHome(context), width: 60),
          ),
          Positioned(
            left: 100,
            top: 10,
            child: BottomNavTab(onTap: () => goToProducts(context), width: 60),
          ),
          Positioned(
            left: 264,
            top: 10,
            child: BottomNavTab(onTap: () => goToOrders(context), width: 60),
          ),
          Positioned(
            left: 344,
            top: 10,
            child: BottomNavTab(onTap: () => goToProfile(context), width: 60),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.height,
    required this.shadow,
    required this.children,
  });

  final double height;
  final List<BoxShadow> shadow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: shadow,
      ),
      child: Stack(children: children),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.iconSize});

  final String icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.orderTile,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Image(image: AssetImage(icon), width: iconSize, height: iconSize),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.width,
    required this.left,
    required this.text,
    required this.textWidth,
  });

  final double width;
  final double left;
  final String text;
  final double textWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 31,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: 3,
            child: LabelText(text, AppTextStyles.addChipText, width: textWidth),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.width,
    required this.filled,
    required this.dotLeft,
    required this.dotColor,
    required this.textLeft,
    required this.text,
    required this.textWidth,
    required this.style,
  });

  final double width;
  final bool filled;
  final double dotLeft;
  final Color dotColor;
  final double textLeft;
  final String text;
  final double textWidth;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 34,
      decoration: BoxDecoration(
        color: filled ? AppColors.orderDark : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: Border.all(
          color: filled ? const Color(0x0F000000) : AppColors.addChipBorder,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: dotLeft,
            top: 14,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: textLeft,
            top: 4,
            child: LabelText(text, style, width: textWidth),
          ),
        ],
      ),
    );
  }
}

const Color _dotIdle = AppColors.addDotIdle;
const Color _dotActive = AppColors.orderDark;

const List<BoxShadow> _shadowPhotos = [
  BoxShadow(color: Color(0x1A8F8F8F), offset: Offset(0, 4), blurRadius: 9),
  BoxShadow(color: Color(0x178F8F8F), offset: Offset(0, 16), blurRadius: 16),
  BoxShadow(color: Color(0x0D8F8F8F), offset: Offset(0, 36), blurRadius: 21),
  BoxShadow(color: Color(0x038F8F8F), offset: Offset(0, 63), blurRadius: 25),
];

const List<BoxShadow> _shadowCards = [
  BoxShadow(color: Color(0x1AABABAB), offset: Offset(1, 4), blurRadius: 8),
  BoxShadow(color: Color(0x17ABABAB), offset: Offset(5, 14), blurRadius: 15),
  BoxShadow(color: Color(0x0DABABAB), offset: Offset(12, 32), blurRadius: 20),
  BoxShadow(color: Color(0x03ABABAB), offset: Offset(21, 57), blurRadius: 24),
];
