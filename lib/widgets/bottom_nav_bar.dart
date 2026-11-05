import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'hover_press.dart';

/// Shared seller-dashboard bottom navigation (Zeplin "Android Compact - 124/
/// 151/152/159"): Home, Products, a lime FAB, Orders, Profile.
///
/// Drawn against a 412-wide artboard; the bar is 88 tall with the FAB
/// protruding above it. [selectedIndex] highlights one of the four tabs
/// (Home=0, Products=1, Orders=2, Profile=3); null leaves none selected.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    this.selectedIndex,
    this.onHomeTap,
    this.onProductsTap,
    this.onAddTap,
    this.onOrdersTap,
    this.onProfileTap,
  });

  static const double designWidth = 412;
  static const double barHeight = 88;

  final int? selectedIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProductsTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onProfileTap;

  /// Design-measured tab centers (Zeplin 124): Home 52, Products 127,
  /// FAB 206, Orders 285, Profile 363. Tab boxes are 60 wide, so each is
  /// centered as `left = center - 30`; Profile ends at x393, inside 412.
  static const double _homeCenter = 52;
  static const double _productsCenter = 127;
  static const double _ordersCenter = 285;
  static const double _profileCenter = 363;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: designWidth,
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: designWidth,
              height: barHeight,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: _homeCenter - 30,
            top: 14,
            child: _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: selectedIndex == 0,
              onTap: onHomeTap,
            ),
          ),
          Positioned(
            left: _productsCenter - 30,
            top: 14,
            child: _NavItem(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              active: selectedIndex == 1,
              onTap: onProductsTap,
            ),
          ),
          Positioned(
            left: _ordersCenter - 30,
            top: 14,
            child: _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              active: selectedIndex == 2,
              onTap: onOrdersTap,
            ),
          ),
          Positioned(
            left: _profileCenter - 30,
            top: 14,
            child: _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              active: selectedIndex == 3,
              onTap: onProfileTap,
            ),
          ),
          Positioned(
            left: (designWidth - 66) / 2,
            top: -22,
            child: GestureDetector(
              onTap: onAddTap,
              child: HoverPress.icon(
                enabled: onAddTap != null,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.fabLime,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 28,
                        color: AppColors.darkGreenInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [BottomNavBar] pinned to the viewport bottom for the scrollable dashboard
/// screens (Home, My Products, My Orders).
///
/// The bar is laid out at its 412x88 design size and scaled by the viewport
/// width, matching the [DesignCanvas] content scale, so the tabs stay the same
/// size as the artboard on every device.
class PinnedBottomNav extends StatelessWidget {
  const PinnedBottomNav({
    super.key,
    this.selectedIndex,
    this.onHomeTap,
    this.onProductsTap,
    this.onAddTap,
    this.onOrdersTap,
    this.onProfileTap,
    this.maxScale = 1.0,
  });

  final int? selectedIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProductsTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onProfileTap;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / BottomNavBar.designWidth).clamp(
          0.4,
          maxScale,
        );
        return SizedBox(
          width: BottomNavBar.designWidth * scale,
          height: BottomNavBar.barHeight * scale,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: BottomNavBar.designWidth,
              height: BottomNavBar.barHeight,
              child: BottomNavBar(
                selectedIndex: selectedIndex,
                onHomeTap: onHomeTap,
                onProductsTap: onProductsTap,
                onAddTap: onAddTap,
                onOrdersTap: onOrdersTap,
                onProfileTap: onProfileTap,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.navActive : AppColors.navInactive;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: HoverPress.chip(
        enabled: onTap != null,
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.navLabel.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
