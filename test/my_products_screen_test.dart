import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/product_store.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/add_products_screen.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';
import 'package:seller_app/screens/product_details_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/widgets/bottom_nav_bar.dart';
import 'package:seller_app/widgets/page_header.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1008);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: MyProductsScreen()));
  await tester.pumpAndSettle();
}

final _photoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6Q'
  'AAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhX'
  'Y/jPwPAfAAUAAf+mXJtdAAAAAElFTkSuQmCC',
);

Product _product({
  String name = 'Brinjal',
  double price = 32,
  int quantity = 50,
  String description = '',
  ProductStatus status = ProductStatus.active,
  List<ProductPhoto> photos = const <ProductPhoto>[],
}) {
  return ProductStore.instance.addProduct(
    name: name,
    category: 'Vegetables',
    price: price,
    unit: 'kg',
    quantity: quantity,
    description: description,
    status: status,
    photos: photos,
  );
}

void main() {
  setUp(() {
    ProductStore.instance.clear();
    // The route guard only opens authenticated screens while a session is
    // active; these tests exercise the in-app navigation directly.
    SessionStore.instance.startSession(
      phone: '9876543210',
      userName: 'Test Seller',
      method: 'login',
    );
    AddProductsScreen.debugPhotoPicker =
        () async => ProductPhoto(bytes: _photoBytes);
    AddProductsScreen.debugProductSaver = (
      ProductDraft draft,
      List<ProductPhoto> photos,
    ) async {
      return ProductStore.instance.addProduct(
        name: draft.name,
        category: draft.category,
        price: draft.price,
        unit: draft.unit,
        quantity: draft.quantity,
        description: draft.description,
        status: draft.status,
        photos: photos,
      );
    };
  });

  tearDown(() {
    AddProductsScreen.debugPhotoPicker = null;
    AddProductsScreen.debugProductSaver = null;
  });

  testWidgets('renders the empty 123 products content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('My Products'), findsOneWidget);
    expect(find.text('Search vegetables...'), findsOneWidget);
    expect(find.text('0 Products'), findsOneWidget);
    expect(find.text('12 Products'), findsNothing);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.byKey(const ValueKey('products-empty')), findsOneWidget);
    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Your listings will appear here'), findsOneWidget);
    expect(find.text('Fresh Tomatoes'), findsNothing);
    expect(find.text('\u20B948'), findsNothing);
    expect(find.text('/ kg'), findsNothing);
    expect(find.text('Publish'), findsNothing);
    expect(find.text('Add product'), findsNWidgets(2));
    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('layout matches the 412x1008 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('My Products')).left, closeTo(68, 2));
    expect(rectOf(find.text('My Products')).top, closeTo(28, 3));
    expect(
      rectOf(find.byKey(const ValueKey('products-empty'))).left,
      closeTo(24, 2),
    );
    expect(
      rectOf(find.byKey(const ValueKey('products-empty'))).top,
      closeTo(203, 3),
    );
  });

  testWidgets('the header back opens the Home tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(PageHeader.backKey));
    await tester.pumpAndSettle();

    expect(find.byType(MyProductsScreen), findsNothing);
    expect(find.byType(SellerHomeScreen), findsOneWidget);
  });

  testWidgets('renders store products and removes dummy rows', (tester) async {
    _product(photos: <ProductPhoto>[ProductPhoto(bytes: _photoBytes)]);
    _product(
      name: 'Okra',
      price: 40,
      quantity: 20,
      status: ProductStatus.draft,
    );

    await pumpScreen(tester);

    expect(find.text('2 Products'), findsOneWidget);
    expect(find.byKey(const ValueKey('products-empty')), findsNothing);
    expect(find.text('Okra'), findsOneWidget);
    expect(find.text('20 kg available'), findsOneWidget);
    expect(find.text('\u20B940'), findsOneWidget);
    expect(find.text('Brinjal'), findsOneWidget);
    expect(find.text('50 kg available'), findsOneWidget);
    expect(find.text('\u20B932'), findsOneWidget);
    expect(find.text('Draft'), findsNWidgets(2));
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Fresh Tomatoes'), findsNothing);

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('my-product-P1')),
        matching: find.byType(Image),
      ),
    );
    expect(image.image, isA<MemoryImage>());
  });

  testWidgets('lists every product even when ProductStore.userId is set',
      (tester) async {
    // ProductStore.userId is the seller profile id (and the Settings mobile
    // field used to write into it). It must never hide rows: this app has a
    // single seller, and sellers_products.user_id cannot hold text ids anyway.
    ProductStore.instance.userId = '9876543210';
    addTearDown(() => ProductStore.instance.userId = '');
    _product(name: 'Brinjal');

    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('products-empty')), findsNothing);
    expect(find.text('1 Product'), findsOneWidget);
    expect(find.text('Brinjal'), findsOneWidget);
  });

  testWidgets('status tabs filter the product list', (tester) async {
    _product(name: 'Tomato');
    _product(name: 'Okra', quantity: 0, status: ProductStatus.outOfStock);
    _product(name: 'Chilli', status: ProductStatus.draft);
    _product(name: 'Brinjal');

    await pumpScreen(tester);
    expect(find.text('4 Products'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Okra'), findsOneWidget);
    expect(find.text('Chilli'), findsOneWidget);
    expect(find.text('Brinjal'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('products-filter-active')));
    await tester.pumpAndSettle();
    expect(find.text('2 Products'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Brinjal'), findsOneWidget);
    expect(find.text('Okra'), findsNothing);
    expect(find.text('Chilli'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('products-filter-out-of-stock')),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 Product'), findsOneWidget);
    expect(find.text('Okra'), findsOneWidget);
    expect(find.text('Tomato'), findsNothing);
    expect(find.text('Brinjal'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('products-filter-draft')));
    await tester.pumpAndSettle();
    expect(find.text('1 Product'), findsOneWidget);
    expect(find.text('Chilli'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Tomato'), findsNothing);
    expect(find.text('Okra'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('products-filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('4 Products'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Okra'), findsOneWidget);
    expect(find.text('Chilli'), findsOneWidget);
    expect(find.text('Brinjal'), findsOneWidget);
  });

  testWidgets('search filters products by name and category', (tester) async {
    _product(name: 'Tomato');
    _product(name: 'Okra');

    await pumpScreen(tester);
    await tester.enterText(find.byKey(const ValueKey('products-search')), 'ok');
    await tester.pumpAndSettle();
    expect(find.text('1 Product'), findsOneWidget);
    expect(find.text('Okra'), findsOneWidget);
    expect(find.text('Tomato'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('products-search')),
      'vegetables',
    );
    await tester.pumpAndSettle();
    expect(find.text('2 Products'), findsOneWidget);
    expect(find.text('Okra'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('products-search')),
      'nothing',
    );
    await tester.pumpAndSettle();
    expect(find.text('0 Products'), findsOneWidget);
    expect(find.text('No products found'), findsOneWidget);
    expect(find.text('Try another filter or search'), findsOneWidget);
    expect(find.text('No products yet'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('products-search')), '');
    await tester.pumpAndSettle();
    expect(find.text('2 Products'), findsOneWidget);
    expect(find.text('Okra'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
  });

  testWidgets('keeps the promo card above the pinned nav for long lists', (
    tester,
  ) async {
    for (var i = 0; i < 6; i++) {
      _product(name: 'Product $i');
    }

    await pumpScreen(tester);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    final promo = tester.getRect(find.byKey(const ValueKey('products-promo')));
    final nav = tester.getRect(find.byType(BottomNavBar));
    expect(promo.bottom, lessThanOrEqualTo(nav.top));
  });

  testWidgets('a product row opens its product details', (tester) async {
    _product(
      description: 'Fresh brinjal from Salem',
      photos: <ProductPhoto>[ProductPhoto(bytes: _photoBytes)],
    );

    await pumpScreen(tester);
    await tester.tap(find.text('Brinjal'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Brinjal'), findsOneWidget);
    expect(find.text('Vegetables, 50 kg available'), findsOneWidget);
    expect(find.text('\u20B932'), findsNWidgets(2));
    expect(find.text('Fresh brinjal from Salem'), findsOneWidget);

    final Image image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('product-details-photo')),
        matching: find.byType(Image),
      ),
    );
    expect(image.image, isA<MemoryImage>());
  });

  testWidgets('the count and rows update when the store changes', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('0 Products'), findsOneWidget);
    expect(find.text('No products yet'), findsOneWidget);

    _product(name: 'Carrot', price: 45, quantity: 30);
    await tester.pumpAndSettle();

    expect(find.text('1 Product'), findsOneWidget);
    expect(find.text('No products yet'), findsNothing);
    expect(find.text('Carrot'), findsOneWidget);
    expect(find.text('\u20B945'), findsOneWidget);
  });

  testWidgets('Continue adds the product and returns to My Products', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('products-empty-add')));
    await tester.pumpAndSettle();
    expect(find.byType(AddProductsScreen), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('product-name')),
      'Green Chilli',
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-price')),
      '24',
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('add-photo')),
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-photo')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('add-product-continue')),
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-product-continue')));
    await tester.pumpAndSettle();

    expect(find.byType(AddProductsScreen), findsNothing);
    expect(find.byType(MyProductsScreen), findsOneWidget);
    expect(find.text('Green Chilli'), findsOneWidget);
    expect(find.text('\u20B924'), findsOneWidget);
    expect(find.text('1 Product'), findsOneWidget);
    expect(find.text('Product added'), findsOneWidget);
  });

  testWidgets('the bottom nav is pinned with Products selected', (
    tester,
  ) async {
    await pumpScreen(tester);

    final nav = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
    expect(nav.selectedIndex, 1);
    expect(tester.getRect(find.byType(BottomNavBar)).bottom, closeTo(1008, 1));
  });

  Finder navText(String label) => find.descendant(
    of: find.byType(BottomNavBar),
    matching: find.text(label),
  );

  testWidgets('the bottom nav opens the Home tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(navText('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(SellerHomeScreen), findsOneWidget);
  });

  testWidgets('the bottom nav opens the Orders tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(navText('Orders'));
    await tester.pumpAndSettle();
    expect(find.byType(MyOrdersScreen), findsOneWidget);
  });

  testWidgets('the bottom nav opens the Profile tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(navText('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('the bottom nav FAB opens the add product flow', (tester) async {
    await pumpScreen(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavBar),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AddProductsScreen), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyProductsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('My Products'), findsOneWidget);
  });
}
