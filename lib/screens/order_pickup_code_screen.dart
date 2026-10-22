import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import 'order_pickup_success_screen.dart';

/// Order Details ├óΓé¼ΓÇ¥ pickup code entry state. Static replica of Zeplin
/// "Android Compact - 154".
class OrderPickupCodeScreen extends StatelessWidget {
  const OrderPickupCodeScreen({super.key});

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
              const Positioned(left: 25, top: 359, child: _CodeCard()),
              const Positioned(left: 24, top: 847, child: _ContinueButton()),
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
            Positioned(
              left: 21 + i * 65,
              top: 18,
              child: _StepCircle(index: i),
            ),
          const Positioned(
            left: 21,
            top: 55,
            child: _Label(
              'Active',
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.orderDark,
              ),
              width: 34,
              height: 15,
            ),
          ),
          const Positioned(
            left: 78.5,
            top: 55,
            child: _Label(
              'Accepted',
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.orderDark,
              ),
              width: 48,
              height: 15,
            ),
          ),
          const Positioned(
            left: 152,
            top: 55,
            child: _Label(
              'Ready',
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.orderDark,
              ),
              width: 34,
              height: 15,
            ),
          ),
          const Positioned(
            left: 215,
            top: 55,
            child: _Label(
              'Pickup',
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.orderDark,
              ),
              width: 38,
              height: 15,
            ),
          ),
          const Positioned(
            left: 267,
            top: 55,
            child: _Label(
              'Completed',
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0x8C0D3B20),
              ),
              width: 60,
              height: 15,
            ),
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
          if (index < 3)
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
          else if (index == 3)
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.orderDark,
                shape: BoxShape.circle,
              ),
              child: const CustomPaint(
                size: Size(20, 20),
                painter: _DownloadPainter(),
              ),
            )
          else
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Image(
                image: AssetImage('assets/order/ic_step_flag.png'),
                width: 15,
                height: 15,
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

class _DownloadPainter extends CustomPainter {
  const _DownloadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.orderDivider
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(10, 2), const Offset(10, 10), paint);
    final Path head = Path()
      ..moveTo(5, 7)
      ..lineTo(10, 11)
      ..lineTo(15, 7);
    canvas.drawPath(head, paint);
    canvas.drawLine(const Offset(0.5, 17.5), const Offset(19.5, 17.5), paint);
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

class _CodeCard extends StatelessWidget {
  const _CodeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 275,
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
            left: 14,
            top: 21,
            child: Container(
              width: 333.5,
              height: 76.5,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6E6),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          Positioned(
            left: 28,
            top: 38,
            child: Container(
              alignment: Alignment.center,
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.orderTile,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
        child: Transform.translate(
          offset: const Offset(-1, -1),
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0, 0, 0, 0, 13,
              0, 0, 0, 0, 59,
              0, 0, 0, 0, 32,
              0, 8, 0, 0, -1200,
            ]),
            child: const Image(
              image: AssetImage('assets/order/ic_shop.png'),
              width: 20,
              height: 20,
            ),
          ),
        ),
            ),
          ),
          const Positioned(
            left: 130,
            top: 42.5,
            child: _Label(
              'Akash Stores',
              TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
              width: 130,
              height: 18,
            ),
          ),
          Positioned(
            left: 122,
            top: 62.5,
            child: SizedBox(
              width: 170,
              height: 14,
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7F8078),
                  ),
                  children: [
                    TextSpan(
                      text: '#NX4582',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.orderIdGreen,
                      ),
                    ),
                    TextSpan(
                      text: ' \u2022 3 Items',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 273.5,
            top: 45.9,
            child: _Label(
              '\u20B92,840',
              TextStyle(
                fontSize: 19.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: AppColors.textPrimary,
              ),
              width: 70,
              height: 26,
            ),
          ),
          Positioned(
            left: 79,
            top: 131,
            width: 200,
            height: 26,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Enter pickup code',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.35,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 49,
            top: 160.5,
            child: _Label(
              'Ask the buyer for the 4-digital code shown in their app',
              TextStyle(fontSize: 12, color: Color(0xFF858585)),
              width: 300,
              height: 16,
            ),
          ),
          Positioned(
            left: 53,
            top: 189,
            child: Container(
              width: 54,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: const Color(0xFF2E8B4B), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFDDECE2),
                    spreadRadius: 4.5,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 122,
            top: 190,
            child: Container(
              width: 54,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6E6),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          Positioned(
            left: 190,
            top: 190,
            child: Container(
              width: 54,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6E6),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          Positioned(
            left: 258,
            top: 190,
            child: Container(
              width: 54,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6E6),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const OrderPickupSuccessScreen(),
          ),
        );
      },
      child: Container(
        width: 364,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(29)),
          gradient: const LinearGradient(
            colors: [Color(0xFF607E6A), Color(0xFF71CA93)],
          ),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                alignment: Alignment.center,
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF9EC463),
                  shape: BoxShape.circle,
                ),
                child: const CustomPaint(
                  size: Size(17, 11),
                  painter: _ArrowPainter(),
                ),
              ),
            ),
            Positioned(
              left: 65,
              top: -1,
              width: 250,
              height: 58,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Enter the code to continus',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
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

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF3C6736)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(0.5, 5.5)
      ..lineTo(16.5, 5.5)
      ..moveTo(11.5, 0.5)
      ..lineTo(16.5, 5.5)
      ..lineTo(11.5, 10.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

