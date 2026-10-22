import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import 'seller_home_screen.dart';

/// "STEP 02 — What best describes you?" — static replica of Zeplin
/// "Android Compact - 82" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1ad4e1c5d509d0c2f6b7c).
///
/// Built against a 412x943 artboard. Every offset below is taken straight from
/// the design PNG, so on a matching viewport the layout renders 1:1; on other
/// sizes it scales down uniformly instead of overflowing. Pills and the
/// Continue button are visual only — no handlers, no state.
class Step02SellerTypeScreen extends StatelessWidget {
  const Step02SellerTypeScreen({super.key});

  static const String illustrationAsset = 'assets/step02/illustration.png';
  static const double designWidth = 412;
  static const double designHeight = 943;

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
              width: designWidth,
              height: designHeight,
              child: Stack(
                children: const [
                  Positioned(right: 25, top: 84.2, child: _StepLabel()),
                  Positioned(left: 40, top: 97, child: _Illustration()),
                  Positioned(left: 24, top: 441.5, child: _TitleLead()),
                  Positioned(left: 24, top: 473.5, child: _TitleAccent()),
                  Positioned(left: 24, top: 512, child: _Subtitle()),
                  Positioned(left: 33, top: 582, child: _FarmerPill()),
                  Positioned(left: 227, top: 582, child: _ShopOwnerPill()),
                  Positioned(left: 93, top: 649, child: _RestaurantPill()),
                  Positioned(left: 46, top: 716, child: _MarketPill()),
                  Positioned(left: 214, top: 716, child: _WholesalerPill()),
                  Positioned(left: 113, top: 781, child: _BusinessPill()),
                  Positioned(left: 24, top: 866, child: _ContinueButton()),
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
  });

  final double width;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 50,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(BorderSide(color: AppColors.pillBorder)),
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
      // Scales the icon+label row down when the label cannot fit the pill
      // (the test font renders every glyph one em wide); on device with the
      // bundled Roboto it renders 1:1.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.pillLabel),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.pillLabel),
          ],
        ),
      ),
    );
  }
}

class _FarmerPill extends StatelessWidget {
  const _FarmerPill();

  @override
  Widget build(BuildContext context) {
    return const _SellerTypePill(
      width: 151.5,
      icon: Icons.spa,
      label: 'Farmer',
    );
  }
}

class _ShopOwnerPill extends StatelessWidget {
  const _ShopOwnerPill();

  @override
  Widget build(BuildContext context) {
    return const _SellerTypePill(
      width: 151.5,
      icon: Icons.storefront,
      label: 'Shop Owner',
    );
  }
}

class _RestaurantPill extends StatelessWidget {
  const _RestaurantPill();

  @override
  Widget build(BuildContext context) {
    return const _SellerTypePill(
      width: 223.5,
      icon: Icons.local_dining,
      label: 'Restaurant Supplier',
    );
  }
}

class _MarketPill extends StatelessWidget {
  const _MarketPill();

  @override
  Widget build(BuildContext context) {
    return const _SellerTypePill(
      width: 151.5,
      icon: Icons.directions_bus,
      label: 'Shop Owner',
    );
  }
}

class _WholesalerPill extends StatelessWidget {
  const _WholesalerPill();

  @override
  Widget build(BuildContext context) {
    return const _SellerTypePill(
      width: 151.5,
      icon: Icons.inventory_2,
      label: 'Wholesaler',
    );
  }
}

class _BusinessPill extends StatelessWidget {
  const _BusinessPill();

  @override
  Widget build(BuildContext context) {
    return const _SellerTypePill(
      width: 183.5,
      icon: Icons.apartment,
      label: 'Business seller',
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.home),
          builder: (_) => const SellerHomeScreen(),
        ),
      ),
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
    );
  }
}
