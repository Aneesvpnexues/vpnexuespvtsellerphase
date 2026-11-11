import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/seller_backend_sync.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/hover_press.dart';
import '../widgets/keyboard_aware_canvas.dart';
import 'seller_type_screen.dart';

/// "STEP 01 — Is this your location?" — static replica of Zeplin
/// "Android Compact - 261".
///
/// Sits between [Step01LocationScreen] and [Step02SellerTypeScreen]: the map
/// pin can be nudged, the address card can send the seller back, and
/// "Confirm location" saves the location before continuing to STEP 02.
///
/// Built against a 412x917 artboard, so every offset below is taken straight
/// from the design PNG.
class LocationConfirmScreen extends StatelessWidget {
  const LocationConfirmScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: KeyboardAwareCanvas(
        designWidth: designWidth,
        designHeight: designHeight,
        child: Stack(
          children: const [
            Positioned(left: -94.2, top: -159.5, child: _PaleBlob()),
            Positioned(right: 29, top: 76, child: _StepLabel()),
            Positioned(left: 25, top: 113.5, child: _Title()),
            Positioned(left: 25, top: 151, child: _Subtitle()),
            Positioned(left: 28, top: 247, child: _MapCard()),
            Positioned(left: 24, top: 561, child: _LocationCard()),
            Positioned(left: 24, top: 731, child: _ConfirmButton()),
          ],
        ),
      ),
    );
  }
}

class _PaleBlob extends StatelessWidget {
  const _PaleBlob();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.paleCircle,
            AppColors.paleCircle,
            Color(0xFFE5F8EA),
          ],
          stops: [0, 0.55, 1],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return const Text('STEP 01', style: AppTextStyles.stepLabel);
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Is this your location?',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Move the map if the pin isn’t exact, Buyers\n'
      'use this to find you.',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 22 / 17,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('locationMapCard'),
      width: 360,
      height: 283,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x99FFFFFF), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: const [
            Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Positioned(left: 9, top: 22, child: _DragPill()),
            Positioned(left: 300, top: 245, child: _RecenterButton()),
          ],
        ),
      ),
    );
  }
}

class _DragPill extends StatelessWidget {
  const _DragPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      height: 24,
      padding: const EdgeInsets.only(left: 10, right: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(
            Icons.location_on_outlined,
            size: 11,
            color: Color(0xFF3E9B4E),
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Drag the map to adjust',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 11,
              height: 1,
              color: Color(0xFF6B6C6E),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: HoverPress.icon(
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
            size: 15,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('locationCard'),
      width: 364,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2F3F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 11.5,
            child: Container(
              width: 23,
              height: 23,
              decoration: const BoxDecoration(
                color: Color(0xFFE4F4E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: Color(0xFF3E9B4E),
              ),
            ),
          ),
          const Positioned(
            left: 59,
            top: 7,
            child: Text(
              'Your location',
              style: TextStyle(
                fontSize: 9,
                height: 1,
                color: Color(0xFF9A9B9D),
              ),
            ),
          ),
          const Positioned(
            left: 59,
            top: 15.5,
            child: Text(
              'Salem, Tamil Nadu',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1,
                color: Color(0xFF707173),
              ),
            ),
          ),
          const Positioned(
            left: 59,
            top: 28,
            child: Text(
              'Fairlands, Salem · 636016',
              style: TextStyle(
                fontSize: 9,
                height: 1,
                color: Color(0xFFB0B1B3),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: const Text(
                'Change',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton();

  void _confirm(BuildContext context) {
    unawaited(SellerBackendSync.saveLocation());
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step02SellerTypeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _confirm(context),
      child: HoverPress.button(
        child: Container(
          key: const Key('confirmLocationButton'),
          width: 364,
          height: 54,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1C000000),
                blurRadius: 120,
                offset: Offset(0, 30),
              ),
            ],
          ),
          child: const Text(
            'Confirm location',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0.2,
              color: AppColors.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  static const Color _fill = Color(0xFFEDF3E6);
  static const Color _block = Color(0xFFE1E7D6);
  static const Color _road = Color(0xFFFFFFFF);
  static const Color _water = Color(0xFFD3E6EC);
  static const Color _yellow = Color(0xFFF7E39A);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..isAntiAlias = true;

    paint.color = _fill;
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = _block;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 360, 7), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(282, 75, 60, 50),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(282, 153, 60, 45),
        const Radius.circular(7),
      ),
      paint,
    );

    paint.color = _water;
    canvas.drawRect(const Rect.fromLTWH(0, 228, 360, 55), paint);

    paint.color = const Color(0xFFE7F0E8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 240, 128, 32),
        const Radius.circular(8),
      ),
      paint,
    );
    paint.color = _block;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(63, 240, 104, 32),
        const Radius.circular(8),
      ),
      paint,
    );
    paint.color = _road;
    canvas.drawRect(const Rect.fromLTWH(63, 240, 5, 32), paint);

    paint.color = _road;
    canvas.drawRect(const Rect.fromLTWH(43, 0, 11.5, 228), paint);
    canvas.drawRect(const Rect.fromLTWH(229.5, 0, 8.5, 283), paint);
    canvas.drawRect(const Rect.fromLTWH(0, 219, 360, 9), paint);

    paint.color = const Color(0xFFFBF6E2);
    canvas.drawRect(const Rect.fromLTWH(0, 37, 360, 13), paint);
    paint.color = _yellow;
    canvas.drawRect(const Rect.fromLTWH(0, 39, 360, 9), paint);

    paint.color = const Color(0x38C9E2C0);
    canvas.drawCircle(const Offset(179, 134), 58, paint);
    paint
      ..color = const Color(0x33A9C99A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(const Offset(179, 134), 58, paint);
    paint.style = PaintingStyle.fill;

    _paintLabel(
      canvas,
      'Fairlands',
      const Offset(263, 121),
      const Color(0xFFB0B8AC),
      9,
    );
    _paintRotatedLabel(
      canvas,
      'Gandhi Rd',
      const Offset(141, 141),
      const Color(0xFFA9B0A5),
      9,
    );

    _paintPin(canvas);
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double fontSize,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  void _paintRotatedLabel(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double fontSize,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(-math.pi / 2);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _paintPin(Canvas canvas) {
    const double cx = 177;
    const double cy = 98;
    const double radius = 18;
    const double tip = 135;

    final Path pin = Path()
      ..moveTo(cx, tip)
      ..cubicTo(cx - 6, 122, cx - radius, 114, cx - radius, cy)
      ..arcToPoint(
        Offset(cx + radius, cy),
        radius: const Radius.circular(radius),
        clockwise: true,
      )
      ..cubicTo(cx + radius, 114, cx + 6, 122, cx, tip)
      ..close();

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(cx, tip + 4),
        width: 24,
        height: 5,
      ),
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawPath(
      pin,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF6DC6B),
            Color(0xFFEFD264),
            Color(0xFF8FBF55),
            Color(0xFF3E9B4E),
          ],
          stops: [0, 0.4, 0.62, 0.9],
        ).createShader(const Rect.fromLTRB(cx - radius, 80, cx + radius, tip)),
    );

    final RRect square = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(cx, cy),
        width: 26,
        height: 26,
      ),
      const Radius.circular(7),
    );
    canvas.drawRRect(square, Paint()..color = AppColors.surface);

    final Paint glyph = Paint()..color = const Color(0xFF3E9B4E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(cx, cy),
          width: 14,
          height: 14,
        ),
        const Radius.circular(2.5),
      ),
      glyph,
    );
    final Paint glyphWhite = Paint()..color = AppColors.surface;
    canvas.drawCircle(const Offset(cx, cy - 1.2), 2.6, glyphWhite);
    final Path glyphTail = Path()
      ..moveTo(cx - 2.1, cy + 0.6)
      ..lineTo(cx + 2.1, cy + 0.6)
      ..lineTo(cx, cy + 3.4)
      ..close();
    canvas.drawPath(glyphTail, glyphWhite);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}
