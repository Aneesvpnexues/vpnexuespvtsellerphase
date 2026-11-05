import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seller_app/screens/notifications_screen.dart';

import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/product_image_view.dart';
import 'my_products_screen.dart';

/// Seller Home dashboard — static replica of Zeplin
/// "Android Compact - 117" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1adaf148b8bf14a899c54).
///
/// Built against a 412x1071 artboard. Every offset below is taken from the
/// Zeplin latest-version layers, so on a matching viewport the layout renders
/// 1:1; on other sizes it scales down uniformly instead of overflowing.
/// The product strip reads the shared in-memory [ProductStore].
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
                        const Positioned(left: 22, top: 74, child: _Greeting()),
                        Positioned(
                          left: 330.5,
                          top: 73.5,
                          child: _HeaderButton(
                            key: const Key('home-notifications'),
                            icon: Icons.notifications,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 361.5,
                          top: 73.5,
                          child: _HeaderButton(
                            key: const Key('home-settings'),
                            icon: Icons.settings_outlined,
                            onTap: () => goToSettings(context),
                          ),
                        ),
                        const Positioned(
                          left: 25,
                          top: 143,
                          child: _ActiveOrdersCard(),
                        ),
                        const Positioned(
                          left: 25,
                          top: 361,
                          child: _SectionTitle('My Products'),
                        ),
                        Positioned(
                          left: 25,
                          top: 355,
                          width: 130,
                          height: 30,
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
                        Positioned(
                          left: 25,
                          right: 0,
                          top: 389,
                          height: 188,
                          child: _HomeProducts(products: products),
                        ),
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
                        const Positioned(
                          left: 25,
                          top: 793,
                          child: _SectionTitle('Needs Attention'),
                        ),
                        Positioned(
                          left: 25,
                          top: 819,
                          child: _AttentionRow(
                            key: const Key('home-attention-orders'),
                            title: '2 New orders',
                            subtitle: 'Hurry up',
                            barColor: AppColors.attentionAmber,
                            boxColor: AppColors.attentionAmberBg,
                            onTap: () => goToOrders(context),
                          ),
                        ),
                        if (lowStock != null)
                          Positioned(
                            left: 25,
                            top: 893,
                            child: _AttentionRow(
                              key: const Key('home-attention-low-stock'),
                              title: '${lowStock.name} low',
                              subtitle:
                                  'Only ${lowStock.quantity}${lowStock.unit} remaining',
                              barColor: AppColors.attentionRed,
                              boxColor: AppColors.attentionRedBg,
                              onTap: () => goToProductDetails(
                                context,
                                product: lowStock,
                              ),
                            ),
                          ),
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
                            child: HoverPress.chip(
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 19,
                                    top: 7,
                                    child: _ViewAll(),
                                  ),
                                ],
                              ),
                            ),
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

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Hello,', style: AppTextStyles.homeHello),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AnimatedBuilder(
                  animation: SellerProfileStore.instance,
                  builder: (context, _) => Text(
                    SellerProfileStore.instance.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homeName,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Container(
                width: 21,
                height: 21,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E8B4B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Salem, Tamil Nadu', style: AppTextStyles.homeLocation),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.iconCircle,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: AppColors.iconDark),
      ),
    );
  }
}

class _ActiveOrdersCard extends StatelessWidget {
  const _ActiveOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 205,
      decoration: const BoxDecoration(
        color: AppColors.limeCard,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 190,
            top: 0,
            child: Container(
              width: 172,
              height: 156,
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
            child: Text('ACTIVE ORDERS', style: AppTextStyles.homeCardLabel),
          ),
          const Positioned(
            left: 20,
            top: 42,
            child: Text('You have', style: AppTextStyles.homeHeroSmall),
          ),
          const Positioned(
            left: 20,
            top: 75,
            child: Text('2 new orders', style: AppTextStyles.homeHeroBig),
          ),
          Positioned(
            left: 23,
            top: 113,
            right: 23,
            child: Text(
              'Review and accept to keep\nyour business growing',
              style: AppTextStyles.homeHeroDesc.copyWith(height: 1.25),
            ),
          ),
          Positioned(
            left: 20,
            top: 162,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => goToOrders(context),
              child: Container(
                width: 102,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.all(Radius.circular(19)),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      left: 14,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          'View orders',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.limeLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: AppColors.darkCard,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 17,
            child: Container(
              width: 126,
              height: 21,
              padding: const EdgeInsets.only(left: 8, right: 6),
              decoration: BoxDecoration(
                color: const Color(0xC2DAEFB8),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                border: Border.all(color: const Color(0x63CDEB6B)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WaitingDot(),
                    SizedBox(width: 5),
                    Text(
                      'Waiting for your response',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF030302),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 281,
            top: 30,
            child: Transform.rotate(
              angle: 20 * math.pi / 180,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Image.asset(
                  'assets/order/ic_hero_box_dark.png',
                  key: const Key('home-hero-tile-dark'),
                  width: 48,
                  height: 48,
                ),
              ),
            ),
          ),
          Positioned(
            left: 261,
            top: 52,
            child: Transform.rotate(
              angle: -12 * math.pi / 180,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Image.asset(
                  'assets/order/ic_hero_box_white.png',
                  key: const Key('home-hero-tile-white'),
                  width: 48,
                  height: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingDot extends StatelessWidget {
  const _WaitingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.attentionRed,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.homeSection);
  }
}

class _ViewAll extends StatelessWidget {
  const _ViewAll();

  @override
  Widget build(BuildContext context) {
    return const Text('View all', style: AppTextStyles.homeViewAll);
  }
}

class _HomeProducts extends StatelessWidget {
  const _HomeProducts({required this.products});

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
      separatorBuilder: (context, index) => const SizedBox(width: 18),
      itemBuilder: (context, index) => _ProductCard(product: products[index]),
    );
  }
}

class _EmptyHomeProducts extends StatelessWidget {
  const _EmptyHomeProducts();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-empty-products'),
      width: 362,
      height: 144,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(color: AppColors.cardBorder),
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
                    style: TextStyle(fontSize: 11, color: AppColors.tabGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            key: const ValueKey('home-empty-add'),
            onTap: () => goToAddProduct(context),
            child: HoverPress.button(
              child: Container(
                width: 92,
                height: 34,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.all(Radius.circular(17)),
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('home-product-${product.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => goToProductDetails(context, product: product),
      child: Container(
        width: 144,
        height: 188,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _categoryColor(product.category),
          borderRadius: const BorderRadius.all(Radius.circular(26)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImageView(
              product: product,
              placeholder: const SizedBox.expand(),
            ),
            Positioned(
              right: 12,
              top: 8,
              child: Container(
                width: 44,
                height: 16.5,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                  border: Border.all(color: const Color(0x12000000)),
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 52,
                padding: const EdgeInsets.only(
                  left: 13,
                  right: 6,
                  top: 4,
                  bottom: 2,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x1A000000), Color(0xB3000000)],
                  ),
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

class _MonthChip extends StatelessWidget {
  const _MonthChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 69,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.all(Radius.circular(5)),
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

class _SalesCard extends StatelessWidget {
  const _SalesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 146,
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 21,
            top: 20,
            child: Text(
              'Total sales this month',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xA1FFFFFF),
                height: 1.0,
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 37,
            child: Text(
              '\u20B924,850',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.limeLight,
                height: 1.0,
              ),
            ),
          ),
          Positioned(
            right: 13,
            top: 22,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10462A),
                border: Border.all(color: AppColors.limeLight, width: 5),
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
          ),
          Positioned(
            left: 21,
            right: 21,
            top: 87,
            child: Container(height: 1, color: const Color(0x26CDEB6B)),
          ),
          const Positioned(
            left: 22,
            top: 101,
            child: _SalesStat(
              number: '12',
              label: 'Orders',
              dot: Colors.white,
            ),
          ),
          const Positioned(
            left: 129,
            top: 101,
            child: _SalesStat(
              number: '8',
              label: 'Complete',
              dot: AppColors.limeLight,
            ),
          ),
          const Positioned(
            left: 246,
            top: 101,
            child: _SalesStat(
              number: '4',
              label: 'Progress',
              dot: Color(0xFFE9B949),
            ),
          ),
        ],
      ),
    );
  }
}

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
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
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

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.barColor,
    required this.boxColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color barColor;
  final Color boxColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 362,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(17)),
          border: Border.all(color: const Color(0x12000000)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 14,
              child: Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
            Positioned(
              left: 21,
              top: 14,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 23,
                  color: Color(0xFF5A4A1A),
                ),
              ),
            ),
            Positioned(
              left: 76,
              top: 11,
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
            const Positioned(
              right: 12,
              top: 23,
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF8A8A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

