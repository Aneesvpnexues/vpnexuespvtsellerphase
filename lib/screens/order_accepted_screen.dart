import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

/// Order Accepted (Buyer Pickup / packing checklist) - static replica of
/// Zeplin "Android Compact - 139" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ae15e87c44ea55984599).
///
/// Built against a 412x917 artboard. Same zoom-scroll pattern as
/// 117/123/132/135: fit width, scroll vertically for the 917px tall content.
/// The packing checklist is live: tapping a row ticks it off, the counter and
/// the rail follow, and the CTA only continues once all three are packed.
class OrderAcceptedScreen extends StatefulWidget {
  const OrderAcceptedScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  @override
  State<OrderAcceptedScreen> createState() => _OrderAcceptedScreenState();
}

class _OrderAcceptedScreenState extends State<OrderAcceptedScreen> {
  final Set<int> _packed = <int>{};

  bool get _allPacked => _packed.length == 3;

  void _togglePacked(int index) {
    setState(() {
      if (!_packed.remove(index)) {
        _packed.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: OrderAcceptedScreen.designWidth,
          designHeight: OrderAcceptedScreen.designHeight,
          trimTop: OrderAcceptedScreen.trimTop,
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
              Positioned(
                left: 24,
                top: 552,
                child: _PackingCard(packed: _packed, onToggle: _togglePacked),
              ),
              Positioned(
                left: 21,
                top: 847,
                child: _PackCta(
                  active: _allPacked,
                  onComplete: () => goToOrderReady(context),
                ),
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
/// reproduce the design's half-leading. Without it Flutter clamps paragraphs
/// that are taller than the box (e.g. the 28px hero title: natural line box
/// 34px > 27px box) and paints the glyphs a few pixels lower than Zeplin.
///
/// Zeplin boxes hug the text, so the Inter advance plus Flutter's trailing
/// letter spacing can be a hair wider than the box (e.g. 'ORDER #NX4582':
/// 108.8px in a 107px box). Every label in the design is single line, so
/// wrapping is disabled instead of widening the box.
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
            child: _Label(
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
            child: _Label(
              'ORDER #NX4582',
              AppTextStyles.orderId,
              width: 107,
              height: 15,
            ),
          ),
          const Positioned(
            left: 16,
            top: 34,
            child: _Label(
              'Order Accepted',
              AppTextStyles.orderHeroTitle,
              width: 222,
              height: 27,
            ),
          ),
          Positioned(
            left: 274,
            top: 11,
            child: Container(
              width: 73,
              height: 19,
              decoration: BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          const Positioned(
            left: 283,
            top: 18,
            child: _Dot(size: 5, color: AppColors.orderDivider),
          ),
          const Positioned(
            left: 291,
            top: 8,
            child: _Label(
              'Accepted',
              AppTextStyles.orderPillLabel,
              width: 52,
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
      labelWidth: 32,
      icon: 'assets/order_accepted/ic_step_check.png',
      iconSize: 20,
      iconDx: 8,
      iconDy: 8,
      state: _StepState.active,
    ),
    _Step(
      label: 'Accepted',
      labelWidth: 48,
      icon: 'assets/order/ic_step_tick.png',
      iconSize: 19,
      iconDx: 9,
      iconDy: 9,
      state: _StepState.done,
    ),
    _Step(
      label: 'Ready',
      labelWidth: 31,
      icon: 'assets/order/ic_step_package.png',
      iconSize: 16,
      iconDx: 10,
      iconDy: 10,
      state: _StepState.idle,
    ),
    _Step(
      label: 'Pickup',
      labelWidth: 34,
      icon: 'assets/order/ic_step_download.png',
      iconSize: 20,
      iconDx: 8,
      iconDy: 8,
      state: _StepState.idle,
    ),
    _Step(
      label: 'Completed',
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
          for (int i = 0; i < steps.length; i++)
            Positioned(
              left: 20 + i * 65,
              top: 17,
              child: _StepCircle(step: steps[i]),
            ),
          for (int i = 0; i < steps.length; i++)
            Positioned(
              left: 20 + i * 65,
              top: 51,
              child: _Label(
                steps[i].label,
                steps[i].state == _StepState.idle
                    ? AppTextStyles.orderStepLabelIdle
                    : AppTextStyles.orderStepLabel,
                width: steps[i].labelWidth,
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
    required this.labelWidth,
    required this.icon,
    required this.iconSize,
    required this.iconDx,
    required this.iconDy,
    required this.state,
  });

  final String label;
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
    final Border? border = switch (step.state) {
      _StepState.active => null,
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
            child: _Label(
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
            child: _Label(
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
                    child: _Label(
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
                    child: _Label(
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
  const _PackingCard({required this.packed, required this.onToggle});

  final Set<int> packed;
  final ValueChanged<int> onToggle;

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
            child: _Label(
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
          Positioned(
            left: 281,
            top: 20,
            child: _Label(
              '${packed.length}/3 packed',
              AppTextStyles.orderStepLabel,
              width: 59,
              height: 20,
            ),
          ),
          Positioned(
            left: 17,
            top: 59,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(7)),
              child: Container(
                width: 330,
                height: 6,
                color: AppColors.orderTrack,
                child: CustomPaint(painter: _PackProgress(packed.length / 3)),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 79,
            child: _PackRow(
              image: 'assets/order/tomatoes.png',
              name: 'Fresh Tomatoes',
              qty: '50 kg',
              packed: packed.contains(0),
              onTap: () => onToggle(0),
            ),
          ),
          Positioned(
            left: 16,
            top: 142,
            child: _PackRow(
              image: 'assets/order/chillies.png',
              name: 'Green Chillies',
              qty: '30 kg',
              packed: packed.contains(1),
              onTap: () => onToggle(1),
            ),
          ),
          Positioned(
            left: 16,
            top: 205,
            child: _PackRow(
              image: 'assets/order/chillies2.png',
              name: 'Green Chillies',
              qty: '20 kg',
              packed: packed.contains(2),
              onTap: () => onToggle(2),
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
    required this.packed,
    required this.onTap,
  });

  final String image;
  final String name;
  final String qty;
  final bool packed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: 331,
        height: 59,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        foregroundDecoration: BoxDecoration(
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
              left: 295,
              top: 17,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: packed ? AppColors.orderStepGreen : Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(7)),
                  border: packed
                      ? null
                      : Border.all(color: AppColors.orderCheckBorder),
                ),
                child: packed
                    ? const Center(
                        child: Image(
                          image: AssetImage(
                            'assets/order_ready/ic_badge_check.png',
                          ),
                          width: 10.5,
                          height: 9,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackProgress extends CustomPainter {
  const _PackProgress(this.fill);

  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill <= 0) {
      return;
    }
    final Rect full = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * fill.clamp(0.0, 1.0), size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.orderTrackStart,
            AppColors.orderTrackMid,
            AppColors.orderTrackEnd,
          ],
          stops: [0, 0.504807710647583, 1],
        ).createShader(full),
    );
  }

  @override
  bool shouldRepaint(_PackProgress oldDelegate) => oldDelegate.fill != fill;
}

class _PackCta extends StatefulWidget {
  const _PackCta({required this.active, required this.onComplete});

  /// True once every checklist item is packed; the knob only slides then.
  final bool active;

  /// Called once the knob has been dragged past 70% of the track.
  final VoidCallback onComplete;

  @override
  State<_PackCta> createState() => _PackCtaState();
}

class _PackCtaState extends State<_PackCta>
    with SingleTickerProviderStateMixin {
  static const double _start = 4;
  static const double _end = 310;
  static const double _travel = _end - _start;
  static const double _threshold = _start + _travel * 0.7;

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
    if (!widget.active) {
      return;
    }
    _controller.stop();
    setState(() {
      _knobX = (_knobX + details.delta.dx).clamp(_start, _end);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.active) {
      _knobX = _start;
      _controller.value = 0;
      return;
    }
    if (_knobX >= _threshold) {
      setState(() => _knobX = _end);
      widget.onComplete();
      return;
    }
    _controller.value = ((_knobX - _start) / _travel).clamp(0.0, 1.0);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: SizedBox(
        width: 364,
        height: 58,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: widget.active ? 1 : 0.65,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(28)),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.orderSlideStart,
                        AppColors.orderSlideEnd,
                      ],
                      stops: [0.11656297743320465, 1],
                    ),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: _knobX,
              top: 4,
              child: Container(
                alignment: Alignment.center,
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.orderSlideCircle,
                  shape: BoxShape.circle,
                ),
                child: const Image(
                  image: AssetImage('assets/order_accepted/ic_pack_arrow.png'),
                  width: 26,
                  height: 26,
                ),
              ),
            ),
            const Positioned(
              left: 107,
              top: 15,
              child: _Label(
                'Pack all items to continue',
                AppTextStyles.orderSlideLabelMuted,
                width: 179,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
