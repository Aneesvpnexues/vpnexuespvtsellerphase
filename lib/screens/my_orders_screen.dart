import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';
import 'order_details_screen.dart';

/// My Orders list — replica of Zeplin
/// "Android Compact - 132" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae17402fbd4010868423).
///
/// Built against a 412x1154 artboard. Same zoom-scroll pattern as 117/123:
/// fit width, scroll vertically. The status tabs filter the order list and
/// the Sort by control opens an ordering sheet.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1154;
  static const double trimTop = 49;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  _OrderFilter _filter = _OrderFilter.all;
  _OrderSort _sort = _OrderSort.newest;

  List<_Order> get _visibleOrders {
    final indexed = <(int, _Order)>[
      for (final (index, order) in _orders.indexed)
        if (_filter.matches(order)) (index, order),
    ];
    indexed.sort((a, b) {
      final comparison = switch (_sort) {
        _OrderSort.newest => b.$2.recency.compareTo(a.$2.recency),
        _OrderSort.oldest => a.$2.recency.compareTo(b.$2.recency),
        _OrderSort.priceHigh => b.$2.amount.compareTo(a.$2.amount),
        _OrderSort.priceLow => a.$2.amount.compareTo(b.$2.amount),
      };
      return comparison == 0 ? a.$1.compareTo(b.$1) : comparison;
    });
    return [for (final (_, order) in indexed) order];
  }

  void _selectFilter(_OrderFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
  }

  Future<void> _showSortOptions() async {
    final selected = await showModalBottomSheet<_OrderSort>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SortSheet(selected: _sort),
    );
    if (selected != null && mounted) {
      setState(() => _sort = selected);
    }
  }

  void _openOrder() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.orderDetails),
        builder: (_) => const OrderDetailsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _visibleOrders;
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: DesignCanvas(
                designWidth: MyOrdersScreen.designWidth,
                designHeight: MyOrdersScreen.designHeight,
                trimTop: MyOrdersScreen.trimTop,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 73,
                      child: PageHeader(
                        title: 'My Orders',
                        backButtonKey: const ValueKey<String>('my-orders-back'),
                        titleKey: const ValueKey<String>('my-orders-title'),
                        onBack: () => goToHome(context),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 122,
                      child: _SearchSort(onSortTap: _showSortOptions),
                    ),
                    Positioned(
                      left: 24,
                      top: 181,
                      child: _OrderTabs(
                        selected: _filter,
                        onSelected: _selectFilter,
                      ),
                    ),
                    for (var i = 0; i < orders.length; i++)
                      Positioned(
                        left: 24,
                        top: 241 + i * 166.0,
                        child: _OrderBlock(
                          store: orders[i].store,
                          orderId: orders[i].orderId,
                          date: orders[i].date,
                          iconBg: orders[i].iconBg,
                          iconColor: orders[i].iconColor,
                          items: orders[i].items,
                          thumbImages: orders[i].thumbImages,
                          extra: orders[i].extra,
                          price: orders[i].price,
                          status: orders[i].status,
                          onTap: _openOrder,
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

/// One order in the list. [recency] is the order number used by the
/// newest/oldest sorting and [amount] is the numeric total for price sorting.
class _Order {
  const _Order({
    required this.store,
    required this.orderId,
    required this.date,
    required this.recency,
    required this.iconBg,
    this.iconColor = const Color(0xFF5A4A1A),
    required this.items,
    required this.thumbImages,
    required this.extra,
    required this.price,
    required this.amount,
    required this.status,
  });

  final String store;
  final String orderId;
  final String date;
  final int recency;
  final Color iconBg;
  final Color iconColor;
  final String items;
  final List<String> thumbImages;
  final String extra;
  final String price;
  final int amount;
  final String status;
}

const _orders = <_Order>[
  _Order(
    store: 'Akash Stores',
    orderId: '#NX4582',
    date: '12 Mar 2024, 10:30 AM',
    recency: 4582,
    iconBg: AppColors.orderYellowBg,
    items: '4 items',
    thumbImages: [
      'assets/order/tomatoes.png',
      'assets/order/chillies.png',
      'assets/order/chillies2.png',
    ],
    extra: '+1',
    price: '\u20B92,400',
    amount: 2400,
    status: 'Accepted',
  ),
  _Order(
    store: 'Hotel Green Leaf',
    orderId: '#NX4581',
    date: '12 Mar 2024, 4:20 AM',
    recency: 4581,
    iconBg: AppColors.orderBlueBg,
    items: '2 items',
    thumbImages: [
      'assets/order/tomatoes.png',
      'assets/order/chillies.png',
    ],
    extra: '',
    price: '\u20B91,400',
    amount: 1400,
    status: 'Accepted',
  ),
  _Order(
    store: 'Annapoorna Mess',
    orderId: '#NX4580',
    date: '9 Mar 2024, 1:20 PM',
    recency: 4580,
    iconBg: AppColors.darkCard,
    iconColor: Colors.white,
    items: '5 items',
    thumbImages: [
      'assets/order/tomatoes.png',
      'assets/order/chillies.png',
      'assets/order/chillies2.png',
    ],
    extra: '+2',
    price: '\u20B93,400',
    amount: 3400,
    status: 'Pending',
  ),
  _Order(
    store: 'Daily Needs',
    orderId: '#NX4579',
    date: '12 Mar 2024, 4:20 AM',
    recency: 4579,
    iconBg: AppColors.attentionRedBg,
    items: '4 items',
    thumbImages: [
      'assets/order/tomatoes.png',
      'assets/order/chillies.png',
      'assets/order/chillies2.png',
    ],
    extra: '+1',
    price: '\u20B93,000',
    amount: 3000,
    status: 'Confirmed',
  ),
  _Order(
    store: 'Daily Needs',
    orderId: '#NX4579',
    date: '12 Mar 2024, 4:20 AM',
    recency: 4579,
    iconBg: AppColors.orderPurpleBg,
    items: '3 items',
    thumbImages: [
      'assets/order/tomatoes.png',
      'assets/order/chillies.png',
      'assets/order/chillies2.png',
    ],
    extra: '',
    price: '\u20B93,500',
    amount: 3500,
    status: 'Delivered',
  ),
];

enum _OrderFilter {
  all('All'),
  active('Active'),
  pending('Pending'),
  confirmed('Confirmed');

  const _OrderFilter(this.label);

  final String label;

  bool matches(_Order order) => switch (this) {
    _OrderFilter.all => true,
    _OrderFilter.active => order.status == 'Accepted',
    _OrderFilter.pending => order.status == 'Pending',
    _OrderFilter.confirmed => order.status == 'Confirmed',
  };
}

enum _OrderSort {
  newest('Newest first', Icons.south),
  oldest('Oldest first', Icons.north),
  priceHigh('Price: high to low', Icons.trending_down),
  priceLow('Price: low to high', Icons.trending_up);

  const _OrderSort(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _SearchSort extends StatelessWidget {
  const _SearchSort({required this.onSortTap});

  final VoidCallback onSortTap;

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
            child: GestureDetector(
              key: const ValueKey('order-sort-button'),
              behavior: HitTestBehavior.opaque,
              onTap: onSortTap,
              child: HoverPress.button(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTabs extends StatelessWidget {
  const _OrderTabs({required this.selected, required this.onSelected});

  final _OrderFilter selected;
  final ValueChanged<_OrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final double pillLeft = switch (selected) {
      _OrderFilter.all => 4,
      _OrderFilter.active => 112,
      _OrderFilter.pending => 184,
      _OrderFilter.confirmed => 264,
    };
    final double pillWidth = switch (selected) {
      _OrderFilter.all => 99,
      _OrderFilter.active => 60,
      _OrderFilter.pending => 81,
      _OrderFilter.confirmed => 100,
    };
    TextStyle styleFor(_OrderFilter filter) => TextStyle(
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
              key: const ValueKey('order-filter-all'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(_OrderFilter.all),
              child: HoverPress.chip(
                child: Center(
                  child: Text(
                    _OrderFilter.all.label,
                    style: styleFor(_OrderFilter.all),
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
              key: const ValueKey('order-filter-active'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(_OrderFilter.active),
              child: HoverPress.chip(
                child: Center(
                  child: Text(
                    _OrderFilter.active.label,
                    style: styleFor(_OrderFilter.active),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 188,
            top: 0,
            width: 88,
            height: 45,
            child: GestureDetector(
              key: const ValueKey('order-filter-pending'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(_OrderFilter.pending),
              child: HoverPress.chip(
                child: Center(
                  child: Text(
                    _OrderFilter.pending.label,
                    style: styleFor(_OrderFilter.pending),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 276,
            top: 0,
            width: 88,
            height: 45,
            child: GestureDetector(
              key: const ValueKey('order-filter-confirmed'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(_OrderFilter.confirmed),
              child: HoverPress.chip(
                child: Center(
                  child: Text(
                    _OrderFilter.confirmed.label,
                    style: styleFor(_OrderFilter.confirmed),
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

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.selected});

  final _OrderSort selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.fieldBorder,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('order-sort-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const HoverPress.icon(
                    child: Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final option in _OrderSort.values)
              InkWell(
                key: ValueKey('order-sort-${option.name}'),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                onTap: () => Navigator.of(context).pop(option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.icon,
                        size: 18,
                        color: option == selected
                            ? AppColors.darkCard
                            : AppColors.tabGray,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: option == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: option == selected
                                ? AppColors.darkCard
                                : AppColors.tabGray,
                          ),
                        ),
                      ),
                      if (option == selected)
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
    required this.thumbImages,
    required this.extra,
    required this.price,
    required this.status,
    required this.onTap,
  });

  final String store;
  final String orderId;
  final String date;
  final Color iconBg;
  final Color iconColor;
  final String items;
  final List<String> thumbImages;
  final String extra;
  final String price;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
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
            for (int i = 0; i < thumbImages.length; i++)
              Positioned(
                left: 20.0 + i * 52.0,
                top: 98,
                child: Container(
                  width: 46,
                  height: 46,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7BAE5A),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    border: Border.all(color: const Color(0x12000000)),
                  ),
                  child: Image.asset(
                    thumbImages[i],
                    key: ValueKey<String>('order-thumb-$i'),
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.eco_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (extra.isNotEmpty)
              Positioned(
                left: 20.0 + thumbImages.length * 52.0,
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
      ),
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
