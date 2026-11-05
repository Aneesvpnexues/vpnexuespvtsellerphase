import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';
import 'package:seller_app/screens/order_details_screen.dart';
import 'package:seller_app/screens/order_ready_screen.dart';
import 'package:seller_app/widgets/bottom_nav_bar.dart';

Future<void> pumpDetails(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1501);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OrderDetailsScreen()));
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

  testWidgets('renders the 135 order details content', (tester) async {
    await pumpDetails(tester);

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Buyer Pickup'), findsNWidgets(2));
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('ORDER #NX4582'), findsOneWidget);
    expect(find.text('New Order'), findsOneWidget);
    expect(find.text('Waiting for your response'), findsOneWidget);
    expect(find.text('12 Mar 2024, 10:24 AM'), findsOneWidget);
    expect(find.text('Active'), findsNWidgets(2));
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('+91 12345 67890'), findsOneWidget);
    expect(find.text('Retailer'), findsOneWidget);
    expect(find.text('Call'), findsNWidgets(2));
    expect(find.text('Order Items'), findsOneWidget);
    expect(find.text('Fresh Tomatoes'), findsOneWidget);
    expect(find.text('50 kg'), findsOneWidget);
    expect(find.text('\u20B924/kg'), findsOneWidget);
    expect(find.text('\u20B91,400'), findsOneWidget);
    expect(find.text('Green Chillies'), findsNWidgets(2));
    expect(find.text('30 kg'), findsOneWidget);
    expect(find.text('20 kg'), findsOneWidget);
    expect(find.text('40 kg'), findsNothing);
    expect(find.text('\u20B940/kg'), findsOneWidget);
    expect(find.text('\u20B922/kg'), findsOneWidget);
    expect(find.text('\u20B91,200'), findsOneWidget);
    expect(find.text('\u20B9440'), findsOneWidget);
    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.text('Items Total'), findsOneWidget);
    expect(find.text('Delivery Charges'), findsOneWidget);
    expect(find.text('Total Amount'), findsOneWidget);
    expect(find.text('\u20B92,840'), findsNWidgets(2));
    expect(find.text('\u20B90'), findsOneWidget);
    expect(find.text('Delivery Details'), findsOneWidget);
    expect(find.text('Expected Pickup Date'), findsOneWidget);
    expect(find.text('25 Mar 2024'), findsOneWidget);
    expect(find.text('Buyer Note'), findsOneWidget);
    expect(find.text('Slide to accept order'), findsOneWidget);
  });

  testWidgets('layout matches the 412x1501 design geometry', (tester) async {
    await pumpDetails(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Order Details')).left, closeTo(68, 3));
    expect(rectOf(find.text('Order Details')).top, closeTo(22, 4));
    expect(rectOf(find.text('New Order')).left, closeTo(41, 3));
    expect(rectOf(find.text('New Order')).top, closeTo(155, 5));
    expect(rectOf(find.text('ORDER #NX4582')).left, closeTo(41, 3));
    expect(rectOf(find.text('ORDER #NX4582')).top, closeTo(135, 4));
    expect(rectOf(find.text('Akash Stores')).left, closeTo(119, 3));
    expect(rectOf(find.text('Akash Stores')).top, closeTo(389, 5));
    expect(rectOf(find.text('Fresh Tomatoes')).left, closeTo(107, 3));
    expect(rectOf(find.text('Fresh Tomatoes')).top, closeTo(605, 5));
    expect(rectOf(find.text('Total Amount')).left, closeTo(56, 3));
    expect(rectOf(find.text('Total Amount')).top, closeTo(961, 6));
    expect(rectOf(find.text('Slide to accept order')).left, closeTo(133, 3));
    expect(rectOf(find.text('Slide to accept order')).top, closeTo(1386, 5));
  });

  testWidgets('the slide to accept button opens the ready order screen', (
    tester,
  ) async {
    await pumpDetails(tester);

    expect(find.text('Slide to accept order'), findsOneWidget);

    await tester.tapAt(const Offset(203, 1400));
    await tester.pumpAndSettle();

    expect(find.byType(OrderReadyScreen), findsOneWidget);
    expect(find.text('Packing checklist'), findsOneWidget);
  });

  testWidgets('sliding the knob across opens the ready order screen', (
    tester,
  ) async {
    await pumpDetails(tester);

    await tester.dragFrom(const Offset(50, 1400), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.byType(OrderReadyScreen), findsOneWidget);
    expect(find.text('Packing checklist'), findsOneWidget);
  });

  testWidgets('swiping anywhere on the bar opens the ready order screen', (
    tester,
  ) async {
    await pumpDetails(tester);

    await tester.dragFrom(const Offset(200, 1400), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.byType(OrderReadyScreen), findsOneWidget);
    expect(find.text('Packing checklist'), findsOneWidget);
  });

  testWidgets('a short left to right swipe opens the ready order screen', (
    tester,
  ) async {
    await pumpDetails(tester);

    await tester.dragFrom(const Offset(60, 1400), const Offset(100, 0));
    await tester.pumpAndSettle();

    expect(find.byType(OrderReadyScreen), findsOneWidget);
  });

  testWidgets('a diagonal swipe that starts vertical still slides the bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: OrderDetailsScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Slide to accept order'));
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Slide to accept order')),
    );
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveBy(const Offset(320, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(OrderReadyScreen), findsOneWidget);
  });

  testWidgets('a short slide springs back and does not accept the order', (
    tester,
  ) async {
    await pumpDetails(tester);

    await tester.dragFrom(const Offset(50, 1400), const Offset(30, 0));
    await tester.pumpAndSettle();

    expect(find.byType(OrderReadyScreen), findsNothing);
    expect(find.text('Slide to accept order'), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: OrderDetailsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('New Order'), findsOneWidget);
  });

  testWidgets('the first order block opens the order details screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1154);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyOrdersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Akash Stores'), findsOneWidget);

    await tester.tapAt(const Offset(204, 269));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailsScreen), findsOneWidget);
    expect(find.text('ORDER #NX4582'), findsOneWidget);
  });

  testWidgets('the bottom nav switches between the orders and products tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1154);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyOrdersScreen()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavBar),
        matching: find.text('Products'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MyProductsScreen), findsOneWidget);
    expect(find.text('My Products'), findsOneWidget);
  });
}

