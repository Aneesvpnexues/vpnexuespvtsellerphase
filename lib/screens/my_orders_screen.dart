import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/design_canvas.dart';
import 'order_details_screen.dart';
import 'order_privew.dart';

/// My Orders list ΓÇö static replica of Zeplin
/// "Android Compact - 132" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae17402fbd4010868423).
///
/// Built against a 412x1154 artboard. Same zoom-scroll pattern as 117/123:
/// fit width, scroll vertically. Visual only.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1154;
  static const double trimTop = 49;

  @override
  Widget build(BuildContext context) {
    void openOrderPrivew() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.orderPrivew),
        builder: (_) => const OrderPrivewScreen(),
      ),
    );

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
                    const Positioned(left: 24, top: 73, child: _BackCircle()),
                    const Positioned(
                      left: 74,
                      top: 73,
                      child: Text(
                        'My Orders',
                        style: AppTextStyles.productsTitle,
                      ),
                    ),
                    const Positioned(left: 24, top: 122, child: _SearchSort()),
                    const Positioned(left: 24, top: 181, child: _OrderTabs()),
                    Positioned(
                      left: 24,
                      top: 241,
                      child: _OrderBlock(
                        store: 'Akash Stores',
                        orderId: '#NX4582',
                        date: '12 Mar 2024, 10:30 AM',
                        iconBg: AppColors.orderYellowBg,
                        items: '4 items',
                        thumbs: 3,
                        extra: '+1',
                        price: '\u20B92,400',
                        status: 'Accepted',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(
                              name: AppRoutes.orderDetails,
                            ),
                            builder: (_) => const OrderDetailsScreen(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 407,
                      child: _OrderBlock(
                        store: 'Hotel Green Leaf',
                        orderId: '#NX4581',
                        date: '12 Mar 2024, 4:20 AM',
                        iconBg: AppColors.orderBlueBg,
                        items: '2 items',
                        thumbs: 2,
                        extra: '',
                        price: '\u20B91,400',
                        status: 'Accepted',
                        onTap: openOrderPrivew,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 573,
                      child: _OrderBlock(
                        store: 'Annapoorna Mess',
                        orderId: '#NX4580',
                        date: '9 Mar 2024, 1:20 PM',
                        iconBg: AppColors.darkCard,
                        iconColor: Colors.white,
                        items: '5 items',
                        thumbs: 3,
                        extra: '+2',
                        price: '\u20B93,400',
                        status: 'Pending',
                        onTap: openOrderPrivew,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 739,
                      child: _OrderBlock(
                        store: 'Daily Needs',
                        orderId: '#NX4579',
                        date: '12 Mar 2024, 4:20 AM',
                        iconBg: AppColors.attentionRedBg,
                        items: '4 items',
                        thumbs: 3,
                        extra: '+1',
                        price: '\u20B93,000',
                        status: 'Confirmed',
                        onTap: openOrderPrivew,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 905,
                      child: _OrderBlock(
                        store: 'Daily Needs',
                        orderId: '#NX4579',
                        date: '12 Mar 2024, 4:20 AM',
                        iconBg: AppColors.orderPurpleBg,
                        items: '3 items',
                        thumbs: 3,
                        extra: '',
                        price: '\u20B93,500',
                        status: 'Delivered',
                        onTap: openOrderPrivew,
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
                selectedIndex: 2,
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

class _SearchSort extends StatelessWidget {
  const _SearchSort();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 364,
      height: 45,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 253,
              height: 45,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 19,
                    top: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.search,
                      size: 14,
                      color: Color(0x8A000000),
                    ),
                  ),
                  Positioned(
                    left: 42,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        'Search vegetables...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0x8A000000),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 260,
            top: 0,
            child: Container(
              width: 103,
              height: 45,
              decoration: const BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 12,
                      color: Colors.white,
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

class _OrderTabs extends StatelessWidget {
  const _OrderTabs();

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
                'Pending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tabGray,
                ),
              ),
            ),
          ),
          Positioned(
            left: 282,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                'Confirmed',
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

class _OrderBlock extends StatelessWidget {
  const _OrderBlock({
    required this.store,
    required this.orderId,
    required this.date,
    required this.iconBg,
    this.iconColor = const Color(0xFF5A4A1A),
    required this.items,
    required this.thumbs,
    required this.extra,
    required this.price,
    required this.status,
    this.onTap,
  });

  final String store;
  final String orderId;
  final String date;
  final Color iconBg;
  final Color iconColor;
  final String items;
  final int thumbs;
  final String extra;
  final String price;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = SizedBox(
      width: 363,
      height: 154,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 363,
              height: 69,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 69,
            child: Container(
              width: 363,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          Positioned(
            left: 1,
            top: 19,
            child: Container(
              width: 3,
              height: 31,
              decoration: const BoxDecoration(
                color: AppColors.limeCard,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 16,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 16,
                color: iconColor,
              ),
            ),
          ),
          Positioned(
            left: 65,
            top: 13,
            child: Text(store, style: AppTextStyles.orderStore),
          ),
          Positioned(
            left: 65,
            top: 31,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0x7A000000),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Color(0x8F000000),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0x7A000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 11,
            top: 9,
            child: _OrderStatusPill(status: status),
          ),
          Positioned(
            left: 20,
            top: 68,
            child: Container(
              width: 324,
              height: 1,
              color: const Color(0x1A000000),
            ),
          ),
          Positioned(
            left: 20,
            top: 75,
            child: Text(
              items,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0x9E000000),
              ),
            ),
          ),
          for (int i = 0; i < thumbs; i++)
            Positioned(
              left: 20.0 + i * 52.0,
              top: 98,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF7BAE5A),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(color: const Color(0x12000000)),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          if (extra.isNotEmpty)
            Positioned(
              left: 20.0 + thumbs * 52.0,
              top: 98,
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.filterBg,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                  extra,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCard,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            top: 105,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Total Order',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0x59000000),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

class _OrderStatusPill extends StatelessWidget {
  const _OrderStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color dot;
    switch (status) {
      case 'Accepted':
        bg = AppColors.filterBg;
        dot = AppColors.primary;
      case 'Pending':
        bg = AppColors.outOfStockBg;
        dot = AppColors.attentionRed;
      case 'Confirmed':
        bg = Color(0xFFE1EFFA);
        dot = Color(0xFF1A73E8);
      default:
        bg = Colors.white;
        dot = AppColors.tabGray;
    }
    return Container(
      width: 73,
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
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
              status,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
