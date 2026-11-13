import 'package:flutter/material.dart';

import '../data/seller_profile_store.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';
import '../widgets/slide_drag_detector.dart';

/// Order Details — static replica of Zeplin "Android Compact - 135"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae16aa9fda71b12bf121).
///
/// Built against a 412x1567 artboard: fit width, scroll vertically for the
/// tall content. Slide-to-accept hands over to [OrderPickupCodeScreen];
/// "Reject order" asks for confirmation and pops back to My Orders.
class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

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
              Positioned(
                left: 0,
                top: 73,
                child: PageHeader(
                  title: AppStrings.trOf(context, 'Order Details'),
                ),
              ),
              Positioned(left: 22, top: 117, child: const _SegmentTabs()),
              Positioned(left: 25, top: 172, child: const _OrderHero()),
              Positioned(left: 22, top: 394, child: const _BuyerCard()),
              Positioned(left: 22, top: 588, child: const _ItemsCard()),
              Positioned(left: 22, top: 862, child: const _SummaryCard()),
              Positioned(left: 22, top: 1082, child: const _DeliveryCard()),
              Positioned(
                left: 21,
                top: 1424,
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
              Positioned(left: 21, top: 1494, child: const _SlideAccept()),
            ],
          ),
        ),
      ),
    );
  }
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
  const _SegmentTabs();

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
        ],
      ),
    );
  }
}

class _OrderHero extends StatelessWidget {
  const _OrderHero();

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
              AppStrings.trOf(context, 'ORDER #NX4582'),
              AppTextStyles.orderId,
              width: 107,
              height: 15,
            ),
          ),
          Positioned(
            left: 16,
            top: 32,
            child: _Label(
              AppStrings.trOf(context, 'New Order'),
              AppTextStyles.orderHeroTitle,
              width: 149,
              height: 34,
            ),
          ),
          Positioned(
            left: 16,
            top: 67,
            child: _Label(
              AppStrings.trOf(context, 'Waiting for your response'),
              AppTextStyles.orderHeroCaption,
              width: 126,
              height: 13,
            ),
          ),
          const Positioned(
            left: 16,
            top: 90,
            child: _Label(
              '12 Mar 2024, 10:24 AM',
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
              AppStrings.trOf(context, 'Active'),
              AppTextStyles.orderPillLabel.copyWith(
                color: AppColors.orderDivider,
              ),
              width: 34,
              height: 20,
            ),
          ),
          const Positioned(left: 17, top: 118, child: _ProgressStrip()),
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
  const _ProgressStrip();

  static const List<_Step> steps = [
    _Step('Active', _StepIcon.bolt, true, 38),
    _Step('Pickup', _StepIcon.download, false, 146),
    _Step('Completed', _StepIcon.flag, false, 256),
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
              child: _StepCircle(step: steps[i]),
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
                    color: steps[i].active
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
  const _Step(this.label, this.icon, this.active, this.left);

  final String label;
  final _StepIcon icon;
  final bool active;
  final double left;
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final Widget icon;
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
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: step.active ? AppColors.orderDark : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: step.active
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
  const _BuyerCard();

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
          const Positioned(
            left: 95,
            top: 44,
            child: _Label(
              'Akash Stores',
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
              SellerProfileStore.instance.locationDisplay,
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
          const Positioned(
            left: 109,
            top: 95,
            child: _Label(
              '+91 12345 67890',
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
              AppStrings.trOf(context, 'Retailer'),
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
                    left: 74,
                    top: 11,
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
                    left: 52,
                    top: 13,
                    child: Image(
                      image: AssetImage('assets/order/ic_message.png'),
                      width: 14,
                      height: 14,
                    ),
                  ),
                  Positioned(
                    left: 72,
                    top: 11,
                    child: _Label(
                      AppStrings.trOf(context, 'Message'),
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.12,
                        color: Colors.white,
                      ),
                      width: 56,
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

class _ItemsCard extends StatelessWidget {
  const _ItemsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 260,
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
          const Positioned(
            left: 16,
            top: 58,
            child: _ItemRow(
              image: 'assets/order/tomatoes.png',
              name: 'Fresh Tomatoes',
              qty: '50 kg',
              rate: '\u20B924/kg',
              price: '\u20B91,400',
            ),
          ),
          const Positioned(
            left: 16,
            top: 121,
            child: _ItemRow(
              image: 'assets/order/chillies.png',
              name: 'Green Chillies',
              qty: '30 kg',
              rate: '\u20B940/kg',
              price: '\u20B91,200',
            ),
          ),
          const Positioned(
            left: 16,
            top: 184,
            child: _ItemRow(
              image: 'assets/order/chillies2.png',
              name: 'Green Chillies',
              qty: '20 kg',
              rate: '\u20B922/kg',
              price: '\u20B9440',
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
  const _SummaryCard();

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
            const Positioned(
              left: 287,
              top: 76,
              child: _Label(
                '\u20B92,840',
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
            const Positioned(
              left: 318,
              top: 104,
              child: _Label('\u20B90', AppTextStyles.orderRowValue, width: 30),
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
            const Positioned(
              left: 264,
              top: 148,
              child: _Label(
                '\u20B92,840',
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
  const _DeliveryCard();

  @override
  Widget build(BuildContext context) {
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
                      AppStrings.trOf(context, 'Buyer Pickup'),
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
                          'Buyer will pick up the order  from your\nlocation',
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
                  const Positioned(
                    left: 63,
                    top: 86,
                    child: _Label(
                      '25 Mar 2024',
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
                        AppStrings.trOf(context, 'Please ensure fresh quality and proper\npacking. Call me before ready for pickup.'),
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
