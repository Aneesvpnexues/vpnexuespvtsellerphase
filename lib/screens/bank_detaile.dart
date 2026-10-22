import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import 'seller_home_screen.dart';

/// "Add your bank details" — static replica of Zeplin "Android Compact - 106"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1adb1cc78003f7066066b).
///
/// Built against a 412x936 artboard (the design's 44px top headroom removed).
/// The vegetable-basket illustration is the design PNG cropped to
/// x190..412 / y70..332; the white "STEP 04" label sits over foliage inside
/// that crop and is therefore baked into the asset (only "STEP 02" is rendered
/// here). The back arrow pops; Continue opens the home page
/// ([SellerHomeScreen]).
class BankDetaileScreen extends StatelessWidget {
  const BankDetaileScreen({super.key});

  static const String illustrationAsset = 'assets/bank/illustration.png';
  static const double designWidth = 412;
  static const double designHeight = 936;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Artboard(
            designWidth: designWidth,
            designHeight: designHeight,
            child: Stack(
              children: const [
                Positioned(left: 0, top: 0, child: _HeaderBackground()),
                // Sheet first: the illustration is drawn above it and
                // carries its own baked shadow along the seam, so the
                // sheet's BoxShadow is only visible left of the image
                // (no doubling).
                Positioned(left: 0, top: 287.5, child: _Sheet()),
                Positioned(left: 190, top: 26, child: _Illustration()),
                Positioned(left: 21, top: 30, child: _BackButton()),
                Positioned(left: 25, top: 89.13, child: _StepLabel()),
                Positioned(left: 25, top: 118.75, child: _ProgressTrack()),
                Positioned(left: 24, top: 141.79, child: _TitleLead()),
                Positioned(left: 24, top: 175.80, child: _TitleAccent()),
                Positioned(left: 25, top: 218.12, child: _Subtitle()),
                // Bank details section row.
                Positioned(left: 27, top: 319, child: _SectionTick()),
                Positioned(left: 41, top: 319.45, child: _SectionTitle()),
                Positioned(left: 261, top: 313, child: _PillNote()),
                Positioned(left: 26, top: 350, child: _Divider()),
                // Card 1 — Account Holder Name (active: soft shadow).
                Positioned(left: 25, top: 363, child: _CardActive()),
                Positioned(left: 36, top: 378, child: _TilePerson()),
                Positioned(left: 81, top: 381.81, child: _LabelName()),
                Positioned(left: 81, top: 402, child: _InputName()),
                Positioned(left: 90.5, top: 415.99, child: _InputTextName()),
                // Card 2 — Bank Name (dropdown).
                Positioned(left: 25, top: 467, child: _CardBank()),
                Positioned(left: 36, top: 482, child: _TileBank()),
                Positioned(left: 81, top: 485.81, child: _LabelBank()),
                Positioned(left: 81, top: 506, child: _InputBank()),
                Positioned(left: 90.5, top: 520.10, child: _InputTextBank()),
                Positioned(left: 348, top: 521, child: _ChevronDown()),
                // Card 3 — Account Number.
                Positioned(left: 25, top: 571, child: _CardAccount()),
                Positioned(left: 36, top: 586, child: _TileAccount()),
                Positioned(left: 81, top: 589.81, child: _LabelAccount()),
                Positioned(left: 81, top: 610, child: _InputAccount()),
                Positioned(left: 90.5, top: 623.67, child: _InputTextAccount()),
                // Card 4 — IFSC Code + Verify button.
                Positioned(left: 25, top: 675, child: _CardIfsc()),
                Positioned(left: 36, top: 690, child: _TileIfsc()),
                Positioned(left: 81, top: 692.81, child: _LabelIfsc()),
                Positioned(left: 81, top: 714, child: _InputIfsc()),
                Positioned(left: 90.5, top: 727.99, child: _InputTextIfsc()),
                Positioned(left: 301, top: 713.5, child: _VerifyButton()),
                // Security banner.
                Positioned(left: 25, top: 793, child: _Banner()),
                Positioned(left: 36, top: 807, child: _Shield()),
                Positioned(left: 80.5, top: 808.94, child: _BannerTitle()),
                Positioned(left: 80.5, top: 827.99, child: _BannerBody()),
              ],
            ),
          ),
          // Anchored to the physical screen bottom so it stays there on
          // taller devices; on the 936-tall artboard this matches the
          // design offset (980 - 44 - 54 - 16 = 866).
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 10, right: 10),
              child: SizedBox(height: 54, child: const _ContinueButton()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BankDetaileScreen.designWidth,
      height: 386,
      color: AppColors.bankPageBg,
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BankDetaileScreen.illustrationAsset,
      width: 222,
      height: 262,
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
      child: const Icon(
        Icons.arrow_back,
        size: 22,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return const Text('STEP 02', style: AppTextStyles.stepLabelMuted);
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _Segment(width: 29.5, color: AppColors.progressTrack),
        SizedBox(width: 7),
        _Segment(width: 42.5, color: AppColors.progressActive),
        SizedBox(width: 6.5),
        _Segment(width: 29.5, color: AppColors.progressTrack),
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

class _TitleLead extends StatelessWidget {
  const _TitleLead();

  @override
  Widget build(BuildContext context) {
    return const Text('Add your', style: AppTextStyles.heading);
  }
}

class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  @override
  Widget build(BuildContext context) {
    // "bank details" filled with a horizontal green gradient
    // (#00B013 -> #02590B) measured across the design's heading ink.
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppColors.bankHeadingGreenStart,
          AppColors.bankHeadingGreenEnd,
        ],
      ).createShader(bounds),
      child: const Text('bank details', style: AppTextStyles.heading),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'To receive your earnings',
      style: AppTextStyles.bankSubtitle,
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BankDetaileScreen.designWidth,
      height: BankDetaileScreen.designHeight - 287.5,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
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

class _SectionTick extends StatelessWidget {
  const _SectionTick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 16.5,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bankTickStart,
            AppColors.bankTickMid,
            AppColors.bankTickEnd,
          ],
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
    return const Text(
      'Fill Your Bank Details',
      style: AppTextStyles.bankSectionTitle,
    );
  }
}

class _PillNote extends StatelessWidget {
  const _PillNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126.5,
      height: 27.5,
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
    return Container(width: 362, height: 1, color: AppColors.docDivider);
  }
}

class _Card extends StatelessWidget {
  const _Card({this.shadow = false});

  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 93,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.docCardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
    );
  }
}

class _CardActive extends StatelessWidget {
  const _CardActive();

  @override
  Widget build(BuildContext context) => const _Card(shadow: true);
}

class _CardBank extends StatelessWidget {
  const _CardBank();

  @override
  Widget build(BuildContext context) => const _Card();
}

class _CardAccount extends StatelessWidget {
  const _CardAccount();

  @override
  Widget build(BuildContext context) => const _Card();
}

class _CardIfsc extends StatelessWidget {
  const _CardIfsc();

  @override
  Widget build(BuildContext context) => const _Card();
}

class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _TilePerson extends StatelessWidget {
  const _TilePerson();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileName,
      child: SizedBox(
        width: 12.5,
        height: 16.5,
        child: CustomPaint(
          painter: _PersonIconPainter(color: AppColors.fieldIconName),
        ),
      ),
    );
  }
}

class _TileBank extends StatelessWidget {
  const _TileBank();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileBusiness,
      child: SizedBox(
        width: 16.5,
        height: 15.5,
        child: CustomPaint(
          painter: _BankIconPainter(color: AppColors.fieldIconBusiness),
        ),
      ),
    );
  }
}

class _TileAccount extends StatelessWidget {
  const _TileAccount();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTilePhone,
      child: SizedBox(
        width: 19.5,
        height: 15.5,
        child: CustomPaint(
          painter: _CardDotsPainter(color: AppColors.fieldIconPhone),
        ),
      ),
    );
  }
}

class _TileIfsc extends StatelessWidget {
  const _TileIfsc();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileLocation,
      child: SizedBox(
        width: 15.5,
        height: 11.5,
        child: CustomPaint(
          painter: _CardChipPainter(color: AppColors.fieldIconLocation),
        ),
      ),
    );
  }
}

/// Filled person glyph traced from the design (12.5x16.5 ink): circle head
/// over a rounded-bottom body.
class _PersonIconPainter extends CustomPainter {
  const _PersonIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 12.5;
    final fill = Paint()..color = color;
    canvas.drawCircle(Offset(6.25 * s, 3.9 * s), 3.75 * s, fill);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 10 * s, 12.5 * s, 6.5 * s),
        topLeft: Radius.circular(0.5 * s),
        topRight: Radius.circular(0.5 * s),
        bottomLeft: Radius.circular(3 * s),
        bottomRight: Radius.circular(3 * s),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_PersonIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Outline bank glyph traced from the design (16.5x15.5 ink): pediment with a
/// center dot, entablature, four columns, base.
class _BankIconPainter extends CustomPainter {
  const _BankIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 16.5;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final roof = Path()
      ..moveTo(8.2 * s, 1.2 * s)
      ..lineTo(1.1 * s, 5.3 * s)
      ..lineTo(15.4 * s, 5.3 * s);
    canvas.drawPath(roof, stroke);
    canvas.drawCircle(Offset(7.9 * s, 3.7 * s), 0.85 * s, fill);
    canvas.drawLine(
      Offset(0.9 * s, 6.7 * s),
      Offset(15.6 * s, 6.7 * s),
      stroke,
    );
    for (final x in [1.0, 6.0, 9.0, 13.0]) {
      canvas.drawRect(Rect.fromLTWH(x * s, 8 * s, 2 * s, 6 * s), fill);
    }
    final base = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0.9 * s, 14.7 * s),
      Offset(15.6 * s, 14.7 * s),
      base,
    );
  }

  @override
  bool shouldRepaint(_BankIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Credit-card glyph traced from the design (19.5x15.5 ink): outline, stripe
/// across the upper third, small dot + pill below.
class _CardDotsPainter extends CustomPainter {
  const _CardDotsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 19.5;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1 * s, 1 * s, 17.5 * s, 13.5 * s),
        Radius.circular(3 * s),
      ),
      stroke,
    );
    canvas.drawLine(
      Offset(1.5 * s, 5.75 * s),
      Offset(18 * s, 5.75 * s),
      stroke,
    );
    canvas.drawCircle(Offset(5.1 * s, 10.7 * s), 0.9 * s, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8.5 * s, 9.9 * s, 3.1 * s, 1.9 * s),
        Radius.circular(0.95 * s),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_CardDotsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Card glyph traced from the design (15.5x11.5 ink): outline, stripe across
/// the lower middle, small filled chip top-right.
class _CardChipPainter extends CustomPainter {
  const _CardChipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 15.5;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.9 * s, 0.9 * s, 13.7 * s, 9.7 * s),
        Radius.circular(2.5 * s),
      ),
      stroke,
    );
    canvas.drawLine(
      Offset(1.3 * s, 7.5 * s),
      Offset(14.2 * s, 7.5 * s),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(11 * s, 3 * s, 2.4 * s, 1.9 * s),
        Radius.circular(0.4 * s),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_CardChipPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LabelName extends StatelessWidget {
  const _LabelName();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Account Holder Name',
      style: AppTextStyles.bankFieldLabel,
    );
  }
}

class _LabelBank extends StatelessWidget {
  const _LabelBank();

  @override
  Widget build(BuildContext context) {
    return const Text('Bank Name', style: AppTextStyles.bankFieldLabel);
  }
}

class _LabelAccount extends StatelessWidget {
  const _LabelAccount();

  @override
  Widget build(BuildContext context) {
    return const Text('Account Number', style: AppTextStyles.bankFieldLabel);
  }
}

class _LabelIfsc extends StatelessWidget {
  const _LabelIfsc();

  @override
  Widget build(BuildContext context) {
    return const Text('IFSC Code', style: AppTextStyles.bankFieldLabel);
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 35.5,
      decoration: BoxDecoration(
        color: AppColors.welcomeBg,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _InputName extends StatelessWidget {
  const _InputName();

  @override
  Widget build(BuildContext context) => const _Input(width: 291.5);
}

class _InputBank extends StatelessWidget {
  const _InputBank();

  @override
  Widget build(BuildContext context) => const _Input(width: 291.5);
}

class _InputAccount extends StatelessWidget {
  const _InputAccount();

  @override
  Widget build(BuildContext context) => const _Input(width: 291.5);
}

class _InputIfsc extends StatelessWidget {
  const _InputIfsc();

  @override
  Widget build(BuildContext context) => const _Input(width: 212.5);
}

class _InputTextName extends StatelessWidget {
  const _InputTextName();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Name should match your bank account',
      style: AppTextStyles.bankInputText,
    );
  }
}

class _InputTextBank extends StatelessWidget {
  const _InputTextBank();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'State Bank of India',
      style: AppTextStyles.bankInputText,
    );
  }
}

class _InputTextAccount extends StatelessWidget {
  const _InputTextAccount();

  @override
  Widget build(BuildContext context) {
    return const Text('1234 5678 9012', style: AppTextStyles.bankInputText);
  }
}

class _InputTextIfsc extends StatelessWidget {
  const _InputTextIfsc();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Enter 11-digit code',
      style: AppTextStyles.bankInputText,
    );
  }
}

class _ChevronDown extends StatelessWidget {
  const _ChevronDown();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 11.5,
      height: 6.5,
      child: CustomPaint(
        painter: _ChevronPainter(color: AppColors.verifiedText),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 11.5;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(0.9 * s, 0.9 * s)
      ..lineTo(5.75 * s, 5.4 * s)
      ..lineTo(10.6 * s, 0.9 * s);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 73.5,
      height: 37,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.verifiedText),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Text('Verify', style: AppTextStyles.bankVerifyText),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 61,
      decoration: BoxDecoration(
        color: AppColors.bankBannerBg,
        border: Border.all(color: AppColors.bankBannerBorder),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _Shield extends StatelessWidget {
  const _Shield();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.bankShieldCircle,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(
        width: 18,
        height: 21.5,
        child: CustomPaint(painter: _ShieldPainter()),
      ),
    );
  }
}

/// Solid shield with a white check, traced from the banner glyph (18x21.5).
class _ShieldPainter extends CustomPainter {
  const _ShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 18;
    final shield = Path()
      ..moveTo(0, 4.2 * s)
      ..quadraticBezierTo(0, 0, 9 * s, 0)
      ..quadraticBezierTo(18 * s, 0, 18 * s, 4.2 * s)
      ..lineTo(18 * s, 12 * s)
      ..quadraticBezierTo(18 * s, 15.6 * s, 9 * s, 21.5 * s)
      ..quadraticBezierTo(0, 15.6 * s, 0, 12 * s)
      ..close();
    canvas.drawPath(shield, Paint()..color = AppColors.bankShield);
    final check = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(5 * s, 11 * s)
      ..lineTo(6.8 * s, 13.4 * s)
      ..lineTo(13.5 * s, 7 * s);
    canvas.drawPath(checkPath, check);
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) => false;
}

class _BannerTitle extends StatelessWidget {
  const _BannerTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Your information is safe with us.',
      style: AppTextStyles.bankBannerTitle,
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'We use bank-grade security to protect your details.',
      style: AppTextStyles.bankBannerBody,
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SellerHomeScreen()),
        (route) => false,
      ),
      child: Container(
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
