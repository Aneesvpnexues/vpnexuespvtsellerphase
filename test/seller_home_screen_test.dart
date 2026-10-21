import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1071);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: SellerHomeScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 117 home content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Hello,'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('ACTIVE ORDERS'), findsOneWidget);
    expect(find.text('2 new orders'), findsOneWidget);
    expect(find.text('View orders'), findsOneWidget);
    expect(find.text('Waiting for your response'), findsOneWidget);
    expect(find.text('My Products'), findsOneWidget);
    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('Spinach'), findsOneWidget);
    expect(find.text('Sales Overview'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('\u20B924,850'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('2 New orders'), findsOneWidget);
    expect(find.text('Tomatoes low'), findsOneWidget);
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

  testWidgets('the bottom nav opens the products tab', (tester) async {
    await pumpScreen(tester);

    await tester.tapAt(const Offset(130, 987));
    await tester.pumpAndSettle();
    expect(find.byType(MyProductsScreen), findsOneWidget);
  });

  testWidgets('the bottom nav opens the orders tab', (tester) async {
    await pumpScreen(tester);

    await tester.tapAt(const Offset(294, 987));
    await tester.pumpAndSettle();
    expect(find.byType(MyOrdersScreen), findsOneWidget);
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
