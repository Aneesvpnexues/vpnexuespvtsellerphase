import 'package:flutter/material.dart';

import '../data/seller_profile_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';

/// The six onboarding choices in pill order (index == pill order on screen),
/// kept in sync with the [SellerType] labels persisted to the store.
const List<SellerType> _onboardingSellerTypes = <SellerType>[
  SellerType.farmer,
  SellerType.shopOwner,
  SellerType.restaurantSupplier,
  SellerType.distributor,
  SellerType.wholesaler,
  SellerType.businessSeller,
];

/// "STEP 02 — What best describes you?" — static replica of Zeplin
/// "Android Compact - 82" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ad4e1c5d509d0c2f6b7c).
///
/// Built against a 412x943 artboard. Every offset below is taken straight from
/// the design PNG, so on a matching viewport the layout renders 1:1; on other
/// sizes it scales down uniformly instead of overflowing. The seller type pills
/// are single-select: Continue stays dimmed until one is chosen, saves the
/// pick to [SellerProfileStore] and opens the STEP 03 screen.
class Step02SellerTypeScreen extends StatefulWidget {
  const Step02SellerTypeScreen({super.key});

  static const String illustrationAsset = 'assets/step02/illustration.png';
  static const double designWidth = 412;
  static const double designHeight = 943;

  @override
  State<Step02SellerTypeScreen> createState() => _Step02SellerTypeScreenState();
}

class _Step02SellerTypeScreenState extends State<Step02SellerTypeScreen> {
  int? _selectedIndex;

  void _select(int index) => setState(() => _selectedIndex = index);

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

  /// Requires a selection (the button is dimmed while none is picked), then
  /// persists it and continues to business details.
  void _continue() {
    if (_selectedIndex == null) {
      _showMessage('Select a seller type to continue');
      return;
    }
    SellerProfileStore.instance.saveSellerType(
      _onboardingSellerTypes[_selectedIndex!],
    );
    goToBusinessDetails(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: Step02SellerTypeScreen.designWidth,
              height: Step02SellerTypeScreen.designHeight,
              child: Stack(
                children: [
                  const Positioned(right: 25, top: 84.2, child: _StepLabel()),
                  const Positioned(left: 40, top: 97, child: _Illustration()),
                  const Positioned(left: 24, top: 441.5, child: _TitleLead()),
                  const Positioned(left: 24, top: 473.5, child: _TitleAccent()),
                  const Positioned(left: 24, top: 512, child: _Subtitle()),
                  Positioned(
                    left: 33,
                    top: 582,
                    child: _SellerTypePill(
                      width: 151.5,
                      icon: Icons.spa,
                      label: _onboardingSellerTypes[0].label,
                      selected: _selectedIndex == 0,
                      onTap: () => _select(0),
                    ),
                  ),
                  Positioned(
                    left: 227,
                    top: 582,
                    child: _SellerTypePill(
                      width: 151.5,
                      icon: Icons.storefront,
                      label: _onboardingSellerTypes[1].label,
                      selected: _selectedIndex == 1,
                      onTap: () => _select(1),
                    ),
                  ),
                  Positioned(
                    left: 93,
                    top: 649,
                    child: _SellerTypePill(
                      width: 223.5,
                      icon: Icons.local_dining,
                      label: _onboardingSellerTypes[2].label,
                      selected: _selectedIndex == 2,
                      onTap: () => _select(2),
                    ),
                  ),
                  Positioned(
                    left: 46,
                    top: 716,
                    child: _SellerTypePill(
                      width: 151.5,
                      icon: Icons.directions_bus,
                      label: _onboardingSellerTypes[3].label,
                      selected: _selectedIndex == 3,
                      onTap: () => _select(3),
                    ),
                  ),
                  Positioned(
                    left: 214,
                    top: 716,
                    child: _SellerTypePill(
                      width: 151.5,
                      icon: Icons.inventory_2,
                      label: _onboardingSellerTypes[4].label,
                      selected: _selectedIndex == 4,
                      onTap: () => _select(4),
                    ),
                  ),
                  Positioned(
                    left: 113,
                    top: 781,
                    child: _SellerTypePill(
                      width: 183.5,
                      icon: Icons.apartment,
                      label: _onboardingSellerTypes[5].label,
                      selected: _selectedIndex == 5,
                      onTap: () => _select(5),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 866,
                    child: _ContinueButton(
                      enabled: _selectedIndex != null,
                      onTap: _continue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return const Text('STEP 02', style: AppTextStyles.stepLabel);
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Step02SellerTypeScreen.illustrationAsset,
      width: 348.5,
      height: 347.5,
      fit: BoxFit.fill,
    );
  }
}

class _TitleLead extends StatelessWidget {
  const _TitleLead();

  @override
  Widget build(BuildContext context) {
    return const Text('What best', style: AppTextStyles.heading);
  }
}

class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  @override
  Widget build(BuildContext context) {
    return const Text('describes you?', style: AppTextStyles.headingAccent);
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Choose your seller type\n'
      'to get started.',
      style: AppTextStyles.stepSubtitle,
    );
  }
}

class _SellerTypePill extends StatelessWidget {
  const _SellerTypePill({
    required this.width,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected ? AppColors.surface : AppColors.pillLabel;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          border: Border.fromBorderSide(
            BorderSide(
              color: selected ? AppColors.primary : AppColors.pillBorder,
            ),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(25)),
        ),
        // Scales the icon+label row down when the label cannot fit the pill
        // (the test font renders every glyph one em wide); on device with the
        // bundled Roboto it renders 1:1.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.pillLabel.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Continue CTA. Stays dimmed ([enabled] == false) until a pill is selected;
/// tapping it while disabled reports the missing selection instead of
/// navigating.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: 364,
          height: 54,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: const Text('Continue', style: AppTextStyles.button),
        ),
      ),
    );
  }
}
