import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/add_products_screen.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/widgets/bottom_nav_bar.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1154);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: MyOrdersScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // The route guard only opens authenticated screens while a session is
    // active; these tests exercise the in-app navigation directly.
    SessionStore.instance.startSession(
      phone: '9876543210',
      userName: 'Test Seller',
      method: 'login',
    );
  });

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

    final back = rectOf(find.byKey(const ValueKey('my-orders-back')));
    expect(back.left, closeTo(24, 1));
    expect(back.top, closeTo(24, 1));
    expect(back.size, const Size(26, 26));
    final title = rectOf(find.text('My Orders'));
    expect(title.left, closeTo(68, 2));
    expect(title.top, closeTo(28, 2));
    expect(title.height, closeTo(20, 1));
    expect(rectOf(find.text('Akash Stores')).left, closeTo(89, 2));
    expect(rectOf(find.text('Akash Stores')).top, closeTo(205, 3));
  });

  testWidgets('status tabs filter the order list', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('Hotel Green Leaf'), findsOneWidget);
    expect(find.text('Annapoorna Mess'), findsOneWidget);
    expect(find.text('Daily Needs'), findsNWidgets(2));
    expect(find.text('Delivered'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('order-filter-active')));
    await tester.pumpAndSettle();
    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('Hotel Green Leaf'), findsOneWidget);
    expect(find.text('Annapoorna Mess'), findsNothing);
    expect(find.text('Daily Needs'), findsNothing);
    expect(find.text('Delivered'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('order-filter-pending')));
    await tester.pumpAndSettle();
    expect(find.text('Annapoorna Mess'), findsOneWidget);
    expect(find.text('Akash Stores'), findsNothing);
    expect(find.text('Hotel Green Leaf'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('order-filter-confirmed')));
    await tester.pumpAndSettle();
    expect(find.text('Daily Needs'), findsOneWidget);
    expect(find.text('\u20B93,000'), findsOneWidget);
    expect(find.text('\u20B93,500'), findsNothing);
    expect(find.text('Annapoorna Mess'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('order-filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('Daily Needs'), findsNWidgets(2));
    expect(find.text('Annapoorna Mess'), findsOneWidget);
  });

  testWidgets('Sort by opens the sort sheet and reorders the list', (
    tester,
  ) async {
    await pumpScreen(tester);
    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    await tester.tap(find.byKey(const ValueKey('order-sort-button')));
    await tester.pumpAndSettle();
    expect(find.text('Newest first'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('order-sort-oldest')));
    await tester.pumpAndSettle();
    expect(find.text('Newest first'), findsNothing);

    final oldest = rectOf(find.text('\u20B93,000'));
    final newest = rectOf(find.text('Akash Stores'));
    expect(oldest.top, closeTo(241 + 105 - 49, 3));
    expect(oldest.top, lessThan(newest.top));

    await tester.tap(find.byKey(const ValueKey('order-sort-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('order-sort-priceHigh')));
    await tester.pumpAndSettle();

    final highest = rectOf(find.text('\u20B93,500'));
    final lowest = rectOf(find.text('\u20B91,400'));
    expect(highest.top, lessThan(lowest.top));
  });

  testWidgets('the bottom nav is pinned with Orders selected', (tester) async {
    await pumpScreen(tester);

    final nav = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
    expect(nav.selectedIndex, 2);
    expect(tester.getRect(find.byType(BottomNavBar)).bottom, closeTo(1154, 1));
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

  testWidgets('the bottom nav opens the Products tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(navText('Products'));
    await tester.pumpAndSettle();
    expect(find.byType(MyProductsScreen), findsOneWidget);
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
    await tester.pumpWidget(const MaterialApp(home: MyOrdersScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('My Orders'), findsOneWidget);
  });
}
