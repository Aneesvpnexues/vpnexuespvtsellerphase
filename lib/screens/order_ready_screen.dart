import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';
import '../widgets/slide_drag_detector.dart';

/// Order Ready (Buyer Pickup, 3 of 3 packed) - static replica of Zeplin
/// "Android Compact - 140" (project 6a8d49709e27bd8b35213d35, screen
/// 6ad1ae14aa9fda71b12bf082).
///
/// Built against the same 412x917 artboard as 139 and shares its header,
/// segment tabs, hero, progress card, buyer card and packing shell. The deltas
/// against 139 are the Ready hero pill, the filled checklist ticks, the
/// horizontal row/track/CTA gradients, the lime "3/3 packed" pill, the enabled
/// slide CTA and the diagonal hero fill (measured off the design PNG, Zeplin's
/// REST payload drops the gradient angle).
///
/// The slide CTA keeps the 135/139 gesture: a drag past 70% settles at the end,
/// a shorter one springs back. A full slide opens the out-for-delivery state
/// (141), a tap only settles the knob.
class OrderReadyScreen extends StatelessWidget {
  const OrderReadyScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

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
              const Positioned(left: 24, top: 73, child: _BackCircle()),
              const Positioned(
                left: 68,
                top: 73,
                child: LabelText(
                  'Order Details',
                  AppTextStyles.orderTitle,
                  width: 200,
                  height: 25,
                ),
              ),
              const Positioned(left: 24, top: 117, child: _SegmentTabs()),
              const Positioned(left: 25, top: 172, child: _OrderHero()),
              const Positioned(left: 41, top: 247, child: _ProgressCard()),
              const Positioned(left: 24, top: 358, child: _BuyerCard()),
              const Positioned(left: 24, top: 552, child: _PackingCard()),
              Positioned(
                left: 24,
                top: 847,
                child: _SlideReady(
                  onComplete: () => goToOrderDelivery(context),
                ),
              ),
            ],
          ),
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
        alignment: Alignment.center,
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: const Image(
          image: AssetImage('assets/order/ic_back.png'),
          width: 15,
          height: 15,
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

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 364,
      height: 45,
      child: Stack(
        children: [
          Container(
            width: 364,
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
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A00570E),
                    offset: Offset(1, 1),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: Color(0x1700570E),
                    offset: Offset(5, 6),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Color(0x0D00570E),
                    offset: Offset(11, 13),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Color(0x0300570E),
                    offset: Offset(20, 24),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Color(0x0000570E),
                    offset: Offset(31, 37),
                    blurRadius: 13,
                  ),
                ],
              ),
              child: const Text(
                'Buyer Pickup',
                style: AppTextStyles.orderSegmentActive,
              ),
            ),
          ),
          const Positioned(
            left: 238,
            top: 10,
            child: LabelText(
              'Delivery',
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
      height: 173,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orderLime, AppColors.orderHeroFade],
          stops: [0.1037, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A707070),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
          BoxShadow(
            color: Color(0x17707070),
            offset: Offset(0, 40),
            blurRadius: 40,
          ),
          BoxShadow(
            color: Color(0x0D707070),
            offset: Offset(0, 90),
            blurRadius: 54,
          ),
          BoxShadow(
            color: Color(0x03707070),
            offset: Offset(0, 159),
            blurRadius: 64,
          ),
          BoxShadow(
            color: Color(0x00707070),
            offset: Offset(0, 249),
            blurRadius: 70,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 16,
            top: 12,
            child: LabelText(
              'ORDER #NX4582',
              AppTextStyles.orderId,
              width: 107,
              height: 15,
            ),
          ),
          const Positioned(
            left: 16,
            top: 34,
            child: LabelText(
              'Order Accepted',
              AppTextStyles.orderHeroTitle,
              width: 222,
              height: 27,
            ),
          ),
          Positioned(
            left: 291,
            top: 11,
            child: Container(
              width: 56.29,
              height: 19,
              decoration: BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          const Positioned(
            left: 274.73,
            top: 18.3,
            child: _Dot(size: 4.39, color: AppColors.orderDivider),
          ),
          Positioned(
            left: 283.12,
            top: 8,
            child: LabelText(
              'Ready',
              AppTextStyles.orderPillLabel.copyWith(
                color: AppColors.orderDivider,
              ),
              width: 40.1,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  static const List<_Step> steps = [
    _Step(
      label: 'Active',
      left: 20,
      labelLeft: 22,
      labelWidth: 32,
      icon: 'assets/order_accepted/ic_step_check.png',
      iconSize: 20,
      iconDx: 8,
      iconDy: 8,
      state: _StepState.active,
    ),
    _Step(
      label: 'Accepted',
      left: 85,
      labelLeft: 79,
      labelWidth: 48,
      icon: 'assets/order/ic_step_tick.png',
      iconSize: 19,
      iconDx: 9,
      iconDy: 9,
      state: _StepState.done,
    ),
    _Step(
      label: 'Ready',
      left: 150,
      labelLeft: 153,
      labelWidth: 31,
      icon: 'assets/order/ic_step_package.png',
      iconSize: 16,
      iconDx: 10,
      iconDy: 10,
      state: _StepState.idle,
    ),
    _Step(
      label: 'Pickup',
      left: 215,
      labelLeft: 216,
      labelWidth: 34,
      icon: 'assets/order/ic_step_download.png',
      iconSize: 20,
      iconDx: 8,
      iconDy: 8,
      state: _StepState.idle,
    ),
    _Step(
      label: 'Completed',
      left: 280,
      labelLeft: 269,
      labelWidth: 55,
      icon: 'assets/order/ic_step_flag.png',
      iconSize: 18,
      iconDx: 10,
      iconDy: 9,
      state: _StepState.idle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 334,
      height: 81,
      decoration: BoxDecoration(
        color: AppColors.orderMint,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A949494),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
          BoxShadow(
            color: Color(0x17949494),
            offset: Offset(0, 40),
            blurRadius: 40,
          ),
          BoxShadow(
            color: Color(0x0D949494),
            offset: Offset(0, 90),
            blurRadius: 54,
          ),
          BoxShadow(
            color: Color(0x03949494),
            offset: Offset(0, 160),
            blurRadius: 64,
          ),
          BoxShadow(
            color: Color(0x00949494),
            offset: Offset(0, 251),
            blurRadius: 70,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 30,
            top: 34,
            child: CustomPaint(size: Size(266, 1), painter: _DashedLine()),
          ),
          for (final _Step step in steps)
            Positioned(
              left: step.left,
              top: 17,
              child: _StepCircle(step: step),
            ),
          for (final _Step step in steps)
            Positioned(
              left: step.labelLeft,
              top: 51,
              child: LabelText(
                step.label,
                AppTextStyles.orderStepLabel,
                width: step.labelWidth,
                height: 25,
              ),
            ),
        ],
      ),
    );
  }
}

enum _StepState { active, done, idle }

class _Step {
  const _Step({
    required this.label,
    required this.left,
    required this.labelLeft,
    required this.labelWidth,
    required this.icon,
    required this.iconSize,
    required this.iconDx,
    required this.iconDy,
    required this.state,
  });

  final String label;
  final double left;
  final double labelLeft;
  final double labelWidth;
  final String icon;
  final double iconSize;
  final double iconDx;
  final double iconDy;
  final _StepState state;
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final Color fill = switch (step.state) {
      _StepState.active => AppColors.orderStepGreen,
      _StepState.done => AppColors.orderDark,
      _StepState.idle => Colors.white,
    };
    final Border border = switch (step.state) {
      _StepState.active => Border.all(
        color: AppColors.orderStepActiveRing,
        width: 2,
      ),
      _StepState.done => Border.all(color: AppColors.limeLight, width: 2),
      _StepState.idle => Border.all(color: AppColors.orderStepRing, width: 2),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      child: Stack(
        children: [
          Positioned(
            left: step.iconDx,
            top: step.iconDy,
            child: Image(
              image: AssetImage(step.icon),
              width: step.iconSize,
              height: step.iconSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  const _DashedLine();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.orderDivider
      ..strokeWidth = 1;
    const double dash = 6;
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

class _BuyerCard extends StatelessWidget {
  const _BuyerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 181,
      decoration: BoxDecoration(
        color: AppColors.orderCardDark,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 17,
            top: 15,
            child: LabelText(
              'BUYER DETAILS',
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
            child: LabelText(
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
            child: LabelText(
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
            child: LabelText(
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
              decoration: BoxDecoration(
                color: AppColors.orderLime,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          const Positioned(
            left: 253,
            top: 45,
            child: LabelText(
              'Retailer',
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
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: const Stack(
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
                    child: LabelText(
                      'Call',
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
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: const Stack(
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
                    child: LabelText(
                      'Call',
                      TextStyle(
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

class _PackingCard extends StatelessWidget {
  const _PackingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 282,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A949494),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
          BoxShadow(
            color: Color(0x17949494),
            offset: Offset(0, 40),
            blurRadius: 40,
          ),
          BoxShadow(
            color: Color(0x0D949494),
            offset: Offset(0, 90),
            blurRadius: 54,
          ),
          BoxShadow(
            color: Color(0x03949494),
            offset: Offset(0, 160),
            blurRadius: 64,
          ),
          BoxShadow(
            color: Color(0x00949494),
            offset: Offset(0, 251),
            blurRadius: 70,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
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
          const Positioned(
            left: 56,
            top: 19,
            child: LabelText(
              'Packing checklist',
              AppTextStyles.orderCardTitle,
              width: 125,
            ),
          ),
          Positioned(
            left: 268,
            top: 23,
            child: Container(
              width: 79,
              height: 19,
              decoration: BoxDecoration(
                color: AppColors.orderTile,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          const Positioned(
            left: 280,
            top: 20,
            child: LabelText(
              '3/3 packed',
              AppTextStyles.orderStepLabel,
              width: 59,
              height: 20,
            ),
          ),
          Positioned(
            left: 17,
            top: 59,
            child: Container(
              width: 330,
              height: 4,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(7)),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.orderTrackStart,
                    AppColors.orderTrackMid,
                    AppColors.orderTrackEnd,
                  ],
                  stops: [0, 0.504807710647583, 1],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 16,
            top: 79,
            child: _PackRow(
              image: 'assets/order/tomatoes.png',
              name: 'Fresh Tomatoes',
              qty: '50 kg',
              start: AppColors.orderRow1Start,
              end: AppColors.orderRow1End,
            ),
          ),
          const Positioned(
            left: 16,
            top: 142,
            child: _PackRow(
              image: 'assets/order/chillies.png',
              name: 'Green Chillies',
              qty: '30 kg',
              start: AppColors.orderRow2Start,
              end: AppColors.orderRow2End,
            ),
          ),
          const Positioned(
            left: 16,
            top: 205,
            child: _PackRow(
              image: 'assets/order/chillies2.png',
              name: 'Green Chillies',
              qty: '20 kg',
              start: AppColors.orderRow3Start,
              end: AppColors.orderRow3End,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({
    required this.image,
    required this.name,
    required this.qty,
    required this.start,
    required this.end,
  });

  final String image;
  final String name;
  final String qty;
  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 331,
      height: 59,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [start, end],
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: const Color(0x0D000000)),
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
            child: LabelText(name, AppTextStyles.orderItemName, width: 120),
          ),
          Positioned(
            left: 67,
            top: 26,
            child: LabelText(qty, AppTextStyles.orderItemMeta, width: 60),
          ),
          Positioned(
            left: 295,
            top: 17,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.orderStepGreen,
                borderRadius: BorderRadius.all(Radius.circular(7)),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 7,
                    top: 7.5,
                    child: Image(
                      image: AssetImage(
                        'assets/order_ready/ic_badge_check.png',
                      ),
                      width: 10.5,
                      height: 9,
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

class _SlideReady extends StatefulWidget {
  const _SlideReady({required this.onComplete});

  /// Called once the knob has been dragged all the way to the end.
  final VoidCallback onComplete;

  @override
  State<_SlideReady> createState() => _SlideReadyState();
}

class _SlideReadyState extends State<_SlideReady>
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
      widget.onComplete();
      return;
    }
    _controller.value = ((_knobX - _start) / _travel).clamp(0.0, 1.0);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SlideDragDetector(
      onTap: () => setState(() => _knobX = _end),
      onUpdate: _onDragUpdate,
      onEnd: _onDragEnd,
      child: Container(
        width: 364,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.orderSlideStart, AppColors.orderSlideEnd],
            stops: [0.11656297743320465, 1],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              offset: Offset(0, 22),
              blurRadius: 30,
              spreadRadius: -2,
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          border: Border.all(color: const Color(0x0F000000)),
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
            const Positioned(
              left: 109,
              top: 15,
              child: LabelText(
                'Slide to mark as ready',
                AppTextStyles.orderSlideLabel,
                width: 154,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
