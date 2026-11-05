
import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/design_canvas.dart';
import 'my_products_screen.dart';

/// Seller Home dashboard — updated Zeplin replica.
class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1071;
  static const double trimTop = 44;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProductStore.instance,
      builder: (context, _) {
        final products = ProductStore.instance.products;

        Product? lowStock;
        for (final product in products) {
          if (product.quantity <= 10) {
            lowStock = product;
            break;
          }
        }

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
                        const Positioned(
                          left: 24,
                          top: 68,
                          child: _Greeting(),
                        ),

                        // Notification button
const Positioned(
  left: 295,
  top: 65,
  child: _HeaderIcon(
    icon: Icons.notifications_outlined,
  ),
),

// Settings button
Positioned(
  left: 350,
  top: 65,
  child: _HeaderIcon(
    icon: Icons.settings_outlined,
    onTap: () => goToSettings(context),
  ),
),

                        // Active Orders
                        const Positioned(
                          left: 25,
                          top: 143,
                          child: _ActiveOrdersCard(),
                        ),

                        // My Products section
                        const Positioned(
                          left: 25,
                          top: 361,
                          child: _SectionTitle('My Products'),
                        ),

                        const Positioned(
                          left: 349,
                          top: 365,
                          child: _ViewAll(),
                        ),

                        // View all products tap area
                        Positioned(
                          left: 25,
                          top: 355,
                          width: 362,
                          height: 34,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(
                                  name: AppRoutes.products,
                                ),
                                builder: (_) => const MyProductsScreen(),
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),

                        // Product strip
                        Positioned(
                          left: 25,
                          top: 389,
                          width: 362,
                          height: 188,
                          child: _HomeProducts(
                            products: products,
                          ),
                        ),

                        // Sales Overview
                        const Positioned(
                          left: 25,
                          top: 597,
                          child: _SectionTitle('Sales Overview'),
                        ),

                        const Positioned(
                          left: 318,
                          top: 594,
                          child: _MonthChip(),
                        ),

                        const Positioned(
                          left: 25,
                          top: 628,
                          child: _SalesCard(),
                        ),

                        // Needs Attention
                        const Positioned(
                          left: 25,
                          top: 793,
                          child: _SectionTitle('Needs Attention'),
                        ),

                        const Positioned(
                          left: 24,
                          top: 818,
                          child: _AttentionRow(
                            title: '2 New orders',
                            subtitle: 'Hurry up',
                            barColor: AppColors.attentionAmber,
                            boxColor: AppColors.attentionAmberBg,
                          ),
                        ),

                        // Dynamic low-stock notification
                        if (lowStock != null)
                          Positioned(
                            left: 24,
                            top: 892,
                            child: _AttentionRow(
                              title: '${lowStock.name} low',
                              subtitle:
                                  'Only ${lowStock.quantity}${lowStock.unit} remaining',
                              barColor: AppColors.attentionRed,
                              boxColor: AppColors.attentionRedBg,
                            ),
                          ),

                        // Additional View All tap area
                        Positioned(
                          left: 330,
                          top: 358,
                          width: 60,
                          height: 28,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(
                                  name: AppRoutes.products,
                                ),
                                builder: (_) => const MyProductsScreen(),
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fixed bottom navigation
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: PinnedBottomNav(
                    selectedIndex: 0,
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

 // ------------------------------------------------------------
 // GREETING
 // ------------------------------------------------------------

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 275,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Hello,',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGreenInk,
                ),
              ),

              const SizedBox(width: 6),

              Flexible(
                child: AnimatedBuilder(
                  animation: SellerProfileStore.instance,
                  builder: (context, _) => Text(
                    SellerProfileStore.instance.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreenInk,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Container(
                width: 19,
                height: 19,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E8B4B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Icon(
      Icons.location_on_outlined,
      size: 14,
      color: AppColors.tabGray,
    ),
    const SizedBox(width: 4),
    const Text(
      'Salem, Tamil Nadu',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.tabGray,
      ),
    ),
  ],
),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// HEADER ICONS
// ------------------------------------------------------------

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.iconCircle,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 25,
            color: AppColors.iconDark,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// ACTIVE ORDERS CARD
// ------------------------------------------------------------

class _ActiveOrdersCard extends StatelessWidget {
  const _ActiveOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 210,
      decoration: const BoxDecoration(
        color: AppColors.limeCard,
        borderRadius: BorderRadius.all(
          Radius.circular(22),
        ),
      ),
      child: Stack(
        children: [
          // Decorative background
          Positioned(
            left: 190,
            top: 0,
            child: Container(
              width: 172,
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFD4EE96),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(80),
                ),
              ),
            ),
          ),

          const Positioned(
            left: 20,
            top: 18,
            child: Text(
              'ACTIVE ORDERS',
              style: AppTextStyles.homeCardLabel,
            ),
          ),

          const Positioned(
            left: 20,
            top: 42,
            child: Text(
              'You have',
              style: AppTextStyles.homeHeroSmall,
            ),
          ),

          const Positioned(
            left: 20,
            top: 75,
            child: Text(
              '2 new orders',
              style: AppTextStyles.homeHeroBig,
            ),
          ),

          // Corrected grammar
          

          // Larger View Orders button with arrow inside
          Positioned(
            left: 20,
            top: 161,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => goToOrders(context),
                child: Container(
                  width: 126,
                  height: 36,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.all(
                      Radius.circular(22),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View orders',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 7),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.limeLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
// Decorative half-circle behind waiting status
Positioned(
  right: 5,
  bottom: -140,
  child: Container(
    width: 200,
    height: 200,
    decoration: const BoxDecoration(
      color: Color(0xFFB8D77C),
      shape: BoxShape.circle,
    ),
  ),
),
          // Enlarged waiting status pill
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 166,
              height: 27,
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xC2DAEFB8),
                borderRadius: const BorderRadius.all(
                  Radius.circular(16),
                ),
                border: Border.all(
                  color: const Color(0x63CDEB6B),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _WaitingDot(),
                  SizedBox(width: 7),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Waiting for your response',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF030302),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Order illustrations
          // Overlapping tilted order cards
// Properly overlapping tilted order cards
Positioned(
  right: 30,
  top: 15,
  child: SizedBox(
    width: 115,
    height: 95,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Back card (Dark Green Card - positioned at top-right)
        Positioned(
          right: 0,
          top: 0,
          child: Transform.rotate(
            angle: 0.25, // Adjust rotation angle to match reference
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 7,
                    offset: const Offset(2, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.view_in_ar,
                size: 28,
                color: AppColors.limeLight,
              ),
            ),
          ),
        ),
const Positioned(
            left: -195,
            top: 99,
            // right: 20,
            child: Text(
              'Review and accept orders to\ngrow your business.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGreenInk,
                height: 1.4,
              ),
            ),
          ),
        // 2. Front card (White Card - positioned at bottom-left overlapping the green card)
        Positioned(
          right: 25,
          top: 15,
          child: Transform.rotate(
            angle: 0.25, // Matching rotation angle
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(2, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.view_in_ar,
                size: 28,
                color: AppColors.darkCard,
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

// ------------------------------------------------------------
// WAITING DOT
// ------------------------------------------------------------

class _WaitingDot extends StatelessWidget {
  const _WaitingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.attentionRed,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ------------------------------------------------------------
// SECTION TITLE
// ------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.homeSection,
    );
  }
}

// ------------------------------------------------------------
// VIEW ALL
// ------------------------------------------------------------

class _ViewAll extends StatelessWidget {
  const _ViewAll();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'View all',
      style: AppTextStyles.homeViewAll,
    );
  }
}

// ------------------------------------------------------------
// HOME PRODUCTS
// ------------------------------------------------------------

class _HomeProducts extends StatelessWidget {
  const _HomeProducts({
    required this.products,
  });

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyHomeProducts();
    }

    return ListView.separated(
      key: const ValueKey('home-products'),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: 18),
      itemBuilder: (context, index) {
        return _ProductCard(
          product: products[index],
        );
      },
    );
  }
}

// ------------------------------------------------------------
// EMPTY PRODUCTS
// ------------------------------------------------------------

class _EmptyHomeProducts extends StatelessWidget {
  const _EmptyHomeProducts();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-empty-products'),
      width: 362,
      height: 144,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(22),
        ),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.iconCircle,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 24,
              color: AppColors.iconDark,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No products yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreenInk,
                    ),
                  ),
                ),

                SizedBox(height: 4),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Start selling today',
                    style: TextStyle(
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
            key: const ValueKey('home-empty-add'),
            onTap: () => goToAddProduct(context),
            child: Container(
              width: 92,
              height: 36,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
              ),
              decoration: const BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
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
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// PRODUCT CARD
// ------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ProductPhoto? photo = product.coverPhoto;

    return GestureDetector(
      key: ValueKey('home-product-${product.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => goToProductDetails(
        context,
        product: product,
      ),
      child: Container(
        width: 144,
        height: 188,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _categoryColor(product.category),
          borderRadius: const BorderRadius.all(
            Radius.circular(26),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image.memory(
                photo.bytes,
                fit: BoxFit.cover,
              ),

            // Product status
            Positioned(
              right: 8,
              top: 7,
              child: Container(
                width: 58,
                height: 17,
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(30),
                  ),
                  border: Border.all(
                    color: const Color(0x12000000),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    product.status.label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(product.status),
                    ),
                  ),
                ),
              ),
            ),

            // Product name and quantity
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 52,
                padding: const EdgeInsets.only(
                  left: 13,
                  right: 6,
                  top: 2,
                  bottom: 2,
                ),
                decoration: const BoxDecoration(
                  color: Color(0x66000000),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        product.quantityLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xDBFFFFFF),
                          height: 1.0,
                        ),
                      ),
                    ],
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

// ------------------------------------------------------------
// PRODUCT CATEGORY COLORS
// ------------------------------------------------------------

Color _categoryColor(String category) {
  switch (category) {
    case 'Fruits':
      return const Color(0xFFE2A84B);

    case 'Grains & pulses':
      return const Color(0xFFB89B5E);

    default:
      return const Color(0xFF7BAE5A);
  }
}

// ------------------------------------------------------------
// PRODUCT STATUS COLORS
// ------------------------------------------------------------

Color _statusColor(ProductStatus status) {
  switch (status) {
    case ProductStatus.active:
      return AppColors.primary;

    case ProductStatus.outOfStock:
      return AppColors.attentionRed;

    case ProductStatus.draft:
      return AppColors.tabGray;
  }
}

// ------------------------------------------------------------
// MONTH CHIP
// ------------------------------------------------------------

class _MonthChip extends StatelessWidget {
  const _MonthChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 69,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.all(
          Radius.circular(6),
        ),
      ),
      child: const Text(
        'This Month',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF104526),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// SALES CARD
// ------------------------------------------------------------

class _SalesCard extends StatelessWidget {
  const _SalesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 146,
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.all(
          Radius.circular(22),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        21,
        14,
        21,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Total sales this month',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xA1FFFFFF),
              height: 1.0,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '\u20B924,850',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.limeLight,
                  height: 1.0,
                ),
              ),

              const Spacer(),

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10462A),
                  border: Border.all(
                    color: AppColors.limeLight,
                    width: 5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '72%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 6),
            color: const Color(0x26CDEB6B),
          ),

          const SizedBox(height: 6),

          const Row(
            children: [
              _SalesStat(
                number: '12',
                label: 'Orders',
                dot: Colors.white,
              ),

              SizedBox(width: 28),

              _SalesStat(
                number: '8',
                label: 'Complete',
                dot: AppColors.limeLight,
              ),

              SizedBox(width: 28),

              _SalesStat(
                number: '4',
                label: 'Progress',
                dot: Color(0xFFE9B949),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SALES STATISTICS
// ------------------------------------------------------------

class _SalesStat extends StatelessWidget {
  const _SalesStat({
    required this.number,
    required this.label,
    required this.dot,
  });

  final String number;
  final String label;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 2),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 4),

              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xC2FFFFFF),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// NEEDS ATTENTION ROW
// ------------------------------------------------------------

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.title,
    required this.subtitle,
    required this.barColor,
    required this.boxColor,
  });

  final String title;
  final String subtitle;
  final Color barColor;
  final Color boxColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(
          Radius.circular(17),
        ),
        border: Border.all(
          color: const Color(0x12000000),
        ),
      ),
      child: Stack(
        children: [
          // Colored indicator
          Positioned(
            left: 1,
            top: 15,
            child: Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.all(
                  Radius.circular(2),
                ),
              ),
            ),
          ),

          // Icon background
          Positioned(
            left: 22,
            top: 15,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 23,
                color: Color(0xFF5A4A1A),
              ),
            ),
          ),

          // Attention details
          Positioned(
            left: 76,
            top: 12,
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0x8A000000),
                  ),
                ),
              ],
            ),
          ),

          // Forward indicator
          const Positioned(
            right: 12,
            top: 24,
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: Color(0xFF8A8A8A),
            ),
          ),
        ],
      ),
    );
  }
}
