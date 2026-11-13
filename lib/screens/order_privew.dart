import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/app_navigation.dart';
import '../widgets/artboard.dart';
import '../widgets/page_header.dart';

/// "Fresh Tomatoes is live!" product preview screen (Zeplin
/// "Android Compact - 172", project 6a8d49709e27bd8b35213d35,
/// screen 6ad1b035415e3d8370f20e1c).
///
/// Standalone 412x917 artboard with no status bar. A baked hero image
/// (pale-green card + shadow, title erased so the text can be rendered as a
/// real widget) sits at the top, followed by the success title/subtitle, the
/// Fresh Tomatoes product card with its Active pill, and the two action
/// buttons. Opened from the My Orders order blocks; the floating back circle
/// in the empty band above the hero pops the route, "Preview product" opens
/// the product details page (Zeplin 171) and "Add another product" opens the
/// Add Products flow (Zeplin 124).
class OrderPrivewScreen extends StatelessWidget {
  const OrderPrivewScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;

  static const String heroAsset = 'assets/order_privew/hero.png';
  static const String tileAsset = 'assets/order_privew/tile.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF3),
      body: Artboard(
        designWidth: designWidth,
        designHeight: designHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 56,
              child: PageHeader(
                title: '',
                backButtonKey: const Key('order-preview-back'),
              ),
            ),
            Positioned(
              left: 0,
              top: 103,
              width: 412,
              height: 332,
              child: Image.asset(heroAsset, fit: BoxFit.fill),
            ),
            Positioned(
              left: 0,
              top: 400.9,
              width: 412,
              child: Text(
                AppStrings.trOf(context, 'Fresh Tomatoes is live!'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 1.0,
                  color: Color(0xFF0D3B20),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 437.9,
              width: 412,
              child: Text(
                AppStrings.trOf(
                  context,
                  'Buyers can noww see it and place orders.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0,
                  height: 1.0,
                  color: Color(0xFF81827E),
                ),
              ),
            ),
            const Positioned(left: 22, top: 479, child: _ProductCard()),
            Positioned(
              left: 22,
              top: 782,
              child: _PreviewButton(onTap: () => goToProductDetails(context)),
            ),
            Positioned(
              left: 22,
              top: 846,
              child: _AddProductButton(onTap: () => goToAddProduct(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// White product card (24,479 364x97, r22) with the tile crop, the Fresh
/// Tomatoes name/category, the price row and the availability column, plus
/// the Active pill. Children are absolute siblings of the card in the
/// screen stack so the measured design coordinates stay 1:1.
class _ProductCard extends StatelessWidget {
  const _ProductCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 368,
      height: 97,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 368,
              height: 97,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(22)),
                border: Border.all(color: const Color(0xFFC6E9CA)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16.5,
            top: 12,
            width: 75,
            height: 74,
            child: Image.asset(OrderPrivewScreen.tileAsset, fit: BoxFit.fill),
          ),
          Positioned(
            left: 117.8,
            top: 17.6,
            child: Text(
              AppStrings.trOf(context, 'Fresh Tomatoes'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1.0,
                color: Color(0xFF000000),
              ),
            ),
          ),
          Positioned(
            left: 117.7,
            top: 34.4,
            child: Text(
              AppStrings.trOf(context, 'Vegetables'),
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0,
                height: 1.0,
                color: Color(0xFF858585),
              ),
            ),
          ),
          Positioned(
            left: 118,
            top: 60.9,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '\u20B948',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    height: 1.0,
                    color: Color(0xFF0D3B20),
                  ),
                ),
                SizedBox(width: 1),
                Text(
                  '/kg',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0,
                    height: 1.0,
                    color: Color(0xFF858585),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 254,
            top: 67.2,
            child: Text(
              AppStrings.trOf(context, '50 kg available'),
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0,
                height: 1.0,
                color: Color(0xFF858585),
              ),
            ),
          ),
          const Positioned(left: 286, top: 18, child: _ActivePill()),
        ],
      ),
    );
  }
}

/// "• Active" status chip (310,497 59x17, r8.5, 1px #D3E0BE border). The
/// dot and label coordinates are relative to the content box inside that
/// border.
class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 59,
      height: 17,
      decoration: const BoxDecoration(
        color: Color(0xFFE3F1CC),
        borderRadius: BorderRadius.all(Radius.circular(8.5)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFD3E0BE))),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 4.5,
            child: SizedBox(
              width: 4.5,
              height: 4.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF1D6B38),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            left: 19,
            top: 2,
            child: Text(
              AppStrings.trOf(context, 'Active'),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1.0,
                color: Color(0xFF1D6B38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary "Preview product" button (24,782 364x53, pill, horizontal
/// #104525 → #28AA59 gradient, drop shadow). Opens the product details page.
class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('order-preview-product'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 368,
        height: 53,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(26.5)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF104525), Color(0xFF28AA59)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x47000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          AppStrings.trOf(context, 'Preview product'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: 1.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Secondary "+ Add another product" button (24,846 364x53, pill, white
/// with 1px #EBEBEB border, no shadow). Opens the Add Products flow.
class _AddProductButton extends StatelessWidget {
  const _AddProductButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('order-add-product'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 368,
        height: 53,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(26.5)),
          border: Border.fromBorderSide(BorderSide(color: Color(0xFFEBEBEB))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1.0,
                color: Color(0xFF0D3B26),
              ),
            ),
            SizedBox(width: 10.7),
            Text(
              AppStrings.trOf(context, 'Add another product'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1.0,
                color: Color(0xFF0D3B26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
