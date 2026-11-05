import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/product_store.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/add_products_screen.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';
import 'package:seller_app/screens/product_details_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/widgets/bottom_nav_bar.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1071);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: SellerHomeScreen()));
  await tester.pumpAndSettle();
}

final _photoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6Q'
  'AAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhX'
  'Y/jPwPAfAAUAAf+mXJtdAAAAAElFTkSuQmCC',
);

void main() {
  setUp(() {
    ProductStore.instance.clear();
    SellerProfileStore.instance.reset();
    // The route guard only opens authenticated screens while a session is
    // active; these tests exercise the in-app navigation directly.
    SessionStore.instance.startSession(
      phone: '9876543210',
      userName: 'Test Seller',
      method: 'login',
    );
  });

  testWidgets('greeting uses the saved seller name', (tester) async {
    SellerProfileStore.instance.save(
      name: 'Sita Devi',
      mobile: '9876543210',
      email: '',
      sellerType: SellerType.trader,
    );

    await pumpScreen(tester);

    expect(find.text('Sita Devi'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsNothing);
  });

  testWidgets('renders the 117 home content with no dummy products', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Hello,'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('ACTIVE ORDERS'), findsOneWidget);
    expect(find.text('2 new orders'), findsOneWidget);
    expect(find.text('View orders'), findsOneWidget);
    expect(find.text('Waiting for your response'), findsOneWidget);
    expect(find.text('My Products'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-empty-products')), findsOneWidget);
    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Start selling today'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('Tomatoes'), findsNothing);
    expect(find.text('Spinach'), findsNothing);
    expect(find.text('Carrots'), findsNothing);
    expect(find.text('Sales Overview'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('\u20B924,850'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('2 New orders'), findsOneWidget);
    expect(find.text('Tomatoes low'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Orders'), findsNWidgets(2));
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('layout matches the 412x1071 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Hello,')).left, closeTo(24, 2));
    expect(rectOf(find.text('Hello,')).top, closeTo(24, 2));
    expect(rectOf(find.text('ACTIVE ORDERS')).left, closeTo(45, 2));
    expect(rectOf(find.text('ACTIVE ORDERS')).top, closeTo(117, 3));
    expect(rectOf(find.text('My Products')).left, closeTo(25, 2));
    expect(rectOf(find.text('Sales Overview')).left, closeTo(25, 2));
    expect(rectOf(find.text('Needs Attention')).left, closeTo(25, 2));
  });

  testWidgets('renders products added to the store', (tester) async {
    ProductStore.instance.addProduct(
      name: 'Brinjal',
      category: 'Vegetables',
      price: 32,
      unit: 'kg',
      quantity: 50,
      description: 'Fresh brinjal',
      status: ProductStatus.active,
      photos: <ProductPhoto>[ProductPhoto(bytes: _photoBytes)],
    );

    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('home-empty-products')), findsNothing);
    expect(find.text('Brinjal'), findsOneWidget);
    expect(find.text('50 kg available'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-product-P1')), findsOneWidget);

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('home-product-P1')),
        matching: find.byType(Image),
      ),
    );
    expect(image.image, isA<MemoryImage>());
  });

  testWidgets('a home product opens its product details', (tester) async {
    ProductStore.instance.addProduct(
      name: 'Brinjal',
      category: 'Vegetables',
      price: 32,
      unit: 'kg',
      quantity: 50,
      description: 'Fresh brinjal from Salem',
      status: ProductStatus.active,
      photos: <ProductPhoto>[ProductPhoto(bytes: _photoBytes)],
    );

    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('home-product-P1')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Brinjal'), findsOneWidget);
    expect(find.text('Vegetables, 50 kg available'), findsOneWidget);
    expect(find.text('\u20B932'), findsNWidgets(2));
    expect(find.text('Fresh brinjal from Salem'), findsOneWidget);
  });

  testWidgets('updates the product strip when the store changes', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('No products yet'), findsOneWidget);

    ProductStore.instance.addProduct(
      name: 'Okra',
      category: 'Vegetables',
      price: 40,
      unit: 'kg',
      quantity: 20,
      description: '',
      status: ProductStatus.active,
    );
    await tester.pumpAndSettle();

    expect(find.text('No products yet'), findsNothing);
    expect(find.text('Okra'), findsOneWidget);
  });

  testWidgets('shows a low stock attention row from store data', (
    tester,
  ) async {
    ProductStore.instance.addProduct(
      name: 'Spinach',
      category: 'Vegetables',
      price: 25,
      unit: 'kg',
      quantity: 5,
      description: '',
      status: ProductStatus.active,
    );

    await pumpScreen(tester);

    expect(find.text('Spinach low'), findsOneWidget);
    expect(find.text('Only 5kg remaining'), findsOneWidget);
  });

  testWidgets('the bottom nav is pinned with Home selected', (tester) async {
    await pumpScreen(tester);

    final nav = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
    expect(nav.selectedIndex, 0);
    expect(tester.getRect(find.byType(BottomNavBar)).bottom, closeTo(1071, 1));
  });

  Finder navText(String label) => find.descendant(
    of: find.byType(BottomNavBar),
    matching: find.text(label),
  );

  testWidgets('the bottom nav opens the products tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(navText('Products'));
    await tester.pumpAndSettle();
    expect(find.byType(MyProductsScreen), findsOneWidget);
  });

  testWidgets('the bottom nav opens the orders tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(navText('Orders'));
    await tester.pumpAndSettle();
    expect(find.byType(MyOrdersScreen), findsOneWidget);
  });

  testWidgets('the bottom nav opens the profile tab', (tester) async {
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
    await tester.pumpWidget(const MaterialApp(home: SellerHomeScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
  });
}
