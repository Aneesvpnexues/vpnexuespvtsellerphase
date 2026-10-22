import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/my_orders_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1154);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: MyOrdersScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 132 orders content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Search vegetables...'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(2));
    expect(find.text('Confirmed'), findsNWidgets(2));
    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('Hotel Green Leaf'), findsOneWidget);
    expect(find.text('Annapoorna Mess'), findsOneWidget);
    expect(find.text('Daily Needs'), findsNWidgets(2));
    expect(find.text('#NX4582'), findsOneWidget);
    expect(find.text('\u20B92,400'), findsOneWidget);
    expect(find.text('Accepted'), findsNWidgets(2));
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('layout matches the 412x1154 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('My Orders')).left, closeTo(74, 2));
    expect(rectOf(find.text('My Orders')).top, closeTo(24, 3));
    expect(rectOf(find.text('Akash Stores')).left, closeTo(89, 2));
    expect(rectOf(find.text('Akash Stores')).top, closeTo(205, 3));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyOrdersScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('My Orders'), findsOneWidget);
  });
}
