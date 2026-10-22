import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/design_canvas.dart';

/// Product Details — static replica of Zeplin "Android Compact - 171"
/// (screen 6ad1b035a75614448d4a39f8).
///
/// Built against a 412x1564 artboard. Fit width, scroll vertically. Visual only.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1564;
  static const double trimTop = 49;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: designWidth,
          designHeight: designHeight,
          trimTop: trimTop,
          child: Stack(
            children: [
              Positioned(
                left: 24,
                top: 137,
                width: 363.5,
                height: 251.5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  child: const Image(
                    image: AssetImage('assets/product_details/photo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: 170,
                top: 405,
                width: 43.5,
                height: 10,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E8B4B),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ),
              const Positioned(
                left: 218,
                top: 405.25,
                child: _Dot(size: 9.5, color: Color(0xFFD5DDC8)),
              ),
              const Positioned(
                left: 232.5,
                top: 405.25,
                child: _Dot(size: 9.5, color: Color(0xFFD5DDC8)),
              ),
              Positioned(
                left: 24,
                top: 484,
                width: 364,
                height: 289,
                child: _Card(
                  radius: 18.5,
                  shadow: const [
                    BoxShadow(color: Color(0x2D000000), blurRadius: 8),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                top: 787,
                width: 364,
                height: 256,
                child: _Card(
                  radius: 18,
                  shadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 12),
                  ],
                ),
              ),
              Positioned(
                left: 25,
                top: 1056,
                width: 362,
                height: 150,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F1CC),
                    borderRadius: const BorderRadius.all(Radius.circular(16.5)),
                    border: Border.all(color: const Color(0xFFD1DEBC)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        offset: Offset(0, 11),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 25,
                top: 1219,
                width: 362,
                height: 167,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFEFE),
                    borderRadius: const BorderRadius.all(Radius.circular(17)),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1C000000),
                        offset: Offset(0, 1),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 27,
                top: 1404,
                width: 362,
                height: 53,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE1DA),
                    borderRadius: const BorderRadius.all(Radius.circular(22.5)),
                    border: Border.all(color: const Color(0xFFEBCFC9)),
                  ),
                ),
              ),
              Positioned(
                left: 25,
                top: 1494,
                width: 362,
                height: 53,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(21)),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F4324), Color(0xFF28AA59)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x38000000),
                        offset: Offset(0, 14),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Go back to order',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const _Text(
                'Product Details',
                _Styles.header,
                left: 67.5,
                top: 71.6,
              ),
              const _Text(
                'Fresh Tomatoes',
                _Styles.productName,
                left: 27.5,
                top: 428.1,
              ),
              const _Text('₹48', _Styles.price, left: 325, top: 428.5),
              const _Text('/kg', _Styles.perKg, left: 366.5, top: 439.1),
              const _Text(
                'Vegetables, salem, Tamil Nadu',
                _Styles.subtitle,
                left: 28.5,
                top: 453.2,
              ),
              const _Text('Details', _Styles.cardTitle, left: 44, top: 498.2),
              const _Tile('tile_price', left: 44, top: 539),
              const _Tile('tile_category', left: 44, top: 599),
              const _Tile('tile_unit', left: 44, top: 658),
              const _Tile('tile_location', left: 44, top: 717),
              const _Text(
                'Price per kg',
                _Styles.rowLabel,
                left: 88.5,
                top: 540.7,
              ),
              const _Text('₹48', _Styles.rowValue, left: 89, top: 554.8),
              const _Text(
                'Category',
                _Styles.rowLabel,
                left: 88.5,
                top: 599.7,
              ),
              const _Text(
                'Vegetables',
                _Styles.rowValueWide,
                left: 89,
                top: 614.2,
              ),
              const _Text('Unit', _Styles.rowLabel, left: 88.5, top: 658.7),
              const _Text(
                'Kilogram (kg)',
                _Styles.rowValue,
                left: 89,
                top: 672.8,
              ),
              const _Text(
                'Pickup location',
                _Styles.rowLabel,
                left: 88.5,
                top: 717.7,
              ),
              const _Text(
                'Salem, Tamil Nadu',
                _Styles.rowValue,
                left: 89,
                top: 731.8,
              ),
              const _Text(
                'Performance',
                _Styles.cardTitle,
                left: 44,
                top: 802.2,
              ),
              const Positioned(
                left: 137,
                top: 853,
                width: 122,
                height: 66,
                child: Image(
                  image: AssetImage('assets/product_details/illus.png'),
                ),
              ),
              const _Text(
                'Your first buyers are on their way',
                _Styles.headline,
                left: 25.5,
                top: 925.8,
                width: 364,
              ),
              const _Text(
                'No views or orders yet. Share the listing to speed\n'
                'things up.',
                _Styles.perfBody,
                left: 25.5,
                top: 945.4,
                width: 364,
              ),
              Positioned(
                left: 143,
                top: 992,
                width: 127,
                height: 28,
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC6E96D),
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: const Text(
                    'Share',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: Color(0xFF0D3B25),
                    ),
                  ),
                ),
              ),
              const _Text(
                'About this product',
                _Styles.cardTitle,
                left: 46.5,
                top: 1072.2,
              ),
              const _Text(
                'Farm-fresh tomatoes, hand-picked every\n'
                'morning from our fields in Salem, Firm, juicy\n'
                'and packed with care.',
                _Styles.aboutBody,
                left: 46,
                top: 1110.3,
              ),
              const _Text(
                'How buyers get orders',
                _Styles.cardTitle,
                left: 47,
                top: 1234.7,
              ),
              const _Tile('tile_pickup', left: 46, top: 1275),
              const _Tile('tile_delivery', left: 46, top: 1333),
              const _Text(
                'Buyer Pickup',
                _Styles.buyerTitle,
                left: 91,
                top: 1276.2,
              ),
              const _Text(
                'Buyers collect from your location',
                _Styles.buyerSub,
                left: 91,
                top: 1293.1,
              ),
              const _Text('Delivery', _Styles.buyerTitle, left: 91, top: 1334.2),
              const _Text(
                'You delivery to the buyer',
                _Styles.buyerSub,
                left: 90.5,
                top: 1351.6,
              ),
              Positioned(
                left: 47,
                top: 1321,
                width: 321.5,
                height: 1,
                child: Container(color: const Color(0xFFECECEC)),
              ),
              const _Toggle(left: 329, top: 1282),
              const _Toggle(left: 329, top: 1341),
              const Positioned(
                left: 149,
                top: 1425.7,
                width: 11,
                height: 12.5,
                child: Image(
                  image: AssetImage('assets/product_details/ic_trash.png'),
                ),
              ),
              const _Text(
                'Delete product',
                _Styles.deleteLabel,
                left: 167.5,
                top: 1421.8,
              ),
              Positioned(left: 24, top: 73, child: _BackCircle()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Styles {
  static const TextStyle header = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: Color(0xFF000000),
  );

  static const TextStyle productName = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: Color(0xFF0D3B20),
  );

  static const TextStyle price = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 21,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: Color(0xFF0D3B20),
  );

  static const TextStyle perKg = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Color(0xFF82837F),
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Color(0xFF82837F),
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: Color(0xFF000000),
  );

  static const TextStyle rowLabel = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Color(0xFF858585),
  );

  static const TextStyle rowValue = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: Color(0xFF0D3B20),
  );

  static const TextStyle rowValueWide = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: Color(0xFF0D3B20),
  );

  static const TextStyle headline = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: Color(0xFF0F2418),
  );

  static const TextStyle perfBody = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.43478,
    letterSpacing: 0,
    color: Color(0xFF95A09B),
  );

  static const TextStyle aboutBody = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.46552,
    letterSpacing: 0.25,
    color: Color(0xFF767E6A),
  );

  static const TextStyle buyerTitle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: Color(0xFF000000),
  );

  static const TextStyle buyerSub = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: Color(0xFF848484),
  );

  static const TextStyle deleteLabel = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.25,
    color: Color(0xFFD34B3D),
  );
}

class _Text extends StatelessWidget {
  const _Text(
    this.text,
    this.style, {
    required this.left,
    required this.top,
    this.width,
  });

  final String text;
  final TextStyle style;
  final double left;
  final double top;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final Widget child = Text(
      text,
      style: style,
      textAlign: width == null ? TextAlign.start : TextAlign.center,
    );
    return Positioned(left: left, top: top, width: width, child: child);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.radius, required this.shadow});

  final double radius;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: shadow,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.asset, {required this.left, required this.top});

  final String asset;
  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: 34,
      height: 34,
      child: Image(image: AssetImage('assets/product_details/$asset.png')),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.left, required this.top});

  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: 40,
      height: 18,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2E8B4B),
          borderRadius: BorderRadius.all(Radius.circular(9)),
        ),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 1.75),
            child: _Dot(size: 14.5, color: Colors.white),
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
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        alignment: Alignment.center,
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: const Image(
          image: AssetImage('assets/order/ic_back.png'),
          width: 15,
          height: 15,
        ),
      ),
    );
  }
}
