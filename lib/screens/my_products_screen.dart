import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';
import '../widgets/product_image_view.dart';

/// My Products list — replica of Zeplin
/// "Android Compact - 123" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae1c0e2a2f1a17cbef0e).
///
/// Built against a 412x1008 artboard. Same zoom-scroll pattern as 117:
/// fit width, scroll vertically. Listings come from the shared in-memory
/// [ProductStore]; the status tabs and search box filter the visible rows.
class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1008;
  static const double trimTop = 44;

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  _ProductFilter _filter = _ProductFilter.all;
  String _query = '';

  List<Product> _visibleProducts(List<Product> products) {
    final query = _query.trim().toLowerCase();
    final userId = ProductStore.instance.userId.trim().toLowerCase();
    return [
      for (final product in products)
        if (userId.isEmpty || product.userId.toLowerCase() == userId)
          if (_filter.matches(product) &&
              (query.isEmpty ||
                  product.name.toLowerCase().contains(query) ||
                  product.category.toLowerCase().contains(query)))
            product,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProductStore.instance,
      builder: (context, _) {
        final allProducts = ProductStore.instance.products;
        final products = _visibleProducts(allProducts);
        final double promoTop = products.isEmpty
            ? 430
            : 247 + products.length * 129 + 2;
        final double contentHeight = math.max(
          MyProductsScreen.designHeight,
          promoTop + 126 + 88 + 29,
        );
        return Scaffold(
          backgroundColor: AppColors.homeBg,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DesignCanvas(
                    designWidth: MyProductsScreen.designWidth,
                    designHeight: contentHeight,
                    trimTop: MyProductsScreen.trimTop,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 68,
                          child: PageHeader(
                            title: 'My Products',
                            onBack: () => goToHome(context),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          top: 120,
                          child: _SearchBar(
                            productCount: products.length,
                            onQueryChanged: (value) =>
                                setState(() => _query = value),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          top: 184,
                          child: _FilterTabs(
                            selected: _filter,
                            onSelected: (filter) =>
                                setState(() => _filter = filter),
                          ),
                        ),
                        if (products.isEmpty)
                          Positioned(
                            left: 24,
                            top: 247,
                            child: _EmptyProductsState(
                              filtered: allProducts.isNotEmpty,
                            ),
                          )
                        else
                          for (var i = 0; i < products.length; i++)
                            Positioned(
                              left: 24,
                              top: 247 + i * 129,
                              child: _ProductRow(product: products[i]),
                            ),
                        Positioned(
                          left: 24,
                          top: promoTop,
                          child: _PromoCard(
                            onAdd: () => goToAddProduct(context),
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
      },
    );
  }
}

enum _ProductFilter {
  all('All'),
  active('Active'),
  outOfStock('Out of Stock'),
  draft('Draft');

  const _ProductFilter(this.label);

  final String label;

  bool matches(Product product) => switch (this) {
    _ProductFilter.all => true,
    _ProductFilter.active => product.status == ProductStatus.active,
    _ProductFilter.outOfStock => product.status == ProductStatus.outOfStock,
    _ProductFilter.draft => product.status == ProductStatus.draft,
  };
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.productCount, required this.onQueryChanged});

  final int productCount;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final String countLabel = productCount == 1
        ? '1 Product'
        : '$productCount Products';
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
          Positioned(
            left: 42,
            right: 110,
            top: 0,
            bottom: 0,
            child: Center(
              child: TextField(
                key: const ValueKey('products-search'),
                onChanged: onQueryChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 12),
                cursorColor: AppColors.inputCaret,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search vegetables...',
                  hintStyle: TextStyle(fontSize: 12, color: Color(0x8A000000)),
                ),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  countLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
  const _FilterTabs({required this.selected, required this.onSelected});

  final _ProductFilter selected;
  final ValueChanged<_ProductFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final double pillLeft = switch (selected) {
      _ProductFilter.all => 4,
      _ProductFilter.active => 112,
      _ProductFilter.outOfStock => 190,
      _ProductFilter.draft => 298,
    };
    final double pillWidth = switch (selected) {
      _ProductFilter.all => 99,
      _ProductFilter.active => 60,
      _ProductFilter.outOfStock => 89,
      _ProductFilter.draft => 58,
    };
    TextStyle styleFor(_ProductFilter filter) => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: selected == filter ? AppColors.textPrimary : AppColors.tabGray,
    );

    return Container(
      width: 364,
      height: 45,
      decoration: const BoxDecoration(
        color: Color(0xB8E3F1CC),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: pillLeft,
            top: 4,
            width: pillWidth,
            height: 37,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(23)),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 0,
            width: 99,
            height: 45,
            child: GestureDetector(
              key: const ValueKey('products-filter-all'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(_ProductFilter.all),
              child: HoverPress.chip(
                child: Center(
                  child: Text(
                    _ProductFilter.all.label,
                    style: styleFor(_ProductFilter.all),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 103,
            top: 0,
            width: 85,
            height: 45,
            child: GestureDetector(
              key: const ValueKey('products-filter-active'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(_ProductFilter.active),
              child: HoverPress.chip(
                child: Center(
                  child: Text(
                    _ProductFilter.active.label,
                    style: styleFor(_ProductFilter.active),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 188,
            top: 0,
            width: 106,
            height: 45,
            child: GestureDetector(
              key: const ValueKey('products-filter-out-of-stock'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(_ProductFilter.outOfStock),
              child: HoverPress.chip(
                child: Center(
                  child: Text(
                    _ProductFilter.outOfStock.label,
                    style: styleFor(_ProductFilter.outOfStock),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 294,
            top: 0,
            width: 70,
            height: 45,
            child: GestureDetector(
              key: const ValueKey('products-filter-draft'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(_ProductFilter.draft),
              child: HoverPress.chip(
                child: Center(
                  child: Text(
                    _ProductFilter.draft.label,
                    style: styleFor(_ProductFilter.draft),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({this.filtered = false});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('products-empty'),
      width: 364,
      height: 126,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.iconCircle,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 28,
              color: AppColors.iconDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    filtered ? 'No products found' : 'No products yet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreenInk,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    filtered
                        ? 'Try another filter or search'
                        : 'Your listings will appear here',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.tabGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            key: const ValueKey('products-empty-add'),
            onTap: () => goToAddProduct(context),
            child: HoverPress.button(
              child: Container(
                width: 92,
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Add product',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.limeLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final bool showPublish = product.status == ProductStatus.draft;
    return GestureDetector(
      key: ValueKey('my-product-${product.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => goToProductDetails(context, product: product),
      child: SizedBox(
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
            Positioned(left: 7, top: 7, child: _ProductImage(product: product)),
            const Positioned(left: 82, top: 13, child: _DotsIcon()),
            Positioned(
              left: 122,
              top: 6,
              width: 150,
              child: Text(
                product.name,
                style: AppTextStyles.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              left: 122,
              top: 27,
              width: 150,
              child: Text(
                product.quantityLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0x7A000000)),
              ),
            ),
            Positioned(
              left: 122,
              top: 52,
              child: _StatusPill(status: product.status),
            ),
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
                    '0 sold',
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
            Positioned(
              left: 277,
              top: 41,
              width: 87,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.priceLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '/ ${product.unit}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0x87000000),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 19,
              child: Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: _statusAccent(product.status),
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
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 102,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: ProductImageView(
          product: product,
          placeholder: Container(
            color: const Color(0xFF7BAE5A),
            child: const Icon(
              Icons.eco_outlined,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

Color _statusAccent(ProductStatus status) {
  switch (status) {
    case ProductStatus.active:
      return AppColors.limeCard;
    case ProductStatus.outOfStock:
      return AppColors.attentionRed;
    case ProductStatus.draft:
      return AppColors.tabGray;
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

  final ProductStatus status;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color dot;
    switch (status) {
      case ProductStatus.active:
        label = 'Active';
        bg = AppColors.filterBg;
        dot = AppColors.primary;
      case ProductStatus.outOfStock:
        label = 'Out of stock';
        bg = AppColors.outOfStockBg;
        dot = AppColors.attentionRed;
      case ProductStatus.draft:
        label = 'Draft';
        bg = Colors.white;
        dot = AppColors.tabGray;
    }
    final double width = status == ProductStatus.outOfStock ? 89 : 61;
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
  const _PromoCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('products-promo'),
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
            child: GestureDetector(
              key: const ValueKey('products-add-product'),
              onTap: onAdd,
              behavior: HitTestBehavior.opaque,
              child: HoverPress.button(
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
                        child: Icon(
                          Icons.add,
                          size: 9,
                          color: Color(0xFF0D3B20),
                        ),
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
