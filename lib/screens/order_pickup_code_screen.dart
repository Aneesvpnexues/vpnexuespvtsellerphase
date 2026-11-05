import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/page_header.dart';
import '../widgets/slide_drag_detector.dart';

/// Order Details ΓÇö pickup code entry state. Replica of Zeplin
/// "Android Compact - 154".
///
/// The four code boxes accept a demo code that is shared by every order and
/// user: [demoCode]. When the entered code does not match, the boxes turn red,
/// show an error line and clear; the slide CTA is locked until four digits are
/// present.
class OrderPickupCodeScreen extends StatefulWidget {
  const OrderPickupCodeScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
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
      goToOrderPickupSuccess(context);
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
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Roboto'),
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 73,
                  child: PageHeader(title: 'Order Details'),
                ),
                const Positioned(left: 22, top: 117, child: _SegmentTabs()),
                const Positioned(left: 25, top: 172, child: _HeroCard()),
                Positioned(
                  left: 25,
                  top: 359,
                  child: _CodeCard(
                    controller: _code,
                    focusNode: _codeFocus,
                    error: _error,
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 847,
                  child: _ContinueButton(locked: !_complete, onSubmit: _submit),
                ),
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
              child: const Text(
                'Buyer Pickup',
                style: AppTextStyles.orderSegmentActiveOnDark,
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
  const _CodeCard({
    required this.controller,
    required this.focusNode,
    required this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool error;

  static const List<double> _boxLefts = <double>[0, 69, 137, 205];

  @override
  Widget build(BuildContext context) {
    final String value = controller.text;
    return Container(
      width: 362,
      height: 317,
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
                    0,
                    0,
                    0,
                    0,
                    13,
                    0,
                    0,
                    0,
                    0,
                    59,
                    0,
                    0,
                    0,
                    0,
                    32,
                    0,
                    8,
                    0,
                    0,
                    -1200,
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
          const Positioned(
            left: 22,
            top: 117,
            child: _Label(
              'Pickup code',
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7F8078),
              ),
              width: 90,
              height: 16,
            ),
          ),
          Positioned(
            key: const Key('pickup-code-hint'),
            left: 208,
            top: 110,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _CodeHintBox(character: OrderPickupCodeScreen.demoCode[i]),
                ],
              ],
            ),
          ),
          Positioned(
            left: 79,
            top: 173,
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
            top: 202.5,
            child: _Label(
              'Ask the buyer for the 4-digital code shown in their app',
              TextStyle(fontSize: 12, color: Color(0xFF858585)),
              width: 300,
              height: 16,
            ),
          ),
          Positioned(
            left: 53,
            top: 231,
            width: 259,
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
                  width: 259,
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
            const Positioned(
              left: 53,
              top: 295,
              width: 258,
              height: 14,
              child: _Label(
                'Incorrect code. Try again.',
                TextStyle(
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

class _CodeHintBox extends StatelessWidget {
  const _CodeHintBox({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: const Color(0xFFDFE3E8)),
      ),
      child: Text(
        character,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({required this.locked, required this.onSubmit});

  final bool locked;
  final bool Function() onSubmit;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
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
    return SlideDragDetector(
      onTap: widget.locked
          ? null
          : () {
              if (widget.onSubmit()) {
                setState(() => _knobX = _end);
              }
            },
      onUpdate: _onDragUpdate,
      onEnd: _onDragEnd,
      child: AnimatedContainer(
        key: const Key('pickup-slide-bar'),
        duration: const Duration(milliseconds: 200),
        width: 368,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(29)),
          gradient: LinearGradient(
            colors: widget.locked
                ? const [Color(0xFF607E6A), Color(0xFF71CA93)]
                : const [Color(0xFF4FC96F), Color(0xFF2FBF71)],
          ),
          border: Border.all(color: const Color(0x14000000)),
          boxShadow: widget.locked
              ? null
              : const [BoxShadow(color: Color(0x40C6E96D), blurRadius: 14)],
        ),
        child: Stack(
          children: [
            Positioned(
              left: _knobX,
              top: 4,
              child: AnimatedContainer(
                key: const Key('pickup-slide-knob'),
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.locked
                      ? const Color(0xFF9EC463)
                      : const Color(0xFFC6E96D),
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
