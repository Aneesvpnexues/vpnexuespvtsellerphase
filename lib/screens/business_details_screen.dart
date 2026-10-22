import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import 'verify_detaile.dart';

/// "STEP 02 — Tell us about your business" — static replica of Zeplin
/// "Android Compact - 88" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1adb0eb1c415e3347477b).
///
/// Built against a 412x917 artboard. Every offset below is taken straight from
/// the design PNG, so on a matching viewport the layout renders 1:1; on other
/// sizes the [Artboard] viewport scales it down on small screens and up (capped
/// at 1.5x) on large ones instead of overflowing. All five rows are
/// editable; the Continue button stays inert until every field has a value and
/// then opens [VerifyDetaileScreen].
class Step03BusinessDetailsScreen extends StatefulWidget {
  const Step03BusinessDetailsScreen({super.key});

  static const String leavesAsset = 'assets/step03/leaves.png';
  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  State<Step03BusinessDetailsScreen> createState() =>
      _Step03BusinessDetailsScreenState();
}

class _Step03BusinessDetailsScreenState
    extends State<Step03BusinessDetailsScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _business = TextEditingController();
  final TextEditingController _phone = TextEditingController(
    text: '+91 12345 67890',
  );
  final TextEditingController _location = TextEditingController(
    text: 'Salem, Tamil Nadu',
  );
  final TextEditingController _address = TextEditingController();

  bool get _allFilled =>
      _name.text.isNotEmpty &&
      _business.text.isNotEmpty &&
      _phone.text.isNotEmpty &&
      _location.text.isNotEmpty &&
      _address.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_onChanged);
    }
  }

  Iterable<TextEditingController> get _controllers => [
    _name,
    _business,
    _phone,
    _location,
    _address,
  ];

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _openVerifyDetails() {
    if (!_allFilled) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VerifyDetaileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stepPageBg,
      body: Artboard(
        designWidth: Step03BusinessDetailsScreen.designWidth,
        designHeight: Step03BusinessDetailsScreen.designHeight,
        child: Stack(
          children: [
            const Positioned(left: 200, top: 0, child: _Leaves()),
            const Positioned(left: 24, top: 105.63, child: _StepLabel()),
            const Positioned(left: 25, top: 139, child: _ProgressTrack()),
            const Positioned(left: 24, top: 162.33, child: _TitleLead()),
            const Positioned(left: 24, top: 196.83, child: _TitleYour()),
            const Positioned(left: 105, top: 196.83, child: _TitleAccent()),
            const Positioned(left: 24, top: 248.2, child: _Subtitle()),
            const Positioned(left: 24, top: 330.89, child: _SectionTitle()),
            const Positioned(right: 24.5, top: 326, child: _PillNote()),
            // Field rows.
            const Positioned(left: 24, top: 380.5, child: _TileName()),
            const Positioned(left: 43, top: 419.5, child: _Connector1()),
            const Positioned(left: 89, top: 438, child: _Divider1()),
            const Positioned(left: 89, top: 383.8, child: _LabelName()),
            Positioned(
              left: 89,
              top: 405.04,
              child: _FieldInput(
                fieldKey: const Key('businessName'),
                width: 299,
                controller: _name,
                hint: 'Enter your name..',
              ),
            ),
            const Positioned(left: 24, top: 457.5, child: _TileBusiness()),
            const Positioned(left: 43, top: 496.5, child: _Connector2()),
            const Positioned(left: 89, top: 515, child: _Divider2()),
            const Positioned(left: 89, top: 460.64, child: _LabelBusiness()),
            Positioned(
              left: 89,
              top: 481.68,
              child: _FieldInput(
                fieldKey: const Key('businessFarm'),
                width: 299,
                controller: _business,
                hint: 'Enter Business name',
              ),
            ),
            const Positioned(left: 24, top: 533.5, child: _TilePhone()),
            const Positioned(left: 43, top: 572.5, child: _Connector3()),
            const Positioned(left: 89, top: 593, child: _Divider3()),
            const Positioned(left: 89, top: 537.31, child: _LabelPhone()),
            Positioned(
              left: 89,
              top: 557.69,
              child: _FieldInput(
                fieldKey: const Key('businessPhone'),
                width: 200,
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
            ),
            const Positioned(right: 24.5, top: 541, child: _VerifiedBadge()),
            const Positioned(left: 24, top: 611.5, child: _TileLocation()),
            const Positioned(left: 43, top: 650.5, child: _Connector4()),
            const Positioned(left: 89, top: 670, child: _Divider4()),
            const Positioned(left: 89, top: 613.54, child: _LabelLocation()),
            Positioned(
              left: 89,
              top: 635.12,
              child: _FieldInput(
                fieldKey: const Key('businessLocation'),
                width: 240,
                controller: _location,
              ),
            ),
            const Positioned(right: 24.5, top: 636.5, child: _ChangeLink()),
            const Positioned(left: 24, top: 688.5, child: _TileAddress()),
            const Positioned(left: 89, top: 691.81, child: _LabelAddress()),
            Positioned(
              left: 89,
              top: 713.28,
              child: _FieldInput(
                fieldKey: const Key('businessAddress'),
                width: 299,
                controller: _address,
                hint: 'Enter your full address....',
              ),
            ),
            Positioned(
              left: 24,
              top: 818,
              child: _ContinueButton(onTap: _openVerifyDetails),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaves extends StatelessWidget {
  const _Leaves();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Step03BusinessDetailsScreen.leavesAsset,
      width: 212,
      height: 560,
      fit: BoxFit.fill,
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
        _Segment(width: 43, color: AppColors.progressActive),
        SizedBox(width: 6),
        _Segment(width: 30, color: AppColors.progressTrack),
        SizedBox(width: 7),
        _Segment(width: 30, color: AppColors.progressTrack),
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
    return const Text('Tell us about', style: AppTextStyles.headingLarge);
  }
}

class _TitleYour extends StatelessWidget {
  const _TitleYour();

  @override
  Widget build(BuildContext context) {
    return const Text('your', style: AppTextStyles.headingLarge);
  }
}

class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  @override
  Widget build(BuildContext context) {
    // "business" filled with a horizontal green gradient (#00AF13 -> #035A0D).
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.stepPageAccent, AppColors.stepPageHeadingEnd],
      ).createShader(bounds),
      child: const Text('business', style: AppTextStyles.headingLarge),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Let's create your profile",
      style: AppTextStyles.stepSubtitleAlt,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Text('Business Details', style: AppTextStyles.sectionTitle);
  }
}

class _PillNote extends StatelessWidget {
  const _PillNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126.5,
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.pillNoteGradientStart,
            AppColors.pillNoteGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      // Scales the note down under the Ahem test font (glyphs render one em
      // wide there); with bundled Roboto on device it renders 1:1.
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'All fiedls are required',
          style: AppTextStyles.pillNote,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }
}

class _TileName extends StatelessWidget {
  const _TileName();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileName,
      icon: Icons.person_outline,
      iconColor: AppColors.fieldIconName,
    );
  }
}

class _TileBusiness extends StatelessWidget {
  const _TileBusiness();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileBusiness,
      icon: Icons.business,
      iconColor: AppColors.fieldIconBusiness,
    );
  }
}

class _TilePhone extends StatelessWidget {
  const _TilePhone();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTilePhone,
      icon: Icons.phone_outlined,
      iconColor: AppColors.fieldIconPhone,
    );
  }
}

class _TileLocation extends StatelessWidget {
  const _TileLocation();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileLocation,
      icon: Icons.location_on_outlined,
      iconColor: AppColors.fieldIconLocation,
    );
  }
}

class _TileAddress extends StatelessWidget {
  const _TileAddress();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileAddress,
      icon: Icons.home_outlined,
      iconColor: AppColors.fieldIconAddress,
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

class _Connector1 extends StatelessWidget {
  const _Connector1();

  @override
  Widget build(BuildContext context) {
    return const _Connector(height: 38, color: AppColors.connectorActive);
  }
}

class _Connector2 extends StatelessWidget {
  const _Connector2();

  @override
  Widget build(BuildContext context) {
    return const _Connector(height: 37, color: AppColors.connectorPending);
  }
}

class _Connector3 extends StatelessWidget {
  const _Connector3();

  @override
  Widget build(BuildContext context) {
    return const _Connector(height: 39, color: AppColors.connectorIdle);
  }
}

class _Connector4 extends StatelessWidget {
  const _Connector4();

  @override
  Widget build(BuildContext context) {
    return const _Connector(height: 38, color: AppColors.connectorIdle);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 299, height: 1, color: AppColors.fieldDivider);
  }
}

class _Divider1 extends StatelessWidget {
  const _Divider1();

  @override
  Widget build(BuildContext context) => const _Divider();
}

class _Divider2 extends StatelessWidget {
  const _Divider2();

  @override
  Widget build(BuildContext context) => const _Divider();
}

class _Divider3 extends StatelessWidget {
  const _Divider3();

  @override
  Widget build(BuildContext context) => const _Divider();
}

class _Divider4 extends StatelessWidget {
  const _Divider4();

  @override
  Widget build(BuildContext context) => const _Divider();
}

class _LabelName extends StatelessWidget {
  const _LabelName();

  @override
  Widget build(BuildContext context) {
    return const Text('Your name', style: AppTextStyles.fieldLabel);
  }
}

/// One editable row: a borderless [TextField] laid out where the design puts
/// the placeholder/value text (box top == design glyph top, zero padding).
class _FieldInput extends StatelessWidget {
  const _FieldInput({
    required this.fieldKey,
    required this.width,
    required this.controller,
    this.hint,
    this.keyboardType,
  });

  final Key fieldKey;
  final double width;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: keyboardType,
        style: AppTextStyles.fieldValue,
        cursorColor: AppColors.inputCaret,
        cursorWidth: 2,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.fieldPlaceholder,
          isDense: true,
          border: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _LabelBusiness extends StatelessWidget {
  const _LabelBusiness();

  @override
  Widget build(BuildContext context) {
    return const Text('Business / Farm Name', style: AppTextStyles.fieldLabel);
  }
}

class _LabelPhone extends StatelessWidget {
  const _LabelPhone();

  @override
  Widget build(BuildContext context) {
    return const Text('Phone number', style: AppTextStyles.fieldLabelMuted);
  }
}

class _LabelLocation extends StatelessWidget {
  const _LabelLocation();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Business Location',
      style: AppTextStyles.fieldLabelMuted,
    );
  }
}

class _LabelAddress extends StatelessWidget {
  const _LabelAddress();

  @override
  Widget build(BuildContext context) {
    return const Text('Business Address', style: AppTextStyles.fieldLabel);
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.verifiedBg,
        border: Border.all(color: AppColors.verifiedBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Verified', style: AppTextStyles.verifiedText),
          SizedBox(width: 8),
          Icon(Icons.check_circle, size: 14, color: AppColors.verifiedText),
        ],
      ),
    );
  }
}

class _ChangeLink extends StatelessWidget {
  const _ChangeLink();

  @override
  Widget build(BuildContext context) {
    return const Text('Change', style: AppTextStyles.changeLink);
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
