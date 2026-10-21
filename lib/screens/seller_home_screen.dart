import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import 'my_products_screen.dart';

/// Seller Home dashboard — static replica of Zeplin
/// "Android Compact - 117" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1adaf148b8bf14a899c54).
///
/// Built against a 412x1071 artboard. Every offset below is taken from the
/// Zeplin latest-version layers, so on a matching viewport the layout renders
/// 1:1; on other sizes it scales down uniformly instead of overflowing.
/// Visual only — no network, no state.
class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1071;
  static const double trimTop = 44;

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
            children: [
              const Positioned(left: 24, top: 68, child: _Greeting()),
              const Positioned(
                left: 331,
                top: 74,
                child: _HeaderIcon(icon: Icons.notifications_outlined),
              ),
              Positioned(
                left: 363,
                top: 74,
                child: _HeaderIcon(
                  icon: Icons.settings_outlined,
                  onTap: () => goToSettings(context),
                ),
              ),
              const Positioned(left: 25, top: 143, child: _ActiveOrdersCard()),
              const Positioned(
                left: 25,
                top: 361,
                child: _SectionTitle('My Products'),
              ),
              const Positioned(left: 349, top: 365, child: _ViewAll()),
              const Positioned(
                left: 25,
                top: 389,
                child: _ProductCard(
                  name: 'Tomatoes',
                  qty: '50 kg available',
                  color: Color(0xFF7BAE5A),
                ),
              ),
              const Positioned(
                left: 187,
                top: 389,
                child: _ProductCard(
                  name: 'Spinach',
                  qty: '50 kg available',
                  color: Color(0xFF4E8A3E),
                ),
              ),
              const Positioned(left: 350, top: 389, child: _ProductCardSmall()),
              const Positioned(
                left: 25,
                top: 597,
                child: _SectionTitle('Sales Overview'),
              ),
              const Positioned(left: 318, top: 594, child: _MonthChip()),
              const Positioned(left: 25, top: 628, child: _SalesCard()),
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
              const Positioned(
                left: 24,
                top: 892,
                child: _AttentionRow(
                  title: 'Tomatoes low',
                  subtitle: 'Only 10kg remaining',
                  barColor: AppColors.attentionRed,
                  boxColor: AppColors.attentionRedBg,
                ),
              ),
              const Positioned(left: 0, top: 991, child: _BottomNav()),
              Positioned(
                left: 25,
                top: 355,
                width: 130,
                height: 30,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: AppRoutes.products),
                      builder: (_) => const MyProductsScreen(),
                    ),
                  ),
                  child: const SizedBox.expand(),
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
                      settings: const RouteSettings(name: AppRoutes.products),
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
              const Text('Ramesh Kumar', style: AppTextStyles.homeName),
              const SizedBox(width: 6),
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

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 25,
        height: 25,
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
              style: AppTextStyles.homeHeroDesc.copyWith(height: 1.5),
            ),
          ),
          Positioned(
            left: 20,
            top: 162,
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => goToOrders(context),
                  child: Container(
                    width: 102,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.all(Radius.circular(19)),
                    ),
                    child: const Text(
                      'View orders',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.limeLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    size: 14,
                    color: AppColors.darkCard,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              width: 136,
              height: 21,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xC2DAEFB8),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                border: Border.all(color: const Color(0x63CDEB6B)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
            right: 18,
            top: 20,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 27,
                    color: AppColors.limeLight,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 52,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 27,
                    color: AppColors.darkCard,
                  ),
                ),
              ],
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.qty,
    required this.color,
  });

  final String name;
  final String qty;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      height: 188,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 84,
            top: 7,
            child: Container(
              width: 52,
              height: 17,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                border: Border.all(color: const Color(0x12000000)),
              ),
              child: const Center(
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
              height: 47,
              padding: const EdgeInsets.only(
                left: 13,
                right: 6,
                top: 2,
                bottom: 2,
              ),
              decoration: const BoxDecoration(
                color: Color(0x1A000000),
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
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      qty,
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
    );
  }
}

class _ProductCardSmall extends StatelessWidget {
  const _ProductCardSmall();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 188,
      decoration: const BoxDecoration(
        color: Color(0xFF8FBF6E),
        borderRadius: BorderRadius.all(Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 47,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0x1A000000),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Carrots',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '50 kg',
                      style: TextStyle(
                        fontSize: 9,
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
    );
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
      padding: const EdgeInsets.fromLTRB(21, 14, 21, 10),
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
              _SalesStat(number: '12', label: 'Orders', dot: Colors.white),
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
        borderRadius: const BorderRadius.all(Radius.circular(17)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 1,
            top: 15,
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
            left: 22,
            top: 15,
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
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 412,
      height: 80,
      child: Stack(
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
            child: Text(
              'Home',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.limeLight,
              ),
            ),
          ),
          const Positioned(
            left: 102,
            top: 47,
            child: Text(
              'Products',
              style: TextStyle(fontSize: 12, color: Color(0x54000000)),
            ),
          ),
          const Positioned(
            left: 266,
            top: 47,
            child: Text(
              'Orders',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0x54000000),
              ),
            ),
          ),
          const Positioned(
            left: 346,
            top: 47,
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0x54000000),
              ),
            ),
          ),
          const Positioned(
            left: 42,
            top: 20,
            child: Icon(
              Icons.home_filled,
              size: 21,
              color: AppColors.limeLight,
            ),
          ),
          const Positioned(
            left: 116,
            top: 20,
            child: Icon(Icons.grid_view, size: 22, color: Color(0x54000000)),
          ),
          const Positioned(
            left: 276,
            top: 20,
            child: Icon(
              Icons.receipt_long_outlined,
              size: 21,
              color: Color(0x54000000),
            ),
          ),
          const Positioned(
            left: 353,
            top: 20,
            child: Icon(
              Icons.person_outline,
              size: 21,
              color: Color(0x54000000),
            ),
          ),
          Positioned(
            left: 178,
            top: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.limeLight,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 7),
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
