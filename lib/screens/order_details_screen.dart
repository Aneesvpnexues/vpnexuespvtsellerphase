import 'package:flutter/material.dart';

import '../data/order_store.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';
import '../widgets/slide_drag_detector.dart';

/// Order Details — replica of Zeplin "Android Compact - 135"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae16aa9fda71b12bf121).
///
/// Built against a 412x1567 artboard: fit width, scroll vertically for the
/// tall content. Slide-to-accept hands over to [OrderPickupCodeScreen];
/// "Reject order" asks for confirmation and pops back to My Orders.
///
/// Every section renders the [order] it is handed — order id, buyer
/// details, ordered products, quantities, totals, status and progress
/// stages — so opening a different row of My Orders always shows that
/// order's own summary instead of a fixed one (SELLER-020).
class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.order});

  /// The order this screen is showing.
  final OrderDetail order;

  static const double designWidth = 412;
  static const double designHeight = 1567;
  static const double trimTop = 49;

  Future<void> _confirmReject(BuildContext context) async {
    final bool? reject = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(AppStrings.trOf(dialogContext, 'Reject this order?')),
        content: Text(
          AppStrings.trOf(
            dialogContext,
            'The buyer will be notified that you declined this order.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.trOf(dialogContext, 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppStrings.trOf(dialogContext, 'Reject'),
              style: const TextStyle(color: AppColors.attentionRed),
            ),
          ),
        ],
      ),
    );
    if (reject == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The items card grows with the order's line count (see
    // [_ItemsCard.heightFor]); every card below it shifts by the same
    // delta and the artboard grows with it, so the design spacing — and
    // therefore scrolling — stays intact for 2-, 4- or 5-line orders.
    final double delta =
        _ItemsCard.heightFor(order.items.length) - _ItemsCard.designHeight;
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: designWidth,
          designHeight: designHeight + delta,
          trimTop: trimTop,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 73,
                child: PageHeader(
                  title: AppStrings.trOf(context, 'Order Details'),
                ),
              ),
              Positioned(
                left: 22,
                top: 117,
                child: _SegmentTabs(pickupType: order.pickupType),
              ),
              Positioned(left: 25, top: 172, child: _OrderHero(order: order)),
              Positioned(left: 22, top: 394, child: _BuyerCard(order: order)),
              Positioned(left: 22, top: 588, child: _ItemsCard(order: order)),
              Positioned(
                left: 22,
                top: 862 + delta,
                child: _SummaryCard(order: order),
              ),
              Positioned(
                left: 22,
                top: 1082 + delta,
                child: _DeliveryCard(order: order),
              ),
              Positioned(
                left: 21,
                top: 1424 + delta,
                width: 364,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _confirmReject(context),
              child: SizedBox(
                height: 16,
                child: Text(
                  AppStrings.trOf(context, 'Reject order'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.attentionRed,
                  ),
                ),
              ),
                ),
              ),
              Positioned(
                left: 21,
                top: 1494 + delta,
                child: const _SlideAccept(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order data shown by this screen
// ---------------------------------------------------------------------------

/// One product line of an order, exactly as the Order Items card lists it.
class OrderDetailItem {
  const OrderDetailItem({
    required this.image,
    required this.name,
    required this.quantity,
    required this.rate,
  });

  /// Thumbnail shown in the row (and in the My Orders list tile).
  final String image;
  final String name;

  /// Quantity in kilograms and rate in rupees per kilogram. The line total
  /// is derived from them so the Order Summary can never disagree with the
  /// items displayed above it.
  final int quantity;
  final int rate;

  int get total => quantity * rate;
  String get quantityLabel => '$quantity kg';
  String get rateLabel => '\u20B9$rate/kg';
  String get totalLabel => _rupees(total);
}

/// Everything the Order Details screen displays for one selected order:
/// identity, buyer, products, totals, status and progress stage.
class OrderDetail {
  const OrderDetail({
    required this.orderId,
    required this.date,
    required this.status,
    required this.pickupType,
    required this.buyerName,
    required this.buyerLocation,
    required this.buyerPhone,
    required this.buyerType,
    required this.items,
    required this.expectedPickupDate,
    required this.buyerNote,
    this.deliveryCharges = 0,
  });

  /// Order id including the leading '#', e.g. `#NX4582`.
  final String orderId;

  /// Placed-on timestamp shown in the hero card.
  final String date;

  final OrderStatus status;
  final PickupType pickupType;

  final String buyerName;
  final String buyerLocation;
  final String buyerPhone;
  final String buyerType;

  final List<OrderDetailItem> items;
  final String expectedPickupDate;
  final String buyerNote;

  /// Flat delivery fee in rupees (0 for buyer-pickup orders).
  final int deliveryCharges;

  int get itemsTotal =>
      items.fold(0, (int sum, OrderDetailItem item) => sum + item.total);
  int get totalAmount => itemsTotal + deliveryCharges;

  String get itemsTotalLabel => _rupees(itemsTotal);
  String get deliveryChargesLabel => _rupees(deliveryCharges);
  String get totalAmountLabel => _rupees(totalAmount);

  /// Hero headline / caption / pill / progress stage, all derived from the
  /// order's own status so the summary can never contradict the list.
  String get heroTitle => switch (status) {
    OrderStatus.pending => 'New Order',
    OrderStatus.accepted => 'Order Accepted',
    OrderStatus.confirmed => 'Order Confirmed',
    OrderStatus.delivered => 'Order Delivered',
    OrderStatus.rejected => 'Order Rejected',
  };

  String get heroCaption => switch (status) {
    OrderStatus.pending => 'Waiting for your response',
    OrderStatus.accepted => 'Ready for buyer pickup',
    OrderStatus.confirmed => 'Pickup scheduled',
    OrderStatus.delivered => 'Order completed',
    OrderStatus.rejected => 'Buyer notified',
  };

  /// Short label of the hero status pill.
  String get statusPillLabel => switch (status) {
    OrderStatus.delivered => 'Done',
    OrderStatus.rejected => 'Rejected',
    _ => 'Active',
  };

  /// Index of the current progress stage: 0 Active, 1 Pickup, 2 Completed.
  int get progressStage => switch (status) {
    OrderStatus.pending => 0,
    OrderStatus.accepted => 1,
    OrderStatus.confirmed => 1,
    OrderStatus.delivered => 2,
    OrderStatus.rejected => 0,
  };

  /// Design values used by the Zeplin QA preview (`main_order_preview.dart`).
  static const OrderDetail sample = OrderDetail(
    orderId: '#NX4582',
    date: '12 Mar 2024, 10:24 AM',
    status: OrderStatus.pending,
    pickupType: PickupType.buyerPickup,
    buyerName: 'Akash Stores',
    buyerLocation: 'Salem, Tamil Nadu',
    buyerPhone: '+91 12345 67890',
    buyerType: 'Retailer',
    items: <OrderDetailItem>[
      OrderDetailItem(
        image: 'assets/order/tomatoes.png',
        name: 'Fresh Tomatoes',
        quantity: 50,
        rate: 24,
      ),
      OrderDetailItem(
        image: 'assets/order/chillies.png',
        name: 'Green Chillies',
        quantity: 30,
        rate: 40,
      ),
      OrderDetailItem(
        image: 'assets/order/chillies2.png',
        name: 'Green Chillies',
        quantity: 20,
        rate: 22,
      ),
    ],
    expectedPickupDate: '25 Mar 2024',
    buyerNote:
        'Please ensure fresh quality and proper\npacking. Call me before ready for pickup.',
  );
}

/// Groups the last three digits so totals read like the design (`₹2,840`).
String _rupees(int value) {
  final String digits = value.toString();
  if (digits.length <= 3) return '\u20B9$digits';
  final int cut = digits.length - 3;
  return '\u20B9${digits.substring(0, cut)},${digits.substring(cut)}';
}

/// Small helper that places a text inside the exact Zeplin text box so the
/// glyphs sit at the same vertical offset as the design.
///
/// `height` is the line height Zeplin reports for the layer, so the style gets
/// an explicit `height` (box / font size) with even leading distribution to
/// reproduce the design's half-leading.
///
/// Zeplin boxes hug the text, so the Inter advance plus Flutter's trailing
/// letter spacing can be a hair wider than the box. Every label in the design
/// is single line, so wrapping is disabled instead of widening the box.
class _Label extends StatelessWidget {
  const _Label(this.text, this.style, {required this.width, this.height = 25});

  final String text;
  final TextStyle style;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double? fontSize = style.fontSize;
    final TextStyle effective = fontSize == null || fontSize == 0
        ? style
        : style.copyWith(
            height: height / fontSize,
            leadingDistribution: TextLeadingDistribution.even,
          );
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: effective, maxLines: 1, softWrap: false),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({required this.pickupType});

  /// The order's own fulfilment mode: the active half of the toggle and the
  /// delivery copy below follow it.
  final PickupType pickupType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 368,
      height: 45,
      child: Stack(
        children: [
          Container(
            width: 368,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              border: Border.all(color: const Color(0x14000000)),
            ),
          ),
          if (pickupType == PickupType.buyerPickup) ...[
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                width: 177,
                height: 37,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.orderDark,
                  borderRadius: BorderRadius.all(Radius.circular(23)),
                ),
                child: Text(
                  AppStrings.trOf(context, 'Buyer Pickup'),
                  style: AppTextStyles.orderSegmentActive,
                ),
              ),
            ),
            Positioned(
              left: 238,
              top: 10,
              child: _Label(
                AppStrings.trOf(context, 'Delivery'),
                AppTextStyles.orderSegmentIdle,
                width: 50,
              ),
            ),
          ] else ...[
            Positioned(
              left: 187,
              top: 4,
              child: Container(
                width: 177,
                height: 37,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.orderDark,
                  borderRadius: BorderRadius.all(Radius.circular(23)),
                ),
                child: Text(
                  AppStrings.trOf(context, 'Delivery'),
                  style: AppTextStyles.orderSegmentActive,
                ),
              ),
            ),
            Positioned(
              left: 50,
              top: 10,
              child: _Label(
                AppStrings.trOf(context, 'Buyer Pickup'),
                AppTextStyles.orderSegmentIdle,
                width: 92,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderHero extends StatelessWidget {
  const _OrderHero({required this.order});

  /// The selected order: its id, timestamp, status-derived headline and
  /// progress stage all come from here.
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 210,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFC9EA73),
            Color(0xFFC8EAA5),
          ],
        ),
        boxShadow: const [
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
            offset: Offset(0, 20),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: Stack(
        children: [
          Positioned(
            left: 238,
            top: -44,
            child: Container(
              width: 164,
              height: 164,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.orderCircleStart,
                    AppColors.orderCircleEnd,
                  ],
                ),
                border: Border.all(color: const Color(0x51FDF9F0)),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 12,
            child: _Label(
              AppStrings.trOf(context, 'ORDER ${order.orderId}'),
              AppTextStyles.orderId,
              width: 107,
              height: 15,
            ),
          ),
          Positioned(
            left: 16,
            top: 32,
            child: _Label(
              AppStrings.trOf(context, order.heroTitle),
              AppTextStyles.orderHeroTitle,
              width: 149,
              height: 34,
            ),
          ),
          Positioned(
            left: 16,
            top: 67,
            child: _Label(
              AppStrings.trOf(context, order.heroCaption),
              AppTextStyles.orderHeroCaption,
              width: 126,
              height: 13,
            ),
          ),
          Positioned(
            left: 16,
            top: 90,
            child: _Label(
              order.date,
              AppTextStyles.orderHeroMeta,
              width: 113,
              height: 13,
            ),
          ),
          Positioned(
            left: 284,
            top: 15,
            child: Container(
              width: 61,
              height: 19,
              decoration: const BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          const Positioned(
            left: 294,
            top: 22,
            child: _Dot(size: 5, color: AppColors.orderDivider),
          ),
          Positioned(
            left: 301.5,
            top: 15,
            child: _Label(
              AppStrings.trOf(context, order.statusPillLabel),
              AppTextStyles.orderPillLabel.copyWith(
                color: AppColors.orderDivider,
              ),
              width: 34,
              height: 20,
            ),
          ),
          Positioned(
            left: 17,
            top: 118,
            child: _ProgressStrip(stage: order.progressStage),
          ),
        ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.stage});

  /// Index of the order's current progress stage: 0 Active, 1 Pickup,
  /// 2 Completed. Stages up to and including it are shown as reached.
  final int stage;

  static const List<_Step> steps = [
    _Step('Active', _StepIcon.bolt, 38),
    _Step('Pickup', _StepIcon.download, 146),
    _Step('Completed', _StepIcon.flag, 256),
  ];

  static const List<double> centers = [56, 164, 274];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 332,
      height: 79,
      decoration: const BoxDecoration(
        color: AppColors.orderMint,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 74,
            top: 33,
            child: CustomPaint(size: Size(182, 1), painter: _DashedLine()),
          ),
          for (int i = 0; i < steps.length; i++)
            Positioned(
              left: steps[i].left,
              top: 16,
              child: _StepCircle(step: steps[i], active: i <= stage),
            ),
          for (int i = 0; i < steps.length; i++)
            Positioned(
              left: centers[i] - 30,
              top: 55,
              child: SizedBox(
                width: 60,
                height: 15,
                child: Text(
                  AppStrings.trOf(context, steps[i].label),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: i <= stage
                        ? AppColors.orderDark
                        : const Color(0x8C0D3B20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _StepIcon { bolt, download, flag }

class _Step {
  const _Step(this.label, this.icon, this.left);

  final String label;
  final _StepIcon icon;
  final double left;
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.step, required this.active});

  final _Step step;

  /// Whether the order has reached (or passed) this stage: reached circles
  /// are dark with a glyph that stays legible on that background (the lime
  /// bolt for the first stage, a white tick afterwards), while the stages
  /// still ahead keep the design's light-grey icon on a white circle.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Widget icon;
    if (active && step.icon != _StepIcon.bolt) {
      icon = Image.asset(
        'assets/order/ic_step_tick_white.png',
        width: 16,
        height: 16,
      );
    } else {
      switch (step.icon) {
        case _StepIcon.bolt:
          icon = CustomPaint(
            size: const Size(15, 19),
            painter: _BoltPainter(color: AppColors.orderLime),
          );
        case _StepIcon.download:
          icon = Image.asset(
            'assets/order/ic_step_download.png',
            width: 18,
            height: 18,
          );
        case _StepIcon.flag:
          icon = Image.asset(
            'assets/order/ic_step_flag.png',
            width: 16,
            height: 16,
          );
      }
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.orderDark : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? const Color(0xFFE1F8A4)
              : const Color(0xFFE9E9E9),
          width: 2,
        ),
      ),
      child: icon,
    );
  }
}

class _BoltPainter extends CustomPainter {
  const _BoltPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(w * 0.58, h * 0.05)
      ..lineTo(w * 0.27, h * 0.57)
      ..lineTo(w * 0.55, h * 0.57)
      ..lineTo(w * 0.45, h * 0.95)
      ..lineTo(w * 0.84, h * 0.4)
      ..lineTo(w * 0.55, h * 0.4)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedLine extends CustomPainter {
  const _DashedLine();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.orderDivider
      ..strokeWidth = 1;
    const double dash = 5;
    const double gap = 5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BuyerCard extends StatelessWidget {
  const _BuyerCard({required this.order});

  /// The selected order's buyer: name, location, phone and buyer type.
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 181,
      decoration: BoxDecoration(
        color: AppColors.orderCardDark,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: const [
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
            offset: Offset(0, 12),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0x03000000),
            offset: Offset(0, 21),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 17,
            top: 15,
            child: _Label(
              AppStrings.trOf(context, 'BUYER DETAILS'),
              AppTextStyles.orderSectionLabel,
              width: 102,
              height: 15,
            ),
          ),
          Positioned(
            left: 17,
            top: 44,
            child: Container(
              alignment: Alignment.center,
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.orderAvatar,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Image(
                image: AssetImage('assets/order/ic_shop.png'),
                width: 30,
                height: 30,
              ),
            ),
          ),
          Positioned(
            left: 95,
            top: 44,
            child: _Label(
              order.buyerName,
              AppTextStyles.orderStoreName,
              width: 133,
            ),
          ),
          const Positioned(
            left: 94,
            top: 77,
            child: Image(
              image: AssetImage('assets/order/ic_location.png'),
              width: 9,
              height: 9,
            ),
          ),
          Positioned(
            left: 109,
            top: 75,
            child: _Label(
              order.buyerLocation,
              AppTextStyles.orderMuted,
              width: 90,
              height: 13,
            ),
          ),
          const Positioned(
            left: 95,
            top: 96,
            child: Image(
              image: AssetImage('assets/order/ic_phone_sm.png'),
              width: 9,
              height: 12,
            ),
          ),
          Positioned(
            left: 109,
            top: 95,
            child: _Label(
              order.buyerPhone,
              AppTextStyles.orderMuted,
              width: 86,
              height: 13,
            ),
          ),
          Positioned(
            left: 241,
            top: 48,
            child: Container(
              width: 61,
              height: 19,
              decoration: const BoxDecoration(
                color: AppColors.orderLime,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          Positioned(
            left: 253,
            top: 45,
            child: _Label(
              AppStrings.trOf(context, order.buyerType),
              AppTextStyles.orderBuyerType,
              width: 49,
              height: 20,
            ),
          ),
          Positioned(
            left: 18,
            top: 122,
            child: Container(
              alignment: Alignment.center,
              width: 162,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orderLime,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 58,
                    top: 14,
                    child: Image(
                      image: AssetImage('assets/order/ic_phone.png'),
                      width: 10,
                      height: 12,
                    ),
                  ),
                  Positioned(
                    left: 77,
                    top: 7,
                    child: _Label(
                      AppStrings.trOf(context, 'Call'),
                      AppTextStyles.orderCallLabel,
                      width: 27,
                      height: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 188,
            top: 122,
            child: Container(
              alignment: Alignment.center,
              width: 162,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orderSecondary,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 56,
                    top: 13,
                    child: Image(
                      image: AssetImage('assets/order/ic_message.png'),
                      width: 14,
                      height: 14,
                    ),
                  ),
                  Positioned(
                    left: 79,
                    top: 7,
                    child: _Label(
                      AppStrings.trOf(context, 'Call'),
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.12,
                        color: Colors.white,
                      ),
                      width: 27,
                      height: 17,
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

/// Order Items card: lists the selected order's own products and
/// quantities. Its height grows with the line count ([heightFor]); the
/// Order Details layout shifts everything below by the same delta.
class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final OrderDetail order;

  /// Height of the card in the design for three rows (the reference the
  /// artboard offsets below are measured from).
  static const double designHeight = 260;

  /// Card height for [itemCount] rows: first row at y=58, rows pitched 63
  /// apart, 17px bottom padding (58 + 59 + 63*(n-1) + 17 = 71 + 63n).
  static double heightFor(int itemCount) => 71.0 + 63 * itemCount;

  @override
  Widget build(BuildContext context) {
    final List<OrderDetailItem> items = order.items;
    return Container(
      width: 368,
      height: heightFor(items.length),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A9E9E9E),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x179E9E9E),
            offset: Offset(0, 7),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0x0D9E9E9E),
            offset: Offset(0, 16),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0x039E9E9E),
            offset: Offset(0, 29),
            blurRadius: 11,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 17,
            top: 17,
            child: Container(
              alignment: Alignment.center,
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.orderTile,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Image(
                image: AssetImage('assets/order/ic_tile_box.png'),
                width: 18,
                height: 18,
              ),
            ),
          ),
          Positioned(
            left: 56,
            top: 19,
            child: _Label(
              AppStrings.trOf(context, 'Order Items'),
              AppTextStyles.orderCardTitle,
              width: 98,
            ),
          ),
          for (int i = 0; i < items.length; i++)
            Positioned(
              left: 16,
              top: 58 + i * 63.0,
              child: _ItemRow(
                image: items[i].image,
                name: items[i].name,
                qty: items[i].quantityLabel,
                rate: items[i].rateLabel,
                price: items[i].totalLabel,
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.image,
    required this.name,
    required this.qty,
    required this.rate,
    required this.price,
  });

  final String image;
  final String name;
  final String qty;
  final String rate;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 331,
      height: 59,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 5,
            top: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Image(image: AssetImage(image), width: 49, height: 49),
            ),
          ),
          Positioned(
            left: 67,
            top: 8,
            child: _Label(name, AppTextStyles.orderItemName, width: 120),
          ),
          Positioned(
            left: 67,
            top: 26,
            child: _Label(qty, AppTextStyles.orderItemMeta, width: 60),
          ),
          Positioned(
            left: 206,
            top: 18,
            child: _Label(rate, AppTextStyles.orderItemMeta, width: 58),
          ),
          Positioned(
            left: 264,
            top: 19,
            child: _Label(price, AppTextStyles.orderItemPrice, width: 60),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});

  /// The selected order's own totals: items total, delivery charges and
  /// grand total (derived from its item lines, so they always add up).
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 206,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A9E9E9E),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x179E9E9E),
            offset: Offset(0, 7),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0x0D9E9E9E),
            offset: Offset(0, 16),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0x039E9E9E),
            offset: Offset(0, 29),
            blurRadius: 11,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Stack(
          children: [
            Positioned(
              left: 17,
              top: 17,
              child: Container(
                alignment: Alignment.center,
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.orderTile,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: const Image(
                  image: AssetImage('assets/order/ic_tile_box2.png'),
                  width: 18,
                  height: 18,
                ),
              ),
            ),
            Positioned(
              left: 56,
              top: 19,
              child: _Label(
                AppStrings.trOf(context, 'Order Summary'),
                AppTextStyles.orderCardTitle,
                width: 128,
              ),
            ),
            Positioned(
              left: 16,
              top: 64,
              child: Container(
                width: 330,
                height: 72,
                color: AppColors.orderPale,
              ),
            ),
            Positioned(
              left: 32,
              top: 76,
              child: _Label(
                AppStrings.trOf(context, 'Items Total'),
                AppTextStyles.orderRowLabel,
                width: 120,
              ),
            ),
            Positioned(
              left: 287,
              top: 76,
              child: _Label(
                order.itemsTotalLabel,
                AppTextStyles.orderRowValue,
                width: 65,
              ),
            ),
            Positioned(
              left: 32,
              top: 105,
              child: _Label(
                AppStrings.trOf(context, 'Delivery Charges'),
                AppTextStyles.orderRowLabel,
                width: 140,
              ),
            ),
            Positioned(
              left: 318,
              top: 104,
              child: _Label(
                order.deliveryChargesLabel,
                AppTextStyles.orderRowValue,
                width: 30,
              ),
            ),
            Positioned(
              left: 16,
              top: 136,
              child: Container(
                width: 330,
                height: 51,
                color: AppColors.orderBand,
              ),
            ),
            Positioned(
              left: 32,
              top: 148,
              child: _Label(
                AppStrings.trOf(context, 'Total Amount'),
                AppTextStyles.orderTotalLabel,
                width: 120,
              ),
            ),
            Positioned(
              left: 264,
              top: 148,
              child: _Label(
                order.totalAmountLabel,
                AppTextStyles.orderTotalValue,
                width: 84,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  /// The selected order's fulfilment mode, expected pickup date and the
  /// buyer's note.
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final bool isDelivery = order.pickupType == PickupType.delivery;
    return Container(
      width: 368,
      height: 324,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A9E9E9E),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x179E9E9E),
            offset: Offset(0, 7),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0x0D9E9E9E),
            offset: Offset(0, 16),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0x039E9E9E),
            offset: Offset(0, 29),
            blurRadius: 11,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 17,
            top: 17,
            child: Container(
              alignment: Alignment.center,
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.orderTile,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Image(
                image: AssetImage('assets/order/ic_tile_truck.png'),
                width: 16,
                height: 16,
              ),
            ),
          ),
          Positioned(
            left: 56,
            top: 19,
            child: _Label(
              AppStrings.trOf(context, 'Delivery Details'),
              AppTextStyles.orderCardTitle,
              width: 128,
            ),
          ),
          Positioned(
            left: 16,
            top: 64,
            child: Container(
              width: 330,
              height: 123,
              decoration: const BoxDecoration(
                color: AppColors.orderPale,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 16,
                    top: 13,
                    child: Container(
                      alignment: Alignment.center,
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0C8),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Image(
                        image: AssetImage('assets/order/ic_box.png'),
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 63,
                    top: 5,
                    child: _Label(
                      AppStrings.trOf(
                        context,
                        isDelivery ? 'Home Delivery' : 'Buyer Pickup',
                      ),
                      AppTextStyles.orderSubTitle,
                      width: 140,
                    ),
                  ),
                  Positioned(
                    left: 63,
                    top: 26,
                    child: SizedBox(
                      width: 221,
                      height: 30,
                      child: Text(
                        AppStrings.trOf(
                          context,
                          isDelivery
                              ? 'Delivery partner will drop the order at\nyour delivery address'
                              : 'Buyer will pick up the order  from your\nlocation',
                        ),
                        style: AppTextStyles.orderSubText,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 71,
                    child: Container(
                      alignment: Alignment.center,
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Image(
                        image: AssetImage('assets/order/ic_calendar.png'),
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 63,
                    top: 69,
                    child: _Label(
                      AppStrings.trOf(context, 'Expected Pickup Date'),
                      AppTextStyles.orderSubText,
                      width: 160,
                    ),
                  ),
                  Positioned(
                    left: 63,
                    top: 86,
                    child: _Label(
                      order.expectedPickupDate,
                      AppTextStyles.orderDate,
                      width: 100,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 17,
            top: 204,
            child: Container(
              alignment: Alignment.center,
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.orderTile,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Image(
                image: AssetImage('assets/order/ic_tile_notes.png'),
                width: 16,
                height: 16,
              ),
            ),
          ),
          Positioned(
            left: 56,
            top: 205,
            child: _Label(
              AppStrings.trOf(context, 'Buyer Note'),
              AppTextStyles.orderCardTitle,
              width: 90,
            ),
          ),
          Positioned(
            left: 16,
            top: 243,
            child: Container(
              width: 330,
              height: 61,
              decoration: const BoxDecoration(
                color: AppColors.orderNoteBg,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 13,
                    top: 11,
                    child: Container(
                      alignment: Alignment.center,
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.orderNoteTile,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Image(
                        image: AssetImage('assets/order/ic_notes.png'),
                        width: 21,
                        height: 21,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 63,
                    top: 13,
                    child: SizedBox(
                      width: 256,
                      height: 34,
                      child: Text(
                        AppStrings.trOf(context, order.buyerNote),
                        style: AppTextStyles.orderNoteText,
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

class _SlideAccept extends StatefulWidget {
  const _SlideAccept();

  @override
  State<_SlideAccept> createState() => _SlideAcceptState();
}

class _SlideAcceptState extends State<_SlideAccept>
    with SingleTickerProviderStateMixin {
  static const double _start = 4;
  static const double _end = 310;
  static const double _travel = _end - _start;
  static const double _threshold = _start + _travel * 0.3;

  late final AnimationController _controller;
  double _knobX = _start;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          setState(() {
            _knobX = _start + _travel * _controller.value;
          });
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _controller.stop();
    setState(() {
      _knobX = (_knobX + details.delta.dx).clamp(_start, _end);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_knobX >= _threshold || details.velocity.pixelsPerSecond.dx > 300) {
      setState(() => _knobX = _end);
      goToOrderPickupCode(context);
      return;
    }
    _controller.value = ((_knobX - _start) / _travel).clamp(0.0, 1.0);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return HoverPress.slide(
      child: SlideDragDetector(
        onTap: () => goToOrderPickupCode(context),
        onUpdate: _onDragUpdate,
        onEnd: _onDragEnd,
        child: Container(
          width: 364,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(28)),
            gradient: const LinearGradient(
              colors: [AppColors.orderSlideStart, AppColors.orderSlideEnd],
            ),
            border: Border.all(color: const Color(0x14000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 10),
                blurRadius: 22,
              ),
              BoxShadow(
                color: Color(0x17000000),
                offset: Offset(0, 40),
                blurRadius: 40,
              ),
              BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(0, 90),
                blurRadius: 54,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: _knobX,
                top: 4,
                child: Container(
                  alignment: Alignment.center,
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.orderSlideLime,
                    shape: BoxShape.circle,
                  ),
                  child: const Image(
                    image: AssetImage('assets/order/ic_slide.png'),
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
              Positioned(
                left: 112,
                top: 15,
                child: _Label(
                  AppStrings.trOf(context, 'Slide to accept order'),
                  AppTextStyles.orderSlideLabel,
                  width: 180,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
