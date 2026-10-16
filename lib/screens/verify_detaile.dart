import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'bank_detaile.dart';

/// "Verify your details" — static replica of Zeplin "Android Compact - 84"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1adb13fd164a524fed4e6).
///
/// Built against a 412x873 artboard (the design's 44px top headroom removed).
/// Every offset below is taken straight from
/// the design PNG, so on a matching viewport the layout renders 1:1; on other
/// sizes it scales down uniformly instead of overflowing. The back arrow pops
/// the route; cards are visual only; Continue opens [BankDetaileScreen].
class VerifyDetaileScreen extends StatelessWidget {
  const VerifyDetaileScreen({super.key});

  static const String illustrationAsset = 'assets/verify/illustration.png';
  static const double designWidth = 412;
  static const double designHeight = 873;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: designWidth,
                  height: designHeight,
                  child: Stack(
                    children: const [
                      Positioned(left: 0, top: 0, child: _HeaderBackground()),
                      Positioned(left: 200, top: 0, child: _Illustration()),
                      Positioned(left: 21, top: 30, child: _BackButton()),
                      Positioned(right: 22.5, top: 34.63, child: _StepLabel()),
                      Positioned(left: 24, top: 99.15, child: _TitleLead()),
                      Positioned(left: 24, top: 134.79, child: _TitleAccent()),
                      Positioned(left: 24, top: 180.74, child: _Subtitle()),
                      Positioned(left: 23, top: 209.75, child: _ProgressTrack()),
                      Positioned(left: 0, top: 342, child: _Sheet()),
                      // Profile completion card.
                      Positioned(left: 24, top: 367, child: _PcCard()),
                      Positioned(left: 34.5, top: 381.4, child: _PcLabel()),
                      Positioned(right: 40, top: 384.37, child: _PcPercent()),
                      Positioned(left: 34, top: 406, child: _PcBar()),
                      // Verification details section.
                      Positioned(left: 26, top: 452, child: _SectionTick()),
                      Positioned(left: 40.5, top: 452.07, child: _SectionTitle()),
                      Positioned(left: 260, top: 447, child: _PillNote()),
                      Positioned(left: 25, top: 483, child: _Divider()),
                      // Document cards.
                      Positioned(left: 23, top: 497, child: _CardAadhaar()),
                      Positioned(left: 34, top: 508, child: _TileAadhaar()),
                      Positioned(left: 89, top: 510.62, child: _TitleAadhaar()),
                      Positioned(left: 89, top: 532.94, child: _SubAadhaar()),
                      Positioned(right: 41, top: 519, child: _Chevron()),
                      Positioned(left: 23, top: 573, child: _CardPan()),
                      Positioned(left: 34, top: 585, child: _TilePan()),
                      Positioned(left: 89, top: 587.12, child: _TitlePan()),
                      Positioned(left: 89, top: 609.81, child: _SubPan()),
                      Positioned(right: 41, top: 595, child: _Chevron()),
                      Positioned(left: 23, top: 650, child: _CardBusiness()),
                      Positioned(left: 34, top: 661, child: _TileBusiness()),
                      Positioned(left: 89, top: 663.43, child: _TitleBusiness()),
                      Positioned(left: 89, top: 686.49, child: _SubBusiness()),
                      Positioned(right: 41, top: 672, child: _Chevron()),
                    ],
                  ),
                ),
              ),
            ),
            // Anchored to the physical screen bottom so it stays there on
            // taller devices; on the 873-tall artboard this matches the
            // design offset (873 - 54 - 16 = 803).
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: 364,
                  height: 54,
                  child: const _ContinueButton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VerifyDetaileScreen.designWidth,
      height: 386,
      color: AppColors.verifyPageBg,
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      VerifyDetaileScreen.illustrationAsset,
      width: 212,
      height: 318,
      fit: BoxFit.fill,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: const Icon(Icons.arrow_back, size: 22, color: AppColors.textPrimary),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return const Text('STEP 03', style: AppTextStyles.stepLabel);
  }
}

class _TitleLead extends StatelessWidget {
  const _TitleLead();

  @override
  Widget build(BuildContext context) {
    return const Text('Verify your', style: AppTextStyles.heading);
  }
}

class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  @override
  Widget build(BuildContext context) {
    return const Text('details', style: AppTextStyles.headingMint);
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text('A quick verification',
        style: AppTextStyles.verifySubtitle);
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _Segment(width: 30, color: AppColors.progressInactive),
        SizedBox(width: 7),
        _Segment(width: 43, color: AppColors.verifyAccent),
        SizedBox(width: 6),
        _Segment(width: 30, color: AppColors.progressInactive),
        SizedBox(width: 6),
        _Segment(width: 30, color: AppColors.progressInactive),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VerifyDetaileScreen.designWidth,
      height: VerifyDetaileScreen.designHeight - 342,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
    );
  }
}

class _PcCard extends StatelessWidget {
  const _PcCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 61,
      decoration: BoxDecoration(
        color: AppColors.pcCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _PcLabel extends StatelessWidget {
  const _PcLabel();

  @override
  Widget build(BuildContext context) {
    return const Text('Profile Completion', style: AppTextStyles.pcLabel);
  }
}

class _PcPercent extends StatelessWidget {
  const _PcPercent();

  @override
  Widget build(BuildContext context) {
    return const Text('75%', style: AppTextStyles.pcPercent);
  }
}

class _PcBar extends StatelessWidget {
  const _PcBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 338,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.pcTrack,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 253.5,
          height: 8,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.pcFillStart, AppColors.pcFillEnd],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _SectionTick extends StatelessWidget {
  const _SectionTick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 15.5,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.verifyTickStart, AppColors.verifyTickEnd],
        ),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Text('Verification Details',
        style: AppTextStyles.verifySectionTitle);
  }
}

class _PillNote extends StatelessWidget {
  const _PillNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 127,
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.verifyPillBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      // Scales the note down under the Ahem test font (glyphs render one em
      // wide there); with bundled Roboto on device it renders 1:1.
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'All fiedls are required',
          style: AppTextStyles.verifyPillNote,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 1,
      color: AppColors.docDivider,
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 62,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.docCardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _CardAadhaar extends StatelessWidget {
  const _CardAadhaar();

  @override
  Widget build(BuildContext context) => const _DocCard();
}

class _CardPan extends StatelessWidget {
  const _CardPan();

  @override
  Widget build(BuildContext context) => const _DocCard();
}

class _CardBusiness extends StatelessWidget {
  const _CardBusiness();

  @override
  Widget build(BuildContext context) => const _DocCard();
}

class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _TileAadhaar extends StatelessWidget {
  const _TileAadhaar();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileName,
      child: Icon(Icons.credit_card, size: 24, color: AppColors.fieldIconName),
    );
  }
}

class _TilePan extends StatelessWidget {
  const _TilePan();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileBusiness,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _PentagonNotePainter(color: AppColors.fieldIconBusiness)),
      ),
    );
  }
}

class _TileBusiness extends StatelessWidget {
  const _TileBusiness();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTilePhone,
      child: SizedBox(
        width: 19,
        height: 16,
        child: CustomPaint(painter: _ContactCardPainter(color: AppColors.fieldIconPhone)),
      ),
    );
  }
}

/// Rounded pentagon "note" glyph traced from the design (22x22 ink).
class _PentagonNotePainter extends CustomPainter {
  const _PentagonNotePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 22;
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(3.5 * s, 2 * s)
      ..lineTo(13.5 * s, 2 * s)
      ..lineTo(20 * s, 9 * s)
      ..lineTo(20 * s, 17.5 * s)
      ..quadraticBezierTo(20 * s, 20 * s, 17.5 * s, 20 * s)
      ..lineTo(4 * s, 20 * s)
      ..quadraticBezierTo(1 * s, 20 * s, 1 * s, 17 * s)
      ..lineTo(1 * s, 9 * s)
      ..close();
    canvas.drawPath(path, outer);
    final inner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5.5 * s, 10.5 * s, 10 * s, 7 * s),
        Radius.circular(3 * s),
      ),
      inner,
    );
  }

  @override
  bool shouldRepaint(_PentagonNotePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Contact-card glyph (rounded rect, person, two lines) traced from the
/// design (19x16 ink).
class _ContactCardPainter extends CustomPainter {
  const _ContactCardPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 19;
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5 * s, 1 * s, 16.5 * s, 13.5 * s),
        Radius.circular(2.5 * s),
      ),
      outer,
    );
    final inner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(6.25 * s, 7.25 * s), 2 * s, inner);
    final shoulders = Path()
      ..moveTo(4 * s, 12 * s)
      ..quadraticBezierTo(6.5 * s, 9.6 * s, 9 * s, 12 * s);
    canvas.drawPath(shoulders, inner);
    canvas.drawLine(Offset(12 * s, 6 * s), Offset(15.2 * s, 6 * s), inner);
    canvas.drawLine(Offset(12 * s, 9 * s), Offset(15.2 * s, 9 * s), inner);
  }

  @override
  bool shouldRepaint(_ContactCardPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TitleAadhaar extends StatelessWidget {
  const _TitleAadhaar();

  @override
  Widget build(BuildContext context) {
    return const Text('Aadhaar card', style: AppTextStyles.docCardTitle);
  }
}

class _SubAadhaar extends StatelessWidget {
  const _SubAadhaar();

  @override
  Widget build(BuildContext context) {
    return const Text('For individual farmers',
        style: AppTextStyles.docCardSubtitle);
  }
}

class _TitlePan extends StatelessWidget {
  const _TitlePan();

  @override
  Widget build(BuildContext context) {
    return const Text('PAN Card', style: AppTextStyles.docCardTitle);
  }
}

class _SubPan extends StatelessWidget {
  const _SubPan();

  @override
  Widget build(BuildContext context) {
    return const Text('For businesses / traders',
        style: AppTextStyles.docCardSubtitle);
  }
}

class _TitleBusiness extends StatelessWidget {
  const _TitleBusiness();

  @override
  Widget build(BuildContext context) {
    return const Text('Business Registration',
        style: AppTextStyles.docCardTitle);
  }
}

class _SubBusiness extends StatelessWidget {
  const _SubBusiness();

  @override
  Widget build(BuildContext context) {
    return const Text('FSSAI / Udyam / GST (if available)',
        style: AppTextStyles.docCardSubtitle);
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.keyboard_arrow_down,
      size: 18,
      color: AppColors.verifiedText,
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BankDetaileScreen()),
      ),
      child: Container(
        width: 364,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.continueGradientStart,
              AppColors.continueGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.continueGlow,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Text('Continue', style: AppTextStyles.button),
      ),
    );
  }
}
