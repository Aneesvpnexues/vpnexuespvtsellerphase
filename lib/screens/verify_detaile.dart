import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import 'bank_detaile.dart';

typedef DocumentPicker = Future<PickedDocument?> Function();

/// A document selected from the device's file browser.
class PickedDocument {
  const PickedDocument({required this.name, this.path});

  final String name;
  final String? path;

  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}

enum _DocumentSlot { aadhaar, pan, business }

/// "Verify your details" — replica of Zeplin "Android Compact - 84"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1adb13fd164a524fed4e6).
///
/// Built against a 412x873 artboard (the design's 44px top headroom removed).
/// Every offset below is taken straight from
/// the design PNG, so on a matching viewport the layout renders 1:1; on other
/// sizes the [Artboard] viewport scales it down on small screens and up (capped
/// at 1.5x) on large ones instead of overflowing. The back arrow pops
/// the route; each document card opens the system file browser for an image or
/// PDF (picks are held in memory only — no backend exists yet); the "Profile
/// Completion" card is computed from the filled slots; Continue requires the
/// Aadhaar document and opens [BankDetaileScreen].
class VerifyDetaileScreen extends StatefulWidget {
  const VerifyDetaileScreen({super.key, this.documentPicker});

  final DocumentPicker? documentPicker;

  static const String illustrationAsset = 'assets/verify/illustration.png';
  static const double designWidth = 412;
  static const double designHeight = 873;

  @override
  State<VerifyDetaileScreen> createState() => _VerifyDetaileScreenState();
}

class _VerifyDetaileScreenState extends State<VerifyDetaileScreen> {
  final Map<_DocumentSlot, PickedDocument> _documents = {};
  _DocumentSlot? _pickingSlot;

  /// How many of the three document slots are filled, as a percentage shown
  /// on the "Profile Completion" card (0 -> 0%, 1 -> 33%, 2 -> 67%, 3 -> 100%).
  int get _completionPercent {
    const int slots = 3;
    return (_documents.length * 100 / slots).round();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          // Keep the message clear of the bottom Continue button.
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        ),
      );
  }

  /// KYC cannot be skipped: the Aadhaar document is mandatory, the other two
  /// slots are optional.
  void _openBankDetails() {
    if (!_documents.containsKey(_DocumentSlot.aadhaar)) {
      _showMessage('Upload your Aadhaar card to continue');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BankDetaileScreen()),
    );
  }

  Future<void> _pickDocument(_DocumentSlot slot) async {
    if (_pickingSlot != null) return;
    setState(() => _pickingSlot = slot);

    PickedDocument? document;
    try {
      document = await (widget.documentPicker ?? _pickDocumentFromDevice)();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file picker.')),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _pickingSlot = null;
      if (document != null) _documents[slot] = document;
    });
  }

  Future<PickedDocument?> _pickDocumentFromDevice() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Select document',
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
    );
    if (file == null) return null;
    return PickedDocument(name: file.name, path: file.path);
  }

  @override
  Widget build(BuildContext context) {
    final int completion = _completionPercent;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Artboard(
            designWidth: VerifyDetaileScreen.designWidth,
            designHeight: VerifyDetaileScreen.designHeight,
            child: Stack(
              children: [
                const Positioned(left: 0, top: 0, child: _HeaderBackground()),
                const Positioned(left: 200, top: 0, child: _Illustration()),
                const Positioned(left: 21, top: 30, child: _BackButton()),
                const Positioned(right: 22.5, top: 34.63, child: _StepLabel()),
                const Positioned(left: 24, top: 99.15, child: _TitleLead()),
                const Positioned(left: 24, top: 134.79, child: _TitleAccent()),
                const Positioned(left: 24, top: 180.74, child: _Subtitle()),
                const Positioned(
                  left: 23,
                  top: 209.75,
                  child: _ProgressTrack(),
                ),
                const Positioned(left: 0, top: 342, child: _Sheet()),
                // Profile completion card.
                const Positioned(left: 24, top: 367, child: _PcCard()),
                const Positioned(left: 34.5, top: 381.4, child: _PcLabel()),
                Positioned(
                  right: 40,
                  top: 384.37,
                  child: _PcPercent(percent: completion),
                ),
                Positioned(
                  left: 34,
                  top: 406,
                  child: _PcBar(percent: completion),
                ),
                // Verification details section.
                const Positioned(left: 26, top: 452, child: _SectionTick()),
                const Positioned(
                  left: 40.5,
                  top: 452.07,
                  child: _SectionTitle(),
                ),
                const Positioned(left: 260, top: 447, child: _PillNote()),
                const Positioned(left: 25, top: 483, child: _Divider()),
                // Document cards.
                const Positioned(left: 23, top: 497, child: _CardAadhaar()),
                const Positioned(left: 34, top: 508, child: _TileAadhaar()),
                const Positioned(left: 89, top: 510.62, child: _TitleAadhaar()),
                Positioned(
                  left: 89,
                  top: 532.94,
                  width: 246,
                  child: _DocSubtitle(
                    defaultText: 'For individual farmers',
                    document: _documents[_DocumentSlot.aadhaar],
                  ),
                ),
                Positioned(
                  right: 41,
                  top: 519,
                  child: _Chevron(
                    selected: _documents.containsKey(_DocumentSlot.aadhaar),
                  ),
                ),
                const Positioned(left: 23, top: 573, child: _CardPan()),
                const Positioned(left: 34, top: 585, child: _TilePan()),
                const Positioned(left: 89, top: 587.12, child: _TitlePan()),
                Positioned(
                  left: 89,
                  top: 609.81,
                  width: 246,
                  child: _DocSubtitle(
                    defaultText: 'For businesses / traders',
                    document: _documents[_DocumentSlot.pan],
                  ),
                ),
                Positioned(
                  right: 41,
                  top: 595,
                  child: _Chevron(
                    selected: _documents.containsKey(_DocumentSlot.pan),
                  ),
                ),
                const Positioned(left: 23, top: 650, child: _CardBusiness()),
                const Positioned(left: 34, top: 661, child: _TileBusiness()),
                const Positioned(
                  left: 89,
                  top: 663.43,
                  child: _TitleBusiness(),
                ),
                Positioned(
                  left: 89,
                  top: 686.49,
                  width: 246,
                  child: _DocSubtitle(
                    defaultText: 'FSSAI / Udyam / GST (if available)',
                    document: _documents[_DocumentSlot.business],
                  ),
                ),
                Positioned(
                  right: 41,
                  top: 672,
                  child: _Chevron(
                    selected: _documents.containsKey(_DocumentSlot.business),
                  ),
                ),
                // Transparent hit targets covering each full card so taps on
                // any part of it open the picker.
                Positioned(
                  left: 23,
                  top: 497,
                  width: 364,
                  height: 62,
                  child: GestureDetector(
                    key: const Key('verify-doc-aadhaar'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickDocument(_DocumentSlot.aadhaar),
                  ),
                ),
                Positioned(
                  left: 23,
                  top: 573,
                  width: 364,
                  height: 62,
                  child: GestureDetector(
                    key: const Key('verify-doc-pan'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickDocument(_DocumentSlot.pan),
                  ),
                ),
                Positioned(
                  left: 23,
                  top: 650,
                  width: 364,
                  height: 62,
                  child: GestureDetector(
                    key: const Key('verify-doc-business'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickDocument(_DocumentSlot.business),
                  ),
                ),
              ],
            ),
          ),
          // Anchored to the physical screen bottom so it stays there on
          // taller devices; on the 873-tall artboard this matches the
          // design offset (873 - 54 - 16 = 803).
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 10, right: 10),
              child: SizedBox(
                height: 54,
                child: _ContinueButton(onTap: _openBankDetails),
              ),
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
    return const Text('STEP 04', style: AppTextStyles.stepLabel);
  }
}

class _TitleLead extends StatelessWidget {
  const _TitleLead();

  @override
  Widget build(BuildContext context) {
    return const Text('Verify your', style: AppTextStyles.headingLarge);
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
    return const Text(
      'A quick verification',
      style: AppTextStyles.verifySubtitle,
    );
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

/// Profile completion percentage, computed from the filled document slots.
class _PcPercent extends StatelessWidget {
  const _PcPercent({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Text('$percent%', style: AppTextStyles.pcPercent);
  }
}

class _PcBar extends StatelessWidget {
  const _PcBar({required this.percent});

  /// Completion percentage (0..100) that drives the filled portion.
  final int percent;

  static const double trackWidth = 338;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: trackWidth,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.pcTrack,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: trackWidth * percent / 100,
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
    return const Text(
      'Verification Details',
      style: AppTextStyles.verifySectionTitle,
    );
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
          'All fields are required',
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
        child: CustomPaint(
          painter: _PentagonNotePainter(color: AppColors.fieldIconBusiness),
        ),
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
        child: CustomPaint(
          painter: _ContactCardPainter(color: AppColors.fieldIconPhone),
        ),
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

class _DocSubtitle extends StatelessWidget {
  const _DocSubtitle({required this.defaultText, this.document});

  final String defaultText;
  final PickedDocument? document;

  @override
  Widget build(BuildContext context) {
    final selected = document != null;
    return Text(
      document?.name ?? defaultText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: selected
          ? AppTextStyles.docCardSubtitle.copyWith(
              color: AppColors.verifiedText,
            )
          : AppTextStyles.docCardSubtitle,
    );
  }
}

class _TitlePan extends StatelessWidget {
  const _TitlePan();

  @override
  Widget build(BuildContext context) {
    return const Text('PAN Card', style: AppTextStyles.docCardTitle);
  }
}

class _TitleBusiness extends StatelessWidget {
  const _TitleBusiness();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Business Registration',
      style: AppTextStyles.docCardTitle,
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      selected ? Icons.check_circle : Icons.keyboard_arrow_down,
      size: 18,
      color: AppColors.verifiedText,
    );
  }
}

/// Continue CTA. The parent validates that the mandatory Aadhaar document was
/// uploaded before navigating to the bank step.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
