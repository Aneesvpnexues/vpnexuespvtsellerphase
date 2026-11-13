import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';

/// Order Details — completed confirmation state. Replica of Zeplin
/// "Android Compact - 259".
///
/// This is the final page of the buyer-pickup flow: the seller reaches it only
/// after entering the correct 4-digit pickup code on the pickup-code state
/// (154). It shows the completed check, the wallet credit and a simple
/// "Back to orders" pill that returns to the My Orders tab.
///
/// Built against a 412x917 artboard, sharing the 154/165 header and segment
/// tabs. Geometry is measured from the design PNG at 2x.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

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
              children: const [
                Positioned(
                  left: 0,
                  top: 73,
                  child: PageHeader(title: 'Order Details'),
                ),
                Positioned(left: 22, top: 117, child: _SegmentTabs()),
                Positioned(left: 22, top: 201, child: _Divider()),
                Positioned(left: 125, top: 203.5, child: _SuccessBadge()),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 380,
                  child: _OrderCompleted(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 420,
                  child: _CollectedCaption(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 441,
                  child: _OrderReference(),
                ),
                Positioned(left: 22, top: 477.5, child: _WalletCard()),
                Positioned(left: 22, top: 834, child: _BackButton()),
              ],
            ),
          ),
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

class _Label extends StatelessWidget {
  const _Label(this.text, this.style, {required this.width});

  final String text;
  final TextStyle style;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 25,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: style, maxLines: 1, softWrap: false),
      ),
    );
  }
}

/// The faint hairline that separates the segment tabs from the completed
/// state, spanning the design's content width.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 368, height: 1, color: const Color(0xFFEFF1E4));
  }
}

/// Pale-lime outer rings with a dark-green disc and a lime check mark.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  static const double _size = 154;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: const [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFEDF6D1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 13,
            top: 13,
            child: SizedBox(
              width: 128,
              height: 128,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFE3F1CC),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            left: 26,
            top: 26,
            child: SizedBox(
              width: 102,
              height: 102,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.orderDark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _CheckPainter()),
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
      ..color = AppColors.orderDivider
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(61.5, 77.5)
      ..lineTo(71, 88)
      ..lineTo(93.5, 65.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderCompleted extends StatelessWidget {
  const _OrderCompleted();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Order completed',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 34 / 26,
          leadingDistribution: TextLeadingDistribution.even,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CollectedCaption extends StatelessWidget {
  const _CollectedCaption();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Akash Stores collected the order.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 18 / 14,
          leadingDistribution: TextLeadingDistribution.even,
          color: Color(0xFF7F8078),
        ),
      ),
    );
  }
}

class _OrderReference extends StatelessWidget {
  const _OrderReference();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 18 / 13,
            color: Color(0xFF7F8078),
          ),
          children: [
            TextSpan(text: 'Order '),
            TextSpan(
              text: '#NX4582',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: AppColors.orderIdGreen,
              ),
            ),
            TextSpan(text: ' \u00B7 3 items'),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 76,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B341B), Color(0xFF1E6A38)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.orderDivider,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const CustomPaint(
                size: Size(22, 18),
                painter: _WalletIconPainter(),
              ),
            ),
          ),
          const Positioned(
            left: 76,
            top: 15,
            child: Text(
              'Added to your wallet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 15 / 12,
                leadingDistribution: TextLeadingDistribution.even,
                color: Color(0xFF8FA89A),
              ),
            ),
          ),
          const Positioned(
            left: 76,
            top: 34,
            child: Text(
              '\u20B92,840',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 30 / 26,
                leadingDistribution: TextLeadingDistribution.even,
                color: AppColors.orderDivider,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletIconPainter extends CustomPainter {
  const _WalletIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.orderDark
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 6.5, size.height * 0.3),
      Offset(size.width - 6.5, size.height * 0.7),
      paint,
    );
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
      onTap: () => goToOrdersRoot(context),
      child: HoverPress.button(
        child: Container(
          width: 368,
          height: 58,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.orderDark,
            borderRadius: BorderRadius.all(Radius.circular(29)),
          ),
          child: const Text(
            'Back to orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: AppColors.orderDivider,
            ),
          ),
        ),
      ),
    );
  }
}
