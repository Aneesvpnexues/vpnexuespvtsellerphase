import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/add_products_screen.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';
import 'package:seller_app/screens/product_details_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/widgets/bottom_nav_bar.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1008);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: MyProductsScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 123 products content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('My Products'), findsOneWidget);
    expect(find.text('Search vegetables...'), findsOneWidget);
    expect(find.text('12 Products'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsNWidgets(3));
    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.text('Draft'), findsNWidgets(2));
    expect(find.text('Fresh Tomatoes'), findsNWidgets(4));
    expect(find.text('\u20B948'), findsNWidgets(4));
    expect(find.text('/ kg'), findsNWidgets(4));
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('layout matches the 412x1008 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('My Products')).left, closeTo(58, 2));
    expect(rectOf(find.text('My Products')).top, closeTo(24, 3));
    expect(rectOf(find.text('Fresh Tomatoes').first).left, closeTo(146, 2));
    expect(rectOf(find.text('Fresh Tomatoes').first).top, closeTo(209, 3));
  });

  testWidgets('all four product cards open the product details screen', (
    tester,
  ) async {
    await pumpScreen(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Fresh Tomatoes').at(i));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailsScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(ProductDetailsScreen))).pop();
      await tester.pumpAndSettle();
    }
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
