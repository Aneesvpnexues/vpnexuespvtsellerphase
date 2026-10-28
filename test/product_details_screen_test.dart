import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/product_store.dart';
import 'package:seller_app/screens/product_details_screen.dart';

const List<String> _assets = [
  'assets/product_details/photo.png',
  'assets/product_details/illus.png',
  'assets/product_details/tile_price.png',
  'assets/product_details/tile_category.png',
  'assets/product_details/tile_unit.png',
  'assets/product_details/tile_location.png',
  'assets/product_details/tile_pickup.png',
  'assets/product_details/tile_delivery.png',
  'assets/product_details/ic_trash.png',
  'assets/order/ic_back.png',
];

final _photoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6Q'
  'AAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhX'
  'Y/jPwPAfAAUAAf+mXJtdAAAAAElFTkSuQmCC',
);

Future<void> pumpProductDetails(
  WidgetTester tester, {
  Product? product,
  ProductShare? shareProduct,
}) async {
  tester.view.physicalSize = const Size(412, 1515);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ProductDetailsScreen(product: product, shareProduct: shareProduct),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpPushedProductDetails(
  WidgetTester tester, {
  Product? product,
  ProductUpdater? productUpdater,
  ProductDeleter? productDeleter,
}) async {
  tester.view.physicalSize = const Size(412, 1515);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductDetailsScreen(
                    product: product,
                    productUpdater:
                        productUpdater ??
                        (Product updated) async {
                          ProductStore.instance.updateProduct(updated);
                          return updated;
                        },
                    productDeleter:
                        productDeleter ??
                        (String id) async {
                          ProductStore.instance.removeProduct(id);
                        },
                  ),
                ),
              ),
              child: const Text('Open details'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open details'));
  await tester.pumpAndSettle();
}

Finder assetImage(String asset) => find.byWidgetPredicate(
  (widget) =>
      widget is Image && (widget.image as AssetImage).assetName == asset,
);

void main() {
  setUp(ProductStore.instance.clear);

  testWidgets('renders the 171 product details content', (tester) async {
    await pumpProductDetails(tester);

    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('Fresh Tomatoes'), findsOneWidget);
    expect(find.text('\u20B948'), findsNWidgets(2));
    expect(find.text('/kg'), findsOneWidget);
    expect(find.text('Vegetables, salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Price per kg'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Vegetables'), findsOneWidget);
    expect(find.text('Unit'), findsOneWidget);
    expect(find.text('Kilogram (kg)'), findsOneWidget);
    expect(find.text('Pickup location'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Your first buyers are on their way'), findsOneWidget);
    expect(
      find.text(
        'No views or orders yet. Share the listing to speed\nthings up.',
      ),
      findsOneWidget,
    );
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('About this product'), findsOneWidget);
    expect(
      find.text(
        'Farm-fresh tomatoes, hand-picked every\n'
        'morning from our fields in Salem, Firm, juicy\n'
        'and packed with care.',
      ),
      findsOneWidget,
    );
    expect(find.text('How buyers get orders'), findsOneWidget);
    expect(find.text('Buyer Pickup'), findsOneWidget);
    expect(find.text('Buyers collect from your location'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('You delivery to the buyer'), findsOneWidget);
    expect(find.text('Delete product'), findsOneWidget);
    expect(find.text('Go back to order'), findsOneWidget);
  });

  testWidgets('renders a saved product with its image and details', (
    tester,
  ) async {
    final product = Product(
      id: 'P1',
      name: 'Alphonso Mango',
      category: 'Fruits',
      price: 120.5,
      unit: 'kg',
      quantity: 7,
      description: 'Sweet mangoes from the farm.',
      status: ProductStatus.active,
      photos: <ProductPhoto>[ProductPhoto(bytes: _photoBytes)],
    );

    await pumpProductDetails(tester, product: product);

    expect(find.text('Alphonso Mango'), findsOneWidget);
    expect(find.text('\u20B9120.50'), findsNWidgets(2));
    expect(find.text('Fruits, 7 kg available'), findsOneWidget);
    expect(find.text('Fruits'), findsOneWidget);
    expect(find.text('Price per kg'), findsOneWidget);
    expect(find.text('Kilogram (kg)'), findsOneWidget);
    expect(find.text('Sweet mangoes from the farm.'), findsOneWidget);
    expect(find.text('Fresh Tomatoes'), findsNothing);

    final Image image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('product-details-photo')),
        matching: find.byType(Image),
      ),
    );
    expect(image.image, isA<MemoryImage>());
  });

  testWidgets('slides through every photo added to the product', (
    tester,
  ) async {
    final product = Product(
      id: 'P1',
      name: 'Alphonso Mango',
      category: 'Fruits',
      price: 120.5,
      unit: 'kg',
      quantity: 7,
      description: 'Sweet mangoes from the farm.',
      status: ProductStatus.active,
      photos: <ProductPhoto>[
        ProductPhoto(bytes: _photoBytes),
        ProductPhoto(bytes: _photoBytes),
        ProductPhoto(bytes: _photoBytes),
      ],
    );

    await pumpProductDetails(tester, product: product);

    final Finder carousel = find.byKey(
      const ValueKey('product-details-photo-carousel'),
    );
    final Finder indicators = find.byKey(
      const ValueKey('product-photo-indicators'),
    );
    expect(carousel, findsOneWidget);
    expect(
      find.descendant(of: indicators, matching: find.byType(AnimatedContainer)),
      findsNWidgets(3),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('product-photo-indicator-0')))
          .width,
      closeTo(43.5, 0.1),
    );

    await tester.drag(carousel, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PageView>(carousel).controller!.page,
      closeTo(1, 0.01),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('product-photo-indicator-0')))
          .width,
      closeTo(9.5, 0.1),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('product-photo-indicator-1')))
          .width,
      closeTo(43.5, 0.1),
    );

    await tester.drag(carousel, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PageView>(carousel).controller!.page,
      closeTo(2, 0.01),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('product-photo-indicator-2')))
          .width,
      closeTo(43.5, 0.1),
    );
  });

  testWidgets('sharing sends the product link through the share sheet', (
    tester,
  ) async {
    Product? shared;
    final product = Product(
      id: 'P1',
      name: 'Alphonso Mango',
      category: 'Fruits',
      price: 120.5,
      unit: 'kg',
      quantity: 7,
      description: 'Sweet mangoes from the farm.',
      status: ProductStatus.active,
      photos: const <ProductPhoto>[],
    );

    await pumpProductDetails(
      tester,
      product: product,
      shareProduct: (value) async => shared = value,
    );
    await tester.tap(find.byKey(const ValueKey('share-product')));
    await tester.pump();

    expect(shared, same(product));
    final String link = ProductDetailsScreen.productShareUri(product)
        .toString();
    expect(link, '${ProductDetailsScreen.shareBaseUrl}/P1');
    final String text = ProductDetailsScreen.productShareText(product);
    expect(text, contains('Alphonso Mango'));
    expect(text, contains('\u20B9120.50/kg'));
    expect(text, contains('7 kg available'));
    expect(text, contains(link));
  });

  testWidgets('fulfillment toggles update the product', (tester) async {
    final product = ProductStore.instance.addProduct(
      name: 'Alphonso Mango',
      category: 'Fruits',
      price: 120.5,
      unit: 'kg',
      quantity: 7,
      description: 'Sweet mangoes from the farm.',
      status: ProductStatus.active,
    );

    await pumpPushedProductDetails(tester, product: product);

    await tester.tap(find.byKey(const ValueKey('buyer-pickup-toggle')));
    await tester.pumpAndSettle();
    expect(ProductStore.instance.products.single.buyerPickupEnabled, isFalse);
    expect(
      tester
          .widget<AnimatedAlign>(
            find.descendant(
              of: find.byKey(const ValueKey('buyer-pickup-toggle')),
              matching: find.byType(AnimatedAlign),
            ),
          )
          .alignment,
      Alignment.centerLeft,
    );

    await tester.tap(find.byKey(const ValueKey('delivery-toggle')));
    await tester.pumpAndSettle();
    expect(ProductStore.instance.products.single.deliveryEnabled, isFalse);
    expect(
      tester
          .widget<AnimatedAlign>(
            find.descendant(
              of: find.byKey(const ValueKey('delivery-toggle')),
              matching: find.byType(AnimatedAlign),
            ),
          )
          .alignment,
      Alignment.centerLeft,
    );
  });

  testWidgets('deleting a product confirms, removes it, and goes back', (
    tester,
  ) async {
    final product = ProductStore.instance.addProduct(
      name: 'Alphonso Mango',
      category: 'Fruits',
      price: 120.5,
      unit: 'kg',
      quantity: 7,
      description: 'Sweet mangoes from the farm.',
      status: ProductStatus.active,
    );

    await pumpPushedProductDetails(tester, product: product);

    await tester.tap(find.byKey(const ValueKey('delete-product')));
    await tester.pumpAndSettle();
    expect(find.text('Delete product?'), findsOneWidget);
    expect(
      find.text('Remove Alphonso Mango from your listings?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('confirm-delete-product')));
    await tester.pumpAndSettle();

    expect(ProductStore.instance.products, isEmpty);
    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.text('Open details'), findsOneWidget);
    expect(find.text('Product deleted'), findsOneWidget);
  });

  testWidgets('the bottom button goes back', (tester) async {
    final product = ProductStore.instance.addProduct(
      name: 'Alphonso Mango',
      category: 'Fruits',
      price: 120.5,
      unit: 'kg',
      quantity: 7,
      description: 'Sweet mangoes from the farm.',
      status: ProductStatus.active,
    );

    await pumpPushedProductDetails(tester, product: product);
    await tester.tap(find.byKey(const ValueKey('product-details-back')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.text('Open details'), findsOneWidget);
  });

  testWidgets('layout matches the 412x1564 design geometry', (tester) async {
    await pumpProductDetails(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Product Details')).left, closeTo(67.5, 3));
    expect(rectOf(find.text('Product Details')).top, closeTo(24.6, 4));
    expect(rectOf(find.text('Fresh Tomatoes')).left, closeTo(27.5, 3));
    expect(rectOf(find.text('Fresh Tomatoes')).top, closeTo(381.1, 5));
    expect(rectOf(find.text('\u20B948').first).left, closeTo(325, 3));
    expect(rectOf(find.text('\u20B948').first).top, closeTo(382.5, 5));
    expect(rectOf(find.text('/kg')).left, closeTo(366.5, 3));
    expect(
      rectOf(find.text('Vegetables, salem, Tamil Nadu')).top,
      closeTo(405.2, 5),
    );
    expect(rectOf(find.text('Details')).left, closeTo(43, 3));
    expect(rectOf(find.text('Details')).top, closeTo(451.2, 5));
    expect(rectOf(find.text('Performance')).top, closeTo(755.2, 5));
    expect(rectOf(find.text('Performance')).left, closeTo(43, 3));
    expect(rectOf(find.text('About this product')).left, closeTo(45.5, 3));
    expect(rectOf(find.text('About this product')).top, closeTo(1025.2, 5));
    expect(rectOf(find.text('How buyers get orders')).left, closeTo(46, 3));
    expect(rectOf(find.text('Buyer Pickup')).left, closeTo(90, 3));
    expect(rectOf(find.text('Buyer Pickup')).top, closeTo(1228.2, 5));
    expect(rectOf(find.text('Delivery')).top, closeTo(1286.2, 5));
    expect(rectOf(find.text('Delete product')).left, closeTo(167.5, 3));
    expect(rectOf(find.text('Delete product')).top, closeTo(1373.8, 5));

    final Rect photo = rectOf(assetImage('assets/product_details/photo.png'));
    expect(photo.left, closeTo(24, 1));
    expect(photo.top, closeTo(88, 1));
    expect(photo.width, closeTo(363.5, 1));
    expect(photo.height, closeTo(251.5, 1));

    final Rect illus = rectOf(assetImage('assets/product_details/illus.png'));
    expect(illus.left, closeTo(137, 1));
    expect(illus.top, closeTo(804, 1));
    expect(illus.width, closeTo(122, 1));
    expect(illus.height, closeTo(66, 1));

    final Rect tile = rectOf(
      assetImage('assets/product_details/tile_price.png'),
    );
    expect(tile.left, closeTo(44, 1));
    expect(tile.top, closeTo(490, 1));
    expect(tile.size, const Size(34, 34));

    final Rect pickup = rectOf(
      assetImage('assets/product_details/tile_pickup.png'),
    );
    expect(pickup.left, closeTo(46, 1));
    expect(pickup.top, closeTo(1226, 1));

    final Rect trash = rectOf(
      assetImage('assets/product_details/ic_trash.png'),
    );
    expect(trash.left, closeTo(149, 1));
    expect(trash.top, closeTo(1376.7, 1));
    expect(trash.size, const Size(11, 12.5));

    final Rect goBack = rectOf(find.text('Go back to order'));
    expect(goBack.center.dx, closeTo(206, 3));
    expect(goBack.center.dy, closeTo(1471.5, 5));

    final Rect share = rectOf(find.text('Share'));
    expect(share.center.dx, closeTo(206.5, 3));
    expect(share.center.dy, closeTo(957, 5));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProductDetailsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final double scale = 360 / 412;
    final Rect photo = tester.getRect(
      assetImage('assets/product_details/photo.png'),
    );
    expect(photo.left, closeTo(24 * scale, 1));
    expect(photo.width, closeTo(363.5 * scale, 1));
  });

  testWidgets('golden: 171 product details at 412x1515', (tester) async {
    await tester.runAsync(() async {
      final FontLoader loader = FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
      await loader.load();
    });
    await pumpProductDetails(tester);
    await tester.runAsync(() async {
      final BuildContext context = tester.element(
        find.byType(ProductDetailsScreen),
      );
      for (final String asset in _assets) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProductDetailsScreen),
      matchesGoldenFile('goldens/product_details_171.png'),
    );
  });
}
