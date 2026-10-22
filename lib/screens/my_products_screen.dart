import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/design_canvas.dart';

/// My Products list ΓÇö static replica of Zeplin
/// "Android Compact - 123" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae1c0e2a2f1a17cbef0e).
///
/// Built against a 412x1008 artboard. Same zoom-scroll pattern as 117:
/// fit width, scroll vertically. Visual only.
class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1008;
  static const double trimTop = 44;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: DesignCanvas(
                designWidth: designWidth,
                designHeight: designHeight,
                trimTop: trimTop,
                child: Stack(
                  children: [
                    const Positioned(left: 16, top: 68, child: _BackCircle()),
                    const Positioned(
                      left: 58,
                      top: 68,
                      child: Text(
                        'My Products',
                        style: AppTextStyles.productsTitle,
                      ),
                    ),
                    const Positioned(left: 24, top: 120, child: _SearchBar()),
                    const Positioned(left: 24, top: 184, child: _FilterTabs()),
                    const Positioned(
                      left: 24,
                      top: 247,
                      child: _ProductRow(top: 247, status: _Status.active),
                    ),
                    const Positioned(
                      left: 24,
                      top: 376,
                      child: _ProductRow(top: 376, status: _Status.outOfStock),
                    ),
                    const Positioned(
                      left: 24,
                      top: 505,
                      child: _ProductRow(top: 505, status: _Status.active),
                    ),
                    const Positioned(
                      left: 24,
                      top: 634,
                      child: _ProductRow(
                        top: 634,
                        status: _Status.draft,
                        showPublish: true,
                      ),
                    ),
                    const Positioned(left: 24, top: 765, child: _PromoCard()),
                    Positioned(
                      left: 43,
                      top: 856,
                      width: 96,
                      height: 23,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => goToAddProduct(context),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PinnedBottomNav(
                selectedIndex: 1,
                onHomeTap: () => goToHome(context),
                onProductsTap: () => goToProducts(context),
                onAddTap: () => goToAddProduct(context),
                onOrdersTap: () => goToOrders(context),
                onProfileTap: () => goToProfile(context),
              ),
            ),
          ],
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
        ),
        child: const Icon(Icons.arrow_back, size: 15, color: Colors.black),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 45,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Icon(Icons.search, size: 14, color: Color(0x8A000000)),
          ),
          const Positioned(
            left: 42,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                'Search vegetables...',
                style: TextStyle(fontSize: 12, color: Color(0x8A000000)),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 7,
            child: Container(
              width: 99,
              height: 31,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.limeCard,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '12 Products',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 45,
      decoration: const BoxDecoration(
        color: Color(0xB8E3F1CC),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: const Stack(
        children: [
          Positioned(left: 4, top: 4, child: _AllPill()),
          Positioned(
            left: 125,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                'Active',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tabGray,
                ),
              ),
            ),
          ),
          Positioned(
            left: 200,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                'Out of Stock',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tabGray,
                ),
              ),
            ),
          ),
          Positioned(
            left: 311,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                'Draft',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tabGray,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllPill extends StatelessWidget {
  const _AllPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 99,
      height: 37,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(23)),
      ),
      child: const Text(
        'All',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _Status { active, outOfStock, draft }

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.top,
    required this.status,
    this.showPublish = false,
  });

  final double top;
  final _Status status;
  final bool showPublish;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 364,
      height: 116,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 277,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          Positioned(
            left: 277,
            top: 0,
            child: Container(
              width: 87,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          const Positioned(left: 7, top: 7, child: _ProductImage()),
          const Positioned(left: 82, top: 13, child: _DotsIcon()),
          const Positioned(
            left: 122,
            top: 6,
            child: Text('Fresh Tomatoes', style: AppTextStyles.productName),
          ),
          const Positioned(
            left: 122,
            top: 27,
            child: Text(
              '50 kg available',
              style: TextStyle(fontSize: 12, color: Color(0x7A000000)),
            ),
          ),
          Positioned(left: 122, top: 52, child: _StatusPill(status: status)),
          const Positioned(
            left: 122,
            top: 80,
            child: Icon(
              Icons.analytics_outlined,
              size: 22,
              color: Color(0xFF5A5A5A),
            ),
          ),
          const Positioned(
            left: 150,
            top: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This week',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0x7A000000),
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '24 sold',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 276,
            top: 18,
            child: Container(
              width: 1,
              height: 80,
              color: AppColors.priceDivider,
            ),
          ),
          const Positioned(
            left: 301,
            top: 41,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\u20B948',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '/ kg',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0x87000000),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 19,
            child: Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: status == _Status.active
                    ? AppColors.limeCard
                    : status == _Status.outOfStock
                    ? AppColors.attentionRed
                    : AppColors.tabGray,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          if (showPublish)
            Positioned(
              left: 122,
              bottom: 4,
              child: Container(
                width: 114,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Text(
                  'Publish',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 102,
      decoration: const BoxDecoration(
        color: Color(0xFF7BAE5A),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: const Icon(Icons.eco_outlined, size: 32, color: Colors.white),
    );
  }
}

class _DotsIcon extends StatelessWidget {
  const _DotsIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.more_vert, size: 8, color: Colors.black),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final _Status status;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color dot;
    switch (status) {
      case _Status.active:
        label = 'Active';
        bg = AppColors.filterBg;
        dot = AppColors.primary;
      case _Status.outOfStock:
        label = 'Out of stock';
        bg = AppColors.outOfStockBg;
        dot = AppColors.attentionRed;
      case _Status.draft:
        label = 'Draft';
        bg = Colors.white;
        dot = AppColors.tabGray;
    }
    final double width = status == _Status.outOfStock ? 89 : 61;
    return Container(
      width: width,
      height: 19,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(11)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 126,
      decoration: const BoxDecoration(
        color: AppColors.promoBg,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Layered field waves from Zeplin Group 263 (Vector 34/35/36).
          const Positioned(
            left: 61,
            top: 64,
            child: _PromoWave(width: 302, height: 60, color: Color(0xFFE9F5C4)),
          ),
          const Positioned(
            left: 94,
            top: 79,
            child: _PromoWave(width: 270, height: 47, color: Color(0xFFDDF0B4)),
          ),
          const Positioned(
            left: 124,
            top: 98,
            child: _PromoWave(width: 240, height: 28, color: Color(0xFFD2E89B)),
          ),
          // Soil lines Vector 37/38.
          Positioned(
            left: 197,
            top: 107,
            child: Container(
              width: 107,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF739B4A),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          Positioned(
            left: 226,
            top: 113,
            child: Container(
              width: 106,
              height: 3,
              decoration: const BoxDecoration(
                color: Color(0xFF739B4A),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          // Top-right sun badges Ellipse 173/172.
          Positioned(
            left: 316,
            top: 20,
            child: Container(
              width: 29,
              height: 29,
              decoration: const BoxDecoration(
                color: Color(0xFFDEEB7B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 320,
            top: 24,
            child: Container(
              width: 21,
              height: 21,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE989),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Seedlings.
          const Positioned(
            left: 233,
            top: 83,
            child: Icon(Icons.spa, size: 29, color: Color(0xFF2E7D32)),
          ),
          const Positioned(
            left: 295,
            top: 93,
            child: Icon(Icons.spa, size: 23, color: Color(0xFF388E3C)),
          ),
          const Positioned(
            left: 19,
            top: 15,
            child: Text(
              'List more fresh\nproducts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 16 / 14,
                letterSpacing: 0.14,
              ),
            ),
          ),
          const Positioned(
            left: 19,
            top: 54,
            child: Text(
              'Reach more customers and \ngrow your farm business.',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 13 / 10,
                letterSpacing: 0.1,
                color: Color(0x8A000000),
              ),
            ),
          ),
          Positioned(
            left: 19,
            top: 91,
            child: Container(
              width: 96,
              height: 23,
              decoration: const BoxDecoration(
                color: Color(0xFF0D3B20),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCAEA71),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 7,
                    top: 7,
                    child: Icon(Icons.add, size: 9, color: Color(0xFF0D3B20)),
                  ),
                  const Positioned(
                    left: 25,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Add product',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoWave extends StatelessWidget {
  const _PromoWave({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(height / 2)),
      ),
    );
  }
}
