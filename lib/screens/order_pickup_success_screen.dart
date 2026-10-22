import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';

/// Order Details ├óΓé¼ΓÇ¥ pickup completed state. Static replica of Zeplin
/// "Android Compact - 165".
class OrderPickupSuccessScreen extends StatelessWidget {
  const OrderPickupSuccessScreen({super.key});

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
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Roboto'),
            child: Stack(
            children: [
              const Positioned(left: 24, top: 73, child: _BackCircle()),
              Positioned(
                left: 68,
                top: 73,
                width: 200,
                height: 25,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Order Details',
                    style: AppTextStyles.orderTitle.copyWith(
                      letterSpacing: 1.05,
                    ),
                  ),
                ),
              ),
              const Positioned(left: 24, top: 117, child: _SegmentTabs()),
              const Positioned(left: 25, top: 172, child: _HeroCard()),
              const Positioned(left: 25, top: 359, child: _SuccessCard()),
              const Positioned(left: 24, top: 847, child: _BackButton()),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.style, {required this.width, this.height = 25});

  final String text;
  final TextStyle style;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: style),
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
          colors: [AppColors.orderLime, Color(0xFFCDECA8)],
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
          const Positioned(
            left: 14,
            top: 10,
            child: _Label(
              'ORDER #NX4582',
              TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
                color: AppColors.orderIdGreen,
              ),
              width: 113,
              height: 15,
            ),
          ),
          Positioned(
            left: 278,
            top: 11,
            child: Container(
              width: 68.5,
              height: 18.5,
              decoration: const BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: BorderRadius.all(Radius.circular(9.25)),
              ),
            ),
          ),
          const Positioned(
            left: 289.5,
            top: 17.75,
            child: _Dot(size: 5, color: AppColors.orderDivider),
          ),
          const Positioned(
            left: 297.5,
            top: 10.25,
            child: _Label(
              'Pick up',
              AppTextStyles.orderPillLabel,
              width: 44,
              height: 20,
            ),
          ),
          const Positioned(
            left: 15,
            top: 30.5,
            child: _Label(
              'Ready for Pickup',
              TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.35,
                color: AppColors.orderDark,
              ),
              width: 260,
              height: 34,
            ),
          ),
          const Positioned(left: 15, top: 76, child: _ProgressStrip()),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip();

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.orderDark,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 332,
      height: 79,
      decoration: const BoxDecoration(
        color: AppColors.orderMint,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 37,
            top: 33,
            child: CustomPaint(size: Size(260, 1), painter: _DashedLine()),
          ),
          for (int i = 0; i < 5; i++)
            Positioned(left: 21 + i * 65, top: 18, child: _StepCircle(index: i)),
          const Positioned(
            left: 21,
            top: 55,
            child: _Label('Active', _labelStyle, width: 34, height: 15),
          ),
          const Positioned(
            left: 78.5,
            top: 55,
            child: _Label('Accepted', _labelStyle, width: 48, height: 15),
          ),
          const Positioned(
            left: 152,
            top: 55,
            child: _Label('Ready', _labelStyle, width: 34, height: 15),
          ),
          const Positioned(
            left: 215,
            top: 55,
            child: _Label('Pickup', _labelStyle, width: 38, height: 15),
          ),
          const Positioned(
            left: 267,
            top: 55,
            child: _Label('Completed', _labelStyle, width: 60, height: 15),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -2,
            top: -2,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0x80C6E96D),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (index < 4)
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF2E8B4B),
                shape: BoxShape.circle,
              ),
              child: const CustomPaint(
                size: Size(12, 10),
                painter: _TickPainter(),
              ),
            )
          else
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.orderDark,
                shape: BoxShape.circle,
              ),
              child: const CustomPaint(
                size: Size(16, 16),
                painter: _FlagPainter(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(1.5, 5.5)
      ..lineTo(4.2, 8.3)
      ..lineTo(10.5, 1.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.orderDivider
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path flag = Path()
      ..moveTo(4, 3)
      ..lineTo(12, 3)
      ..lineTo(9.5, 8)
      ..lineTo(12, 12)
      ..lineTo(4, 12);
    canvas.drawPath(flag, paint);
    canvas.drawLine(const Offset(4, 12), const Offset(4, 15.5), paint);
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

class _SuccessCard extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 374,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x129E9E9E),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x0E9E9E9E),
            offset: Offset(0, 3),
            blurRadius: 5,
          ),
          BoxShadow(
            color: Color(0x069E9E9E),
            offset: Offset(0, 7),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x039E9E9E),
            offset: Offset(0, 12),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 115.25,
            top: 11.25,
            child: Container(
              width: 128.5,
              height: 128.5,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FCE9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 122.75,
            top: 18.75,
            child: Container(
              width: 113.5,
              height: 113.5,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF7C3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 131,
            top: 27,
            child: Container(
              width: 97.5,
              height: 97.5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFBFE367), Color(0xFF3A924E)],
                ),
              ),
              child: const CustomPaint(painter: _CheckPainter()),
            ),
          ),
          Positioned(
            left: 14,
            top: 151,
            child: Container(
              width: 333,
              height: 87.5,
              decoration: const BoxDecoration(
                color: AppColors.orderCardDark,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
          ),
          const Positioned(
            left: 12.5,
            top: 169.8,
            width: 333,
            height: 17,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF829B8C),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 12,
            top: 185.6,
            width: 333,
            height: 40,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '\u20B92,840',
                style: TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.1,
                  color: Color(0xFFCDEB6B),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 249,
            child: Container(
              width: 333.5,
              height: 68.5,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6E6),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const Positioned(
            left: 31.5,
            top: 265.9,
            width: 90,
            height: 15,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Order',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF7F8078)),
              ),
            ),
          ),
          const Positioned(
            left: 126.4,
            top: 265.9,
            width: 90,
            height: 15,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Items',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF7F8078)),
              ),
            ),
          ),
          const Positioned(
            left: 230,
            top: 265.9,
            width: 90,
            height: 15,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Picked up',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF7F8078)),
              ),
            ),
          ),
          const Positioned(
            left: 25.5,
            top: 280.3,
            width: 100,
            height: 17,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '#NX4582',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 120.4,
            top: 280.3,
            width: 100,
            height: 17,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '3',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 224.5,
            top: 280.3,
            width: 100,
            height: 17,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '25 Mar 2024',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            left: 101,
            top: 329,
            child: Container(
              width: 160,
              height: 27,
              decoration: const BoxDecoration(
                color: AppColors.orderTile,
                borderRadius: BorderRadius.all(Radius.circular(13.5)),
              ),
            ),
          ),
          const Positioned(
            left: 113.5,
            top: 337.5,
            child: CustomPaint(
              size: Size(10, 8),
              painter: _WalletPainter(),
            ),
          ),
          const Positioned(
            left: 130,
            top: 334.9,
            child: _Label(
                'Added to your earnings',
                TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D3D21),
                ),
              width: 128,
              height: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(30.5, 49)
      ..lineTo(40, 60)
      ..lineTo(67, 32);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WalletPainter extends CustomPainter {
  const _WalletPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF0D3D21)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.55, 0.55, 8.9, 6.9),
        const Radius.circular(2.3),
      ),
      paint,
    );
    canvas.drawLine(const Offset(6.8, 2.6), const Offset(6.8, 5.4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 364,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(29)),
          gradient: const LinearGradient(
            colors: [Color(0xFF0E3B1F), AppColors.orderSlideEnd],
          ),
          border: Border.all(color: const Color(0x14000000)),
          boxShadow: const [
            BoxShadow(color: Color(0x21000000), offset: Offset(0, 12)),
            BoxShadow(color: Color(0x01000000), offset: Offset(0, 8)),
            BoxShadow(color: Color(0x02000000), offset: Offset(0, 6)),
            BoxShadow(color: Color(0x01000000), offset: Offset(0, 4)),
            BoxShadow(color: Color(0x02000000), offset: Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 3,
              top: 3,
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
              left: 87,
              top: 0,
              width: 200,
              height: 58,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Back to orders',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: Colors.white,
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
