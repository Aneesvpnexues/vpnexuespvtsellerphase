import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'verify_detaile.dart';

/// "STEP 02 — Tell us about your business" — static replica of Zeplin
/// "Android Compact - 88" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1adb0eb1c415e3347477b).
///
/// Built against a 412x917 artboard. Every offset below is taken straight from
/// the design PNG, so on a matching viewport the layout renders 1:1; on other
/// sizes it scales down uniformly instead of overflowing. Fields are visual
/// only; the Continue button opens [VerifyDetaileScreen].
class Step03BusinessDetailsScreen extends StatelessWidget {
  const Step03BusinessDetailsScreen({super.key});

  static const String leavesAsset = 'assets/step03/leaves.png';
  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stepPageBg,
      body: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: Stack(
                children: const [
                  Positioned(left: 200, top: 0, child: _Leaves()),
                  Positioned(left: 24, top: 105.63, child: _StepLabel()),
                  Positioned(left: 25, top: 139, child: _ProgressTrack()),
                  Positioned(left: 24, top: 162.33, child: _TitleLead()),
                  Positioned(left: 24, top: 196.83, child: _TitleYour()),
                  Positioned(left: 105, top: 196.83, child: _TitleAccent()),
                  Positioned(left: 24, top: 248.2, child: _Subtitle()),
                  Positioned(left: 24, top: 330.89, child: _SectionTitle()),
                  Positioned(right: 24.5, top: 326, child: _PillNote()),
                  // Field rows.
                  Positioned(left: 24, top: 380.5, child: _TileName()),
                  Positioned(left: 89, top: 419.5, child: _Connector1()),
                  Positioned(left: 89, top: 438, child: _Divider1()),
                  Positioned(left: 89, top: 383.8, child: _LabelName()),
                  Positioned(left: 89, top: 405.04, child: _PlaceholderName()),
                  Positioned(left: 24, top: 457.5, child: _TileBusiness()),
                  Positioned(left: 89, top: 496.5, child: _Connector2()),
                  Positioned(left: 89, top: 515, child: _Divider2()),
                  Positioned(left: 89, top: 460.64, child: _LabelBusiness()),
                  Positioned(left: 89, top: 481.68, child: _PlaceholderBusiness()),
                  Positioned(left: 24, top: 533.5, child: _TilePhone()),
                  Positioned(left: 89, top: 572.5, child: _Connector3()),
                  Positioned(left: 89, top: 593, child: _Divider3()),
                  Positioned(left: 89, top: 537.31, child: _LabelPhone()),
                  Positioned(left: 89, top: 557.69, child: _ValuePhone()),
                  Positioned(right: 24.5, top: 541, child: _VerifiedBadge()),
                  Positioned(left: 24, top: 611.5, child: _TileLocation()),
                  Positioned(left: 89, top: 650.5, child: _Connector4()),
                  Positioned(left: 89, top: 670, child: _Divider4()),
                  Positioned(left: 89, top: 613.54, child: _LabelLocation()),
                  Positioned(right: 24.5, top: 636.5, child: _ChangeLink()),
                  Positioned(left: 89, top: 635.12, child: _ValueLocation()),
                  Positioned(left: 24, top: 688.5, child: _TileAddress()),
                  Positioned(left: 89, top: 691.81, child: _LabelAddress()),
                  Positioned(left: 89, top: 713.28, child: _PlaceholderAddress()),
                  Positioned(left: 24, top: 818, child: _ContinueButton()),
                ],
              ),
            ),
          ),
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
    return const Text('Tell us about', style: AppTextStyles.heading);
  }
}

class _TitleYour extends StatelessWidget {
  const _TitleYour();

  @override
  Widget build(BuildContext context) {
    return const Text('your', style: AppTextStyles.heading);
  }
}

class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  @override
  Widget build(BuildContext context) {
    // "business" filled with a horizontal green gradient (#00AF13 -> #035A0D).
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppColors.stepPageAccent,
          AppColors.stepPageHeadingEnd,
        ],
      ).createShader(bounds),
      child: const Text(
        'business',
        style: AppTextStyles.heading,
      ),
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
  const _Tile({required this.color, required this.icon, required this.iconColor});

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
    return Container(
      width: 299,
      height: 1,
      color: AppColors.fieldDivider,
    );
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

class _PlaceholderName extends StatelessWidget {
  const _PlaceholderName();

  @override
  Widget build(BuildContext context) {
    return const Text('Enter your name..',
        style: AppTextStyles.fieldPlaceholder);
  }
}

class _LabelBusiness extends StatelessWidget {
  const _LabelBusiness();

  @override
  Widget build(BuildContext context) {
    return const Text('Business / Farm Name', style: AppTextStyles.fieldLabel);
  }
}

class _PlaceholderBusiness extends StatelessWidget {
  const _PlaceholderBusiness();

  @override
  Widget build(BuildContext context) {
    return const Text('Enter Business name',
        style: AppTextStyles.fieldPlaceholder);
  }
}

class _LabelPhone extends StatelessWidget {
  const _LabelPhone();

  @override
  Widget build(BuildContext context) {
    return const Text('Phone number', style: AppTextStyles.fieldLabelMuted);
  }
}

class _ValuePhone extends StatelessWidget {
  const _ValuePhone();

  @override
  Widget build(BuildContext context) {
    return const Text('+91 12345 67890', style: AppTextStyles.fieldValue);
  }
}

class _LabelLocation extends StatelessWidget {
  const _LabelLocation();

  @override
  Widget build(BuildContext context) {
    return const Text('Business Location',
        style: AppTextStyles.fieldLabelMuted);
  }
}

class _ValueLocation extends StatelessWidget {
  const _ValueLocation();

  @override
  Widget build(BuildContext context) {
    return const Text('Salem, Tamil Nadu', style: AppTextStyles.fieldValue);
  }
}

class _LabelAddress extends StatelessWidget {
  const _LabelAddress();

  @override
  Widget build(BuildContext context) {
    return const Text('Business Address', style: AppTextStyles.fieldLabel);
  }
}

class _PlaceholderAddress extends StatelessWidget {
  const _PlaceholderAddress();

  @override
  Widget build(BuildContext context) {
    return const Text('Enter your full address....',
        style: AppTextStyles.fieldPlaceholder);
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
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const VerifyDetaileScreen()),
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
