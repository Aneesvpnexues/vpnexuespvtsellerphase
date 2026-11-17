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
/// Built against a trimmed 412x885 artboard. Every offset below is taken
/// from the Zeplin latest-version layers, so on a matching viewport the
/// layout renders 1:1; on other sizes it scales down uniformly instead of
/// overflowing. The product strip reads the shared in-memory [ProductStore].
class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 885;
  static const double trimTop = 44;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProductStore.instance,
      builder: (context, _) {
        final products = ProductStore.instance.products;
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
                          left: 327.5,
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
                          left: 358.5,
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
                          height: 204,
                          child: _HomeProducts(products: products),
                        ),
                        const Positioned(
                          left: 25,
                          top: 613,
                          child: _SectionTitle('Sales Overview'),
                        ),
                        const Positioned(
                          left: 25,
                          top: 644,
                          child: _SalesCard(),
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
          AnimatedBuilder(
            animation: SellerProfileStore.instance,
            builder: (context, _) => Text(
              SellerProfileStore.instance.displayLocation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.homeLocation,
            ),
          ),
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
        child: Icon(icon, size: 17, color: AppColors.iconDark),
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
          Positioned(
            left: 20,
            top: 75,
            child: Text(
              '${ProductStore.instance.count} new orders',
              style: AppTextStyles.homeHeroBig,
            ),
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
                      left: 9,
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
        height: 204,
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
              right: 10,
              top: 8,
              child: AnimatedBuilder(
                animation: SellerProfileStore.instance,
                builder: (context, _) => Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xD6CDEB6B),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 11,
                        color: Color(0xFF144326),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        SellerProfileStore.instance.shortLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: Color(0xFF144326),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 68,
                padding: const EdgeInsets.only(
                  left: 13,
                  right: 6,
                  top: 4,
                  bottom: 10,
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



enum _SalesPeriod { weekly, monthly, yearly }

class _SalesSnapshot {
  const _SalesSnapshot({
    required this.label,
    required this.total,
    required this.delta,
    required this.deltaLabel,
    required this.orders,
    required this.complete,
    required this.progress,
    required this.percent,
  });

  final String label;
  final String total;
  final String delta;
  final String deltaLabel;
  final String orders;
  final String complete;
  final String progress;
  final double percent;
}

const Map<_SalesPeriod, _SalesSnapshot> _salesData =
    <_SalesPeriod, _SalesSnapshot>{
      _SalesPeriod.weekly: _SalesSnapshot(
        label: 'Total sales this week',
        total: '\u20B96,200',
        delta: '+8%',
        deltaLabel: 'vs last week',
        orders: '5',
        complete: '3',
        progress: '2',
        percent: 0.58,
      ),
      _SalesPeriod.monthly: _SalesSnapshot(
        label: 'Total sales this month',
        total: '\u20B923,850',
        delta: '+12%',
        deltaLabel: 'vs last week',
        orders: '12',
        complete: '8',
        progress: '4',
        percent: 0.72,
      ),
      _SalesPeriod.yearly: _SalesSnapshot(
        label: 'Total sales this year',
        total: '\u20B91,43,820',
        delta: '+12%',
        deltaLabel: 'vs last week',
        orders: '148',
        complete: '138',
        progress: '8',
        percent: 0.64,
      ),
    };

class _SalesCard extends StatefulWidget {
  const _SalesCard();

  @override
  State<_SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends State<_SalesCard> {
  _SalesPeriod _period = _SalesPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final _SalesSnapshot data = _salesData[_period]!;

    return Container(
      width: 362,
      height: 185,
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.all(Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2ECDEB6B), Color(0x00CDEB6B)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            child: _SalesSegmentTrack(
              period: _period,
              onChanged: (value) => setState(() => _period = value),
            ),
          ),
          Positioned(
            left: 14,
            top: 52,
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xA1FFFFFF),
                height: 1.0,
              ),
            ),
          ),
          Positioned(
            left: 13,
            top: 66,
            child: Text(
              data.total,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.limeLight,
                height: 1.0,
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 104,
            child: _SalesTrendPill(delta: data.delta, label: data.deltaLabel),
          ),
          Positioned(
            right: 14,
            top: 52,
            child: _ProgressRing(percent: data.percent, size: 56),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 136,
            child: Container(height: 1, color: const Color(0x26CDEB6B)),
          ),
          Positioned(
            left: 14,
            top: 146,
            child: _SalesStat(
              number: data.orders,
              label: 'Orders',
              dot: Colors.white,
            ),
          ),
          Positioned(
            left: 121,
            top: 146,
            child: _SalesStat(
              number: data.complete,
              label: 'Complete',
              dot: AppColors.limeLight,
              leadingBar: true,
            ),
          ),
          Positioned(
            left: 228,
            top: 146,
            child: _SalesStat(
              number: data.progress,
              label: 'Progress',
              dot: const Color(0xFFE9B949),
              leadingBar: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesSegmentTrack extends StatelessWidget {
  const _SalesSegmentTrack({required this.period, required this.onChanged});

  final _SalesPeriod period;
  final ValueChanged<_SalesPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 334,
      height: 30,
      decoration: const BoxDecoration(
        color: Color(0xFF184E2C),
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Row(
        children: [
          _SalesSegment(
            label: 'Weekly',
            selected: period == _SalesPeriod.weekly,
            onTap: () => onChanged(_SalesPeriod.weekly),
          ),
          _SalesSegment(
            label: 'Monthly',
            selected: period == _SalesPeriod.monthly,
            onTap: () => onChanged(_SalesPeriod.monthly),
          ),
          _SalesSegment(
            label: 'Yearly',
            selected: period == _SalesPeriod.yearly,
            onTap: () => onChanged(_SalesPeriod.yearly),
          ),
        ],
      ),
    );
  }
}

class _SalesSegment extends StatelessWidget {
  const _SalesSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: HoverPress.chip(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.limeLight : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: selected
                      ? const Color(0xFF144326)
                      : const Color(0xC2FFFFFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesTrendPill extends StatelessWidget {
  const _SalesTrendPill({required this.delta, required this.label});

  final String delta;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: const BoxDecoration(
        color: Color(0x33CDEB6B),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.trending_up,
            size: 11,
            color: AppColors.limeLight,
          ),
          const SizedBox(width: 4),
          Text(
            '$delta $label',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: AppColors.limeLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percent, this.size = 56});

  final double percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color ring = AppColors.limeLight;
    return SizedBox(
      key: const ValueKey('home-sales-ring'),
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(percent: percent, color: ring),
        child: Center(
          child: Container(
            width: size - 16,
            height: size - 16,
            decoration: const BoxDecoration(
              color: Color(0xFF184E2C),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: AppColors.limeLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 4;

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0x3DCDEB6B);
    canvas.drawCircle(center, radius, track);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    const double start = -1.57079632679; // -90 degrees
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      6.28318530718 * percent.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}

class _SalesStat extends StatelessWidget {
  const _SalesStat({
    required this.number,
    required this.label,
    required this.dot,
    this.leadingBar = false,
  });

  final String number;
  final String label;
  final Color dot;
  final bool leadingBar;

  @override
  Widget build(BuildContext context) {
    final Widget stat = FittedBox(
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

    if (!leadingBar) return stat;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 1,
          height: 30,
          child: ColoredBox(color: Color(0x33FFFFFF)),
        ),
        const SizedBox(width: 10),
        stat,
      ],
    );
  }
}
