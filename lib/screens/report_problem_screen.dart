import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

class ReportProblemScreen extends StatelessWidget {
  const ReportProblemScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  static const _titleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Colors.black,
  );
  static const _sectionStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Colors.black,
  );
  static const _chipStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Color(0xFF6B7B6F),
  );
  static const _placeholderStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: Color(0x7D000000),
  );
  static const _hintStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: Color(0x7D000000),
  );
  static const _heroMutedStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: Color(0xFFB6C5BC),
  );
  static const _heroKickerStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: Color(0xFFB6C5BC),
  );
  static const _heroTitleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.26,
    color: Color(0xFFC6E96D),
  );
  static const _supportStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08,
    color: Color(0xFFCDEB6B),
  );
  static const _submitStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14,
    color: Color(0xFFC6E96D),
  );

  static const _cardBorder = Color(0x14000000);
  static const _chipBorder = Color(0x14000000);
  static const _darkGreen = Color(0xFF0D3B20);

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
                child: LabelText('Report a problem', _titleStyle, width: 170),
              ),
              const Positioned(left: 25, top: 121, child: _SupportHero()),
              const Positioned(left: 24, top: 255, child: _FormCard()),
              const Positioned(
                left: 45,
                top: 272,
                child: LabelText(
                  'What is this about?',
                  _sectionStyle,
                  width: 114,
                ),
              ),
              const Positioned(
                left: 41,
                top: 302,
                child: _ChoiceChip(
                  width: 76,
                  label: 'Order',
                  textLeft: 21,
                  textWidth: 34,
                ),
              ),
              const Positioned(
                left: 127,
                top: 302,
                child: _ChoiceChip(
                  width: 90,
                  label: 'Product',
                  textLeft: 21.5,
                  textWidth: 47,
                ),
              ),
              const Positioned(
                left: 226,
                top: 302,
                child: _ChoiceChip(
                  width: 90,
                  label: 'Payment',
                  textLeft: 19,
                  textWidth: 52,
                ),
              ),
              const Positioned(
                left: 40,
                top: 342,
                child: _ChoiceChip(
                  width: 94,
                  label: 'Account',
                  textLeft: 22,
                  textWidth: 50,
                ),
              ),
              const Positioned(
                left: 143,
                top: 342,
                child: _ChoiceChip(
                  width: 90,
                  label: 'Other',
                  textLeft: 28,
                  textWidth: 34,
                ),
              ),
              const Positioned(
                left: 45,
                top: 384,
                child: LabelText('Order ID', _sectionStyle, width: 50),
              ),
              Positioned(
                left: 45,
                top: 410,
                child: Container(
                  width: 319,
                  height: 41,
                  decoration: const BoxDecoration(
                    color: AppColors.orderPale,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const Positioned(left: 60, top: 424, child: _AlignBoxIcon()),
              const Positioned(
                left: 86,
                top: 418,
                child: LabelText('e.g.', _placeholderStyle, width: 22),
              ),
              const Positioned(
                left: 110,
                top: 418,
                child: LabelText('#NX4582', _placeholderStyle, width: 56),
              ),
              const Positioned(
                left: 45,
                top: 462,
                child: LabelText(
                  'Tell us what happened',
                  _sectionStyle,
                  width: 133,
                ),
              ),
              Positioned(
                left: 45,
                top: 488,
                child: Container(
                  width: 319,
                  height: 101,
                  decoration: const BoxDecoration(
                    color: AppColors.orderPale,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const Positioned(
                left: 60,
                top: 496,
                child: LabelText(
                  'Describe the problem in a few words',
                  _placeholderStyle,
                  width: 214,
                ),
              ),
              const Positioned(
                left: 45,
                top: 600,
                child: LabelText('Add a photo', _sectionStyle, width: 72),
              ),
              const Positioned(left: 45, top: 626, child: _PhotoTile()),
              const Positioned(
                left: 110,
                top: 642,
                child: LabelText(
                  'A screenshot or photo helps us fix it faster',
                  _hintStyle,
                  width: 207,
                ),
              ),
              const Positioned(
                left: 45,
                top: 692,
                child: LabelText(
                  'What is this about?',
                  _sectionStyle,
                  width: 114,
                ),
              ),
              const Positioned(
                left: 41,
                top: 722,
                child: _ContactChip(
                  width: 86,
                  label: 'Call me',
                  textLeft: 21,
                  textWidth: 44,
                  filled: false,
                ),
              ),
              const Positioned(
                left: 137,
                top: 722,
                child: _ContactChip(
                  width: 99,
                  label: 'WhatsApp',
                  textLeft: 18.5,
                  textWidth: 62,
                ),
              ),
              const Positioned(
                left: 246,
                top: 722,
                child: _ContactChip(
                  width: 80,
                  label: 'Email',
                  textLeft: 24,
                  textWidth: 32,
                ),
              ),
              const Positioned(left: 25, top: 850, child: _SubmitButton()),
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
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x1A000000), blurRadius: 1),
            BoxShadow(
              color: Color(0x17000000),
              offset: Offset(0, 1),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(1, 2),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Color(0x03000000),
              offset: Offset(1, 3),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Color(0x00000000),
              offset: Offset(2, 5),
              blurRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Image.asset('assets/order/ic_back.png', width: 15, height: 15),
        ),
      ),
    );
  }
}

class _SupportHero extends StatelessWidget {
  const _SupportHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 118,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment(-0.704419945067802, -0.5811517293366738),
          end: Alignment(0.4779005750097418, 0.380281631141034),
          colors: [Color(0xFF0B341B), Color(0xFF135029)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 7),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(0, 27),
            blurRadius: 27,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 60),
            blurRadius: 36,
          ),
          BoxShadow(
            color: Color(0x03000000),
            offset: Offset(0, 107),
            blurRadius: 43,
          ),
          BoxShadow(
            color: Color(0x00000000),
            offset: Offset(0, 167),
            blurRadius: 47,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.823, -0.322),
                    radius: 1.1,
                    colors: [
                      Color(0xD13CA35A),
                      Color(0xA33CA35A),
                      Color(0x6B3CA35A),
                      Color(0x1A3CA35A),
                      Color(0x003CA35A),
                    ],
                    stops: [0, 0.19, 0.42, 0.56, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 274,
              top: 16,
              child: Container(
                width: 68,
                height: 21,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  border: Border.all(color: const Color(0x63CDEB6B), width: 1),
                ),
              ),
            ),
            const Positioned(left: 285, top: 23, child: _LimeDot()),
            const Positioned(
              left: 296,
              top: 14,
              child: LabelText(
                'Support',
                ReportProblemScreen._supportStyle,
                width: 48,
                height: 20,
              ),
            ),
            const Positioned(
              left: 20,
              top: 20,
              child: LabelText(
                'New request',
                ReportProblemScreen._heroKickerStyle,
                width: 75,
                height: 13,
              ),
            ),
            const Positioned(
              left: 20,
              top: 52,
              child: LabelText(
                'Tell us the issue',
                ReportProblemScreen._heroTitleStyle,
                width: 214,
              ),
            ),
            const Positioned(
              left: 20,
              top: 79,
              child: LabelText(
                'We’ll look into it and get back to you',
                ReportProblemScreen._heroMutedStyle,
                width: 211,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimeDot extends StatelessWidget {
  const _LimeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFCDEB6B),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 521,
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: ReportProblemScreen._cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AB8B8B8),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x17B8B8B8),
            offset: Offset(0, 6),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Color(0x0DB8B8B8),
            offset: Offset(0, 13),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x03B8B8B8),
            offset: Offset(0, 23),
            blurRadius: 9,
          ),
          BoxShadow(
            color: Color(0x00B8B8B8),
            offset: Offset(0, 36),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.width,
    required this.label,
    required this.textLeft,
    required this.textWidth,
  });

  final double width;
  final String label;
  final double textLeft;
  final double textWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 31,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: ReportProblemScreen._chipBorder),
      ),
      child: Stack(
        children: [
          Positioned(
            left: textLeft,
            top: 3,
            child: LabelText(
              label,
              ReportProblemScreen._chipStyle,
              width: textWidth,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.width,
    required this.label,
    required this.textLeft,
    required this.textWidth,
    this.filled = true,
  });

  final double width;
  final String label;
  final double textLeft;
  final double textWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 31,
      decoration: BoxDecoration(
        color: filled ? Colors.white : null,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: ReportProblemScreen._chipBorder),
      ),
      child: Stack(
        children: [
          Positioned(
            left: textLeft,
            top: 3,
            child: LabelText(
              label,
              ReportProblemScreen._chipStyle,
              width: textWidth,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlignBoxIcon extends StatelessWidget {
  const _AlignBoxIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(15, 15),
      painter: const _AlignBoxPainter(),
    );
  }
}

class _AlignBoxPainter extends CustomPainter {
  const _AlignBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0x8A000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1.875, 1.25, 11.25, 12.5),
        const Radius.circular(2.2),
      ),
      stroke,
    );
    canvas.drawLine(const Offset(5, 7.5), const Offset(10, 7.5), stroke);
  }

  @override
  bool shouldRepaint(_AlignBoxPainter oldDelegate) => false;
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 53,
      height: 55,
      child: CustomPaint(
        painter: const _DashedTilePainter(),
        child: const Stack(
          clipBehavior: Clip.none,
          children: [Positioned(left: 19, top: 19, child: _CameraGlyph())],
        ),
      ),
    );
  }
}

class _DashedTilePainter extends CustomPainter {
  const _DashedTilePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          const Radius.circular(15),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedTilePainter oldDelegate) => false;
}

class _CameraGlyph extends StatelessWidget {
  const _CameraGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 17,
      height: 17,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 1.594,
            top: 2.125,
            width: 13.813,
            height: 12.219,
            child: FittedBox(
              child: Icon(
                Icons.camera_alt,
                color: ReportProblemScreen._darkGreen,
              ),
            ),
          ),
          Positioned(
            left: 10.625,
            top: 9.917,
            child: Container(
              width: 6.375,
              height: 6.375,
              decoration: BoxDecoration(
                color: ReportProblemScreen._darkGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
          const Positioned(
            left: 12.042,
            top: 11.333,
            child: SizedBox(
              width: 3.542,
              height: 3.542,
              child: Stack(
                children: [
                  Positioned(
                    left: 1.271,
                    top: 0.738,
                    width: 1,
                    height: 2.066,
                    child: ColoredBox(color: Colors.white),
                  ),
                  Positioned(
                    left: 0.738,
                    top: 1.271,
                    width: 2.066,
                    height: 1,
                    child: ColoredBox(color: Colors.white),
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

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 53,
      decoration: const BoxDecoration(
        color: ReportProblemScreen._darkGreen,
        borderRadius: BorderRadius.all(Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(0, 22),
            blurRadius: 22,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 49),
            blurRadius: 29,
          ),
          BoxShadow(
            color: Color(0x03000000),
            offset: Offset(0, 87),
            blurRadius: 35,
          ),
          BoxShadow(
            color: Color(0x00000000),
            offset: Offset(0, 136),
            blurRadius: 38,
          ),
        ],
      ),
      child: const Stack(
        children: [
          Positioned(
            left: 156,
            top: 14,
            child: LabelText(
              'Submit',
              ReportProblemScreen._submitStyle,
              width: 50,
            ),
          ),
        ],
      ),
    );
  }
}
