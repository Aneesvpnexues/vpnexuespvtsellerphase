import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

/// Signature for the report photo picker so tests can inject a fake.
typedef ReportPhotoPicker = Future<Uint8List?> Function();

/// "Report a problem" form (Zeplin "Android Compact - 200").
///
/// Built against a 412x917 artboard. The topic/contact chips are single
/// select, the order id and description are real text fields, "Add a photo"
/// opens the gallery (or an injected [ReportPhotoPicker]) and Submit validates
/// the form before confirming the request.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key, this.photoPicker});

  /// Overrides the gallery picker, used by widget tests.
  final ReportPhotoPicker? photoPicker;

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
  static const _inputStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: Colors.black,
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
  static const _chipSelectedStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Color(0xFFC6E96D),
  );

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  String? _topic;
  String? _contact;
  Uint8List? _photo;
  late final TextEditingController _orderId;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _orderId = TextEditingController();
    _description = TextEditingController();
  }

  @override
  void dispose() {
    _orderId.dispose();
    _description.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Uint8List?> _pickFromGallery() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  Future<void> _pickPhoto() async {
    Uint8List? bytes;
    try {
      bytes = await (widget.photoPicker ?? _pickFromGallery)();
    } catch (_) {
      if (mounted) _showMessage('Could not open the photo picker.');
      return;
    }
    if (!mounted || bytes == null) return;
    setState(() => _photo = bytes);
  }

  Future<void> _submit() async {
    final String? topic = _topic;
    if (topic == null) {
      _showMessage('Choose what this is about.');
      return;
    }
    if (_description.text.trim().isEmpty) {
      _showMessage('Tell us what happened.');
      return;
    }
    final String? contact = _contact;
    if (contact == null) {
      _showMessage('Choose how we should reach you.');
      return;
    }

    FocusScope.of(context).unfocus();
    final bool? done = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('report-success-dialog'),
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        title: const Text('Request submitted'),
        content: Text(
          'Thanks! We will look into your ${topic.toLowerCase()} issue and '
          'get back to you via $contact.',
        ),
        actions: [
          TextButton(
            key: const Key('report-dialog-done'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (done == true && mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: ReportProblemScreen.designWidth,
          designHeight: ReportProblemScreen.designHeight,
          trimTop: ReportProblemScreen.trimTop,
          child: Stack(
            children: [
              const Positioned(left: 24, top: 73, child: _BackCircle()),
              const Positioned(
                left: 68,
                top: 73,
                child: LabelText(
                  'Report a problem',
                  ReportProblemScreen._titleStyle,
                  width: 170,
                ),
              ),
              const Positioned(left: 25, top: 121, child: _SupportHero()),
              const Positioned(left: 24, top: 255, child: _FormCard()),
              const Positioned(
                left: 45,
                top: 272,
                child: LabelText(
                  'What is this about?',
                  ReportProblemScreen._sectionStyle,
                  width: 114,
                ),
              ),
              Positioned(
                left: 41,
                top: 302,
                child: _ChoiceChip(
                  key: const Key('report-topic-order'),
                  width: 76,
                  label: 'Order',
                  textLeft: 21,
                  textWidth: 34,
                  selected: _topic == 'Order',
                  onTap: () => setState(() => _topic = 'Order'),
                ),
              ),
              Positioned(
                left: 127,
                top: 302,
                child: _ChoiceChip(
                  key: const Key('report-topic-product'),
                  width: 90,
                  label: 'Product',
                  textLeft: 21.5,
                  textWidth: 47,
                  selected: _topic == 'Product',
                  onTap: () => setState(() => _topic = 'Product'),
                ),
              ),
              Positioned(
                left: 226,
                top: 302,
                child: _ChoiceChip(
                  key: const Key('report-topic-payment'),
                  width: 90,
                  label: 'Payment',
                  textLeft: 19,
                  textWidth: 52,
                  selected: _topic == 'Payment',
                  onTap: () => setState(() => _topic = 'Payment'),
                ),
              ),
              Positioned(
                left: 40,
                top: 342,
                child: _ChoiceChip(
                  key: const Key('report-topic-account'),
                  width: 94,
                  label: 'Account',
                  textLeft: 22,
                  textWidth: 50,
                  selected: _topic == 'Account',
                  onTap: () => setState(() => _topic = 'Account'),
                ),
              ),
              Positioned(
                left: 143,
                top: 342,
                child: _ChoiceChip(
                  key: const Key('report-topic-other'),
                  width: 90,
                  label: 'Other',
                  textLeft: 28,
                  textWidth: 34,
                  selected: _topic == 'Other',
                  onTap: () => setState(() => _topic = 'Other'),
                ),
              ),
              const Positioned(
                left: 45,
                top: 384,
                child: LabelText(
                  'Order ID',
                  ReportProblemScreen._sectionStyle,
                  width: 50,
                ),
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
              Positioned(
                left: 86,
                top: 418,
                width: 258,
                height: 25,
                child: TextField(
                  key: const Key('report-order-id-field'),
                  controller: _orderId,
                  style: ReportProblemScreen._inputStyle.copyWith(
                    height: 25 / 12,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                  cursorColor: ReportProblemScreen._darkGreen,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration.collapsed(
                    hintText: 'e.g. #NX4582',
                    hintStyle: ReportProblemScreen._placeholderStyle.copyWith(
                      height: 25 / 12,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 45,
                top: 462,
                child: LabelText(
                  'Tell us what happened',
                  ReportProblemScreen._sectionStyle,
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
              Positioned(
                left: 60,
                top: 496,
                width: 289,
                height: 85,
                child: TextField(
                  key: const Key('report-description-field'),
                  controller: _description,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: ReportProblemScreen._inputStyle.copyWith(
                    height: 25 / 12,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                  cursorColor: ReportProblemScreen._darkGreen,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Describe the problem in a few words',
                    hintStyle: ReportProblemScreen._placeholderStyle.copyWith(
                      height: 25 / 12,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 45,
                top: 600,
                child: LabelText(
                  'Add a photo',
                  ReportProblemScreen._sectionStyle,
                  width: 72,
                ),
              ),
              Positioned(
                left: 45,
                top: 626,
                child: _PhotoTile(
                  photo: _photo,
                  onTap: _pickPhoto,
                  onRemove: () => setState(() => _photo = null),
                ),
              ),
              const Positioned(
                left: 110,
                top: 642,
                child: LabelText(
                  'A screenshot or photo helps us fix it faster',
                  ReportProblemScreen._hintStyle,
                  width: 207,
                ),
              ),
              const Positioned(
                left: 45,
                top: 692,
                child: LabelText(
                  'How should we reach you?',
                  ReportProblemScreen._sectionStyle,
                  width: 150,
                ),
              ),
              Positioned(
                left: 41,
                top: 722,
                child: _ContactChip(
                  key: const Key('report-contact-call'),
                  width: 86,
                  label: 'Call me',
                  textLeft: 21,
                  textWidth: 44,
                  filled: false,
                  selected: _contact == 'Call me',
                  onTap: () => setState(() => _contact = 'Call me'),
                ),
              ),
              Positioned(
                left: 137,
                top: 722,
                child: _ContactChip(
                  key: const Key('report-contact-whatsapp'),
                  width: 99,
                  label: 'WhatsApp',
                  textLeft: 18.5,
                  textWidth: 62,
                  selected: _contact == 'WhatsApp',
                  onTap: () => setState(() => _contact = 'WhatsApp'),
                ),
              ),
              Positioned(
                left: 246,
                top: 722,
                child: _ContactChip(
                  key: const Key('report-contact-email'),
                  width: 80,
                  label: 'Email',
                  textLeft: 24,
                  textWidth: 32,
                  selected: _contact == 'Email',
                  onTap: () => setState(() => _contact = 'Email'),
                ),
              ),
              Positioned(
                left: 25,
                top: 850,
                child: _SubmitButton(onTap: _submit),
              ),
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
      key: const Key('report-back'),
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
    super.key,
    required this.width,
    required this.label,
    required this.textLeft,
    required this.textWidth,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String label;
  final double textLeft;
  final double textWidth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: 31,
        decoration: BoxDecoration(
          color: selected ? ReportProblemScreen._darkGreen : Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(
            color: selected
                ? ReportProblemScreen._darkGreen
                : ReportProblemScreen._chipBorder,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: textLeft,
              top: 3,
              child: LabelText(
                label,
                selected
                    ? ReportProblemScreen._chipSelectedStyle
                    : ReportProblemScreen._chipStyle,
                width: textWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    super.key,
    required this.width,
    required this.label,
    required this.textLeft,
    required this.textWidth,
    required this.selected,
    required this.onTap,
    this.filled = true,
  });

  final double width;
  final String label;
  final double textLeft;
  final double textWidth;
  final bool selected;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: 31,
        decoration: BoxDecoration(
          color: selected
              ? ReportProblemScreen._darkGreen
              : (filled ? Colors.white : null),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(
            color: selected
                ? ReportProblemScreen._darkGreen
                : ReportProblemScreen._chipBorder,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: textLeft,
              top: 3,
              child: LabelText(
                label,
                selected
                    ? ReportProblemScreen._chipSelectedStyle
                    : ReportProblemScreen._chipStyle,
                width: textWidth,
              ),
            ),
          ],
        ),
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
  const _PhotoTile({
    required this.photo,
    required this.onTap,
    required this.onRemove,
  });

  final Uint8List? photo;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('report-photo-tile'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 53,
        height: 55,
        child: photo == null
            ? CustomPaint(
                painter: const _DashedTilePainter(),
                child: const Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(left: 19, top: 19, child: _CameraGlyph()),
                  ],
                ),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      child: Image.memory(photo!, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: GestureDetector(
                      key: const Key('report-photo-remove'),
                      onTap: onRemove,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: ReportProblemScreen._darkGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
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
  const _SubmitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('report-submit'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
