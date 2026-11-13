import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';
import '../widgets/slide_drag_detector.dart';

/// Order pickup code entry — replica of Zeplin "Android Compact - 141"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae10ae8ab8b653609477).
///
/// Built against a 412x1098 artboard. The four code boxes accept the demo
/// code shared by every order and user: [demoCode]. When the entered code
/// does not match, the boxes turn red, show an error line and clear; the
/// slide CTA stays locked until four digits are present. A valid code hands
/// over to the confirmation screen.
class OrderPickupCodeScreen extends StatefulWidget {
  const OrderPickupCodeScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1098;
  static const double trimTop = 49;

  /// Universal demo pickup code (no backend yet).
  static const String demoCode = '4582';

  @override
  State<OrderPickupCodeScreen> createState() => _OrderPickupCodeScreenState();
}

class _OrderPickupCodeScreenState extends State<OrderPickupCodeScreen> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  bool _error = false;

  bool get _complete => _code.text.length == 4;

  @override
  void initState() {
    super.initState();
    _code.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_error && _code.text.isNotEmpty) {
      setState(() => _error = false);
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _code.removeListener(_onCodeChanged);
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  bool _submit() {
    if (!_complete) return false;
    if (_code.text == OrderPickupCodeScreen.demoCode) {
      goToOrderConfirmation(
        context,
        amount: 2840,
        itemsCount: 3,
        orderId: '#NX4582',
        dateTime: DateTime.now(),
      );
      return true;
    }
    _code.clear();
    setState(() => _error = true);
    _codeFocus.requestFocus();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: OrderPickupCodeScreen.designWidth,
          designHeight: OrderPickupCodeScreen.designHeight,
          trimTop: OrderPickupCodeScreen.trimTop,
          child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 73,
                  child: PageHeader(
                    title: AppStrings.trOf(context, 'Order Details'),
                  ),
                ),
                const Positioned(left: 22, top: 117, child: _SegmentTabs()),
                const Positioned(left: 25, top: 172, child: _HeroCard()),
                const Positioned(left: 22, top: 358, child: _BuyerCard()),
                const Positioned(left: 22, top: 552, child: _DeliveryCard()),
                Positioned(
                  left: 22,
                  top: 733,
                  child: _CodeCard(
                    controller: _code,
                    focusNode: _codeFocus,
                    error: _error,
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 1017,
                  child: _SlideConfirm(locked: !_complete, onSubmit: _submit),
                ),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 172,
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
      child: Stack(
        children: [
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
            top: 30,
            child: _Label(
              AppStrings.trOf(context, 'Ready for Pickup'),
              AppTextStyles.orderHeroTitle,
              width: 240,
              height: 34,
            ),
          ),
          Positioned(
            left: 246,
            top: 11,
            child: Container(
              width: 100,
              height: 19,
              decoration: const BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          const Positioned(
            left: 255,
            top: 18,
            child: _Dot(size: 5, color: AppColors.orderDivider),
          ),
          Positioned(
            left: 265.5,
            top: 10.5,
            child: _Label(
              AppStrings.trOf(context, 'Out for delivery'),
              AppTextStyles.orderPillLabel.copyWith(
                color: AppColors.orderDivider,
              ),
              width: 74,
              height: 20,
            ),
          ),
          const Positioned(left: 15, top: 82, child: _ProgressStrip()),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip();

  static const List<_Step> steps = [
    _Step('Active', _StepIcon.bolt, false, 38),
    _Step('Pickup', _StepIcon.download, true, 146),
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
          painter: _BoltPainter(
            color: step.active ? AppColors.orderLime : const Color(0xFFABABAB),
          ),
        );
      case _StepIcon.download:
        icon = step.active
            ? const CustomPaint(
                size: Size(16, 16),
                painter: _DownloadPainter(color: AppColors.orderLime),
              )
            : Image.asset(
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

class _DownloadPainter extends CustomPainter {
  const _DownloadPainter({required this.color});

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
    canvas.drawLine(Offset(w * 0.5, h * 0.12), Offset(w * 0.5, h * 0.52), paint);
    final Path chevron = Path()
      ..moveTo(w * 0.24, h * 0.3)
      ..lineTo(w * 0.5, h * 0.54)
      ..lineTo(w * 0.76, h * 0.3);
    canvas.drawPath(chevron, paint);
    canvas.drawLine(Offset(w * 0.16, h * 0.84), Offset(w * 0.84, h * 0.84), paint);
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

class _CardDashedLine extends CustomPainter {
  const _CardDashedLine();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.orderDeliveryDivider
      ..strokeWidth = 1;
    const double dash = 4;
    const double gap = 4;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BagPainter extends CustomPainter {
  const _BagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path body = Path()
      ..moveTo(w * 0.12, h * 0.3)
      ..lineTo(w * 0.88, h * 0.3)
      ..lineTo(w * 0.82, h * 0.93)
      ..lineTo(w * 0.18, h * 0.93)
      ..close();
    canvas.drawPath(body, paint);
    final Path handle = Path()
      ..moveTo(w * 0.31, h * 0.3)
      ..lineTo(w * 0.31, h * 0.22)
      ..arcToPoint(
        Offset(w * 0.69, h * 0.22),
        radius: Radius.circular(w * 0.19),
      )
      ..lineTo(w * 0.69, h * 0.3);
    canvas.drawPath(handle, paint);
    final Paint smile = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path smilePath = Path()
      ..moveTo(w * 0.36, h * 0.55)
      ..quadraticBezierTo(w * 0.5, h * 0.68, w * 0.64, h * 0.55);
    canvas.drawPath(smilePath, smile);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LockPainter extends CustomPainter {
  const _LockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()
      ..color = const Color(0xFF2A5238)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path shackle = Path()
      ..moveTo(w * 0.25, h * 0.44)
      ..lineTo(w * 0.25, h * 0.3)
      ..arcToPoint(
        Offset(w * 0.75, h * 0.3),
        radius: Radius.circular(w * 0.25),
      )
      ..lineTo(w * 0.75, h * 0.44);
    canvas.drawPath(shackle, paint);
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.09, h * 0.44, w * 0.82, h * 0.5),
      Radius.circular(w * 0.13),
    );
    canvas.drawRRect(body, paint);
    final Paint keyhole = Paint()..color = const Color(0xFF2A5238);
    canvas.drawCircle(Offset(w * 0.5, h * 0.66), w * 0.1, keyhole);
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
          const Positioned(
            left: 109,
            top: 75,
            child: _Label(
              'Salem, Tamil Nadu',
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

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 166,
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
            left: 19,
            top: 17,
            child: Container(
              alignment: Alignment.center,
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.orderDeliveryTileStart,
                    AppColors.orderDeliveryTileEnd,
                  ],
                ),
              ),
              child: const CustomPaint(
                size: Size(26, 26),
                painter: _BagPainter(),
              ),
            ),
          ),
          Positioned(
            left: 86,
            top: 18,
            child: _Label(
              AppStrings.trOf(context, 'Delivery Details'),
              AppTextStyles.orderCardTitle.copyWith(fontSize: 15),
              width: 112,
              height: 25,
            ),
          ),
          Positioned(
            left: 86,
            top: 38,
            child: SizedBox(
              width: 224,
              height: 40,
              child: Text(
                AppStrings.trOf(
                  context,
                  'Waiting for the buyer to arrive at your\nlocation',
                ),
                style: AppTextStyles.orderSubText,
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 88,
            child: CustomPaint(
              size: Size(325, 1),
              painter: _CardDashedLine(),
            ),
          ),
          Positioned(
            left: 20,
            top: 104,
            child: Container(
              alignment: Alignment.center,
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6E6),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Image(
                image: AssetImage('assets/order/ic_calendar.png'),
                width: 20,
                height: 20,
              ),
            ),
          ),
          Positioned(
            left: 72,
            top: 103,
            child: _Label(
              AppStrings.trOf(context, 'Expected Pickup Date'),
              AppTextStyles.orderItemMeta,
              width: 150,
              height: 25,
            ),
          ),
          Positioned(
            left: 72,
            top: 125,
            child: _Label(
              '24 Mar 2024',
              AppTextStyles.orderDate.copyWith(fontSize: 14),
              width: 110,
              height: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.controller,
    required this.focusNode,
    required this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool error;

  static const List<double> _boxLefts = <double>[0, 86, 172, 258];

  @override
  Widget build(BuildContext context) {
    final String value = controller.text;
    return Container(
      width: 368,
      height: 211,
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
            left: 19,
            top: 21,
            child: Container(
              alignment: Alignment.center,
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6E6),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const CustomPaint(
                size: Size(16, 17),
                painter: _LockPainter(),
              ),
            ),
          ),
          Positioned(
            left: 72,
            top: 24,
            child: _Label(
              AppStrings.trOf(context, 'Enter pickup code'),
              AppTextStyles.orderCardTitle.copyWith(fontSize: 15),
              width: 140,
              height: 25,
            ),
          ),
          Positioned(
            left: 23,
            top: 64,
            child: SizedBox(
              width: 315,
              height: 44,
              child: Text(
                AppStrings.trOf(
                  context,
                  'Ask the buyer for the 4-digit code shown in their app only when they arrive.',
                ),
                style: AppTextStyles.orderCodeNote.copyWith(height: 1.65),
              ),
            ),
          ),
          Positioned(
            left: 23,
            top: 120,
            width: 312,
            height: 61,
            child: Stack(
              key: const Key('pickup-code-boxes'),
              children: [
                for (var i = 0; i < 4; i++)
                  Positioned(
                    left: _CodeCard._boxLefts[i],
                    top: i == 0 ? 0 : 1,
                    child: _CodeBox(
                      active: i == value.length,
                      character: i < value.length ? value[i] : null,
                      error: error,
                    ),
                  ),
                Positioned(
                  left: 0,
                  top: 0,
                  width: 312,
                  height: 61,
                  child: TextField(
                    key: const Key('pickup-code-field'),
                    controller: controller,
                    focusNode: focusNode,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    showCursor: false,
                    enableInteractiveSelection: false,
                    style: const TextStyle(
                      color: Colors.transparent,
                      fontSize: 1,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (error)
            Positioned(
              left: 23,
              top: 186,
              width: 258,
              height: 14,
              child: _Label(
                AppStrings.trOf(context, 'Incorrect code. Try again.'),
                const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.attentionRed,
                ),
                width: 258,
                height: 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.active,
    required this.character,
    required this.error,
  });

  final bool active;
  final String? character;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final bool filled = character != null;
    final Color borderColor = error
        ? AppColors.attentionRed
        : active
        ? const Color(0xFF2E8B4B)
        : const Color(0xFFDFE3E8);
    final double borderWidth = error || active ? 2 : (filled ? 1 : 0);

    return Container(
      width: 54,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active || filled ? Colors.white : const Color(0xFFF3F6E6),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: borderWidth == 0
            ? null
            : Border.all(color: borderColor, width: borderWidth),
        boxShadow: active && !error
            ? const [BoxShadow(color: Color(0xFFDDECE2), spreadRadius: 4.5)]
            : null,
      ),
      child: character != null
          ? Text(
              character!,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            )
          : null,
    );
  }
}

class _SlideConfirm extends StatefulWidget {
  const _SlideConfirm({required this.locked, required this.onSubmit});

  final bool locked;
  final bool Function() onSubmit;

  @override
  State<_SlideConfirm> createState() => _SlideConfirmState();
}

class _SlideConfirmState extends State<_SlideConfirm>
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
    if (widget.locked) return;
    _controller.stop();
    setState(() {
      _knobX = (_knobX + details.delta.dx).clamp(_start, _end);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.locked) return;
    if (_knobX >= _threshold || details.velocity.pixelsPerSecond.dx > 300) {
      final bool done = widget.onSubmit();
      if (done) {
        setState(() => _knobX = _end);
      } else {
        _controller.value = ((_knobX - _start) / _travel).clamp(0.0, 1.0);
        _controller.reverse();
      }
      return;
    }
    _controller.value = ((_knobX - _start) / _travel).clamp(0.0, 1.0);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return HoverPress.slide(
      child: SlideDragDetector(
        onTap: widget.locked
            ? null
            : () {
                if (widget.onSubmit()) {
                  setState(() => _knobX = _end);
                }
              },
        onUpdate: _onDragUpdate,
        onEnd: _onDragEnd,
        child: Container(
          key: const Key('pickup-slide-bar'),
          width: 364,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(29)),
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
                  key: const Key('pickup-slide-knob'),
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
                left: 94,
                top: 19,
                child: Text(
                  AppStrings.trOf(context, 'Slide to confirm pickup'),
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
