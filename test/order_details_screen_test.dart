import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/widgets/page_header.dart';

/// Regression tests for bug SELLER-020: tapping a different order in
/// My Orders must open *that* order's own summary (unique order id, buyer,
/// products, quantities, total, status and progress) instead of the same
/// fixed one for every row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openDetails(WidgetTester tester, String orderId) async {
    await tester.tap(find.text(orderId));
    await tester.pumpAndSettle();
  }

  Future<void> backToOrders(WidgetTester tester) async {
    await tester.tap(find.byKey(PageHeader.backKey));
    await tester.pumpAndSettle();
  }

  testWidgets('every order opens its own details summary', (WidgetTester tester) async {
    // Tall viewport so the whole artboard (list and details) is on screen.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MyOrdersScreen()));
    await tester.pumpAndSettle();

    // Precondition: the orders on offer carry unique order ids.
    for (final String id in const <String>[
      '#NX4582',
      '#NX4581',
      '#NX4580',
      '#NX4579',
      '#NX4578',
    ]) {
      expect(
        find.text(id),
        findsOneWidget,
        reason: 'order id $id must appear exactly once in the list',
      );
    }

    // 1st order: accepted, four product lines, ₹2,400 total.
    await openDetails(tester, '#NX4582');
    expect(find.text('ORDER #NX4582'), findsOneWidget);
    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('Order Accepted'), findsOneWidget);
    expect(find.text('Fresh Tomatoes'), findsNWidgets(2));
    expect(find.text('20 kg'), findsOneWidget);
    expect(find.text('\u20B92,400'), findsNWidgets(2)); // items + grand total
    await backToOrders(tester);

    // 2nd order: a different buyer, id, products and total — and none of
    // the first order's values.
    await openDetails(tester, '#NX4581');
    expect(find.text('ORDER #NX4581'), findsOneWidget);
    expect(find.text('ORDER #NX4582'), findsNothing);
    expect(find.text('Hotel Green Leaf'), findsOneWidget);
    expect(find.text('Akash Stores'), findsNothing);
    expect(find.text('40 kg'), findsOneWidget);
    expect(find.text('\u20B91,400'), findsNWidgets(2));
    await backToOrders(tester);

    // 3rd order: pending, five lines, delivery fulfilment, ₹3,400 total.
    await openDetails(tester, '#NX4580');
    expect(find.text('ORDER #NX4580'), findsOneWidget);
    expect(find.text('Hotel Green Leaf'), findsNothing);
    expect(find.text('Annapoorna Mess'), findsOneWidget);
    expect(find.text('New Order'), findsOneWidget);
    expect(find.text('Home Delivery'), findsOneWidget);
    expect(find.text('11 kg'), findsOneWidget);
    expect(find.text('\u20B93,400'), findsNWidgets(2));
    await backToOrders(tester);

    // 5th order: delivered, its own buyer and ₹3,500 total.
    await openDetails(tester, '#NX4578');
    expect(find.text('ORDER #NX4578'), findsOneWidget);
    expect(find.text('Annapoorna Mess'), findsNothing);
    expect(find.text('Order Delivered'), findsOneWidget);
    expect(find.text('Karur, Tamil Nadu'), findsOneWidget);
    expect(find.text('\u20B93,500'), findsNWidgets(2));
    await backToOrders(tester);

    // Back on the Orders page, ready to open the next order again.
    expect(find.text('My Orders'), findsOneWidget);
  });
}
