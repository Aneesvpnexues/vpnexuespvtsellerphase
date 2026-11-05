import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/order_delivery_screen.dart';
import 'package:seller_app/screens/order_pickup_code_screen.dart';

Future<void> pumpDelivery(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OrderDeliveryScreen()));
  await tester.pumpAndSettle();
}

/// The 26px arrow image sits centred in the 50px slide knob, so its rect is
/// used to read the knob's travel (left - 12).
Finder slideArrow() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == 'assets/order/ic_slide.png',
);

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

  testWidgets('renders the 141 out for delivery content', (tester) async {
    await pumpDelivery(tester);

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Buyer Pickup'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('ORDER #NX4582'), findsOneWidget);
    expect(find.text('Ready for Pickup'), findsOneWidget);
    expect(find.text('Out for delivery'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('BUYER DETAILS'), findsOneWidget);
    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('Retailer'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('+91 12345 67890'), findsOneWidget);
    expect(find.text('Call'), findsNWidgets(2));
    expect(find.text('Delivery Details'), findsOneWidget);
    expect(find.text('Expected Pickup Date'), findsOneWidget);
    expect(find.text('24 Mar 2024'), findsOneWidget);
    expect(
      find.text('Ask the buyer for their 4-digit code at handover'),
      findsOneWidget,
    );
    expect(find.text('Slide when the buyer arrives'), findsOneWidget);
    expect(find.text('Packing checklist'), findsNothing);
    expect(find.text('3/3 packed'), findsNothing);
    expect(find.text('Order Accepted'), findsNothing);
    expect(find.text('Slide to mark as ready'), findsNothing);
  });

  testWidgets('the delivery blurb breaks after "your" like the design', (
    tester,
  ) async {
    await pumpDelivery(tester);

    expect(
      find.text('Waiting for the buyer to arrive at your'),
      findsOneWidget,
    );
    expect(find.text('location'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpDelivery(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // The canvas trims the 49px status bar, so screen y = design y - 49.
    expect(rectOf(find.text('Order Details')).left, closeTo(68, 3));
    expect(rectOf(find.text('Order Details')).top, closeTo(24, 4));
    expect(rectOf(find.text('ORDER #NX4582')).left, closeTo(41, 3));
    expect(rectOf(find.text('ORDER #NX4582')).top, closeTo(135, 4));
    expect(rectOf(find.text('Ready for Pickup')).left, closeTo(41, 3));
    expect(rectOf(find.text('Ready for Pickup')).top, closeTo(157, 5));
    expect(rectOf(find.text('Out for delivery')).left, closeTo(288, 3));
    expect(rectOf(find.text('Out for delivery')).top, closeTo(131, 5));
    expect(rectOf(find.text('Akash Stores')).left, closeTo(119, 3));
    expect(rectOf(find.text('Akash Stores')).top, closeTo(353, 5));
    expect(rectOf(find.text('Delivery Details')).left, closeTo(108, 3));
    expect(rectOf(find.text('Delivery Details')).top, closeTo(520, 5));
    expect(
      rectOf(find.text('Waiting for the buyer to arrive at your')).left,
      closeTo(108, 3),
    );
    expect(
      rectOf(find.text('Waiting for the buyer to arrive at your')).top,
      closeTo(542, 5),
    );
    expect(rectOf(find.text('location')).top, closeTo(557, 5));
    expect(rectOf(find.text('Expected Pickup Date')).left, closeTo(91, 3));
    expect(rectOf(find.text('Expected Pickup Date')).top, closeTo(610, 5));
    expect(rectOf(find.text('24 Mar 2024')).left, closeTo(91, 3));
    expect(rectOf(find.text('24 Mar 2024')).top, closeTo(623, 5));
    expect(
      rectOf(find.text('Ask the buyer for their 4-digit code at handover'))
          .left,
      closeTo(76, 3),
    );
    expect(
      rectOf(find.text('Ask the buyer for their 4-digit code at handover')).top,
      closeTo(671, 5),
    );
    expect(
      rectOf(find.text('Slide when the buyer arrives')).left,
      closeTo(117, 3),
    );
    expect(
      rectOf(find.text('Slide when the buyer arrives')).top,
      closeTo(813, 5),
    );

    expect(rectOf(slideArrow()).left, closeTo(40, 2));
    expect(rectOf(slideArrow()).top, closeTo(814, 2));
  });

  testWidgets('the five step labels sit at the design x offsets', (
    tester,
  ) async {
    await pumpDelivery(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);
    Finder labelAt(String text, double expectedLeft) {
      final int count = find.text(text).evaluate().length;
      for (int i = 0; i < count; i++) {
        if ((rectOf(find.text(text).at(i)).left - expectedLeft).abs() < 12) {
          return find.text(text).at(i);
        }
      }
      return find.text(text).first;
    }

    const List<String> labels = <String>[
      'Active',
      'Accepted',
      'Ready',
      'Pickup',
      'Completed',
    ];
    const List<double> lefts = <double>[63, 120, 194, 257, 310];

    for (int i = 0; i < labels.length; i++) {
      final double expectedLeft = lefts[i];
      final Rect rect = rectOf(labelAt(labels[i], expectedLeft));
      expect(rect.left, closeTo(expectedLeft, 3));
      expect(rect.top, closeTo(249, 5));
    }
  });

  testWidgets(
    'a short slide springs back and a full one opens the pickup code',
    (tester) async {
      await pumpDelivery(tester);

      final origin = tester.getTopLeft(find.byType(MaterialApp));
      Rect rectOf(Finder finder) =>
          tester.getRect(finder).translate(-origin.dx, -origin.dy);

      expect(rectOf(slideArrow()).left, closeTo(40, 2));

      await tester.drag(slideArrow(), const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(rectOf(slideArrow()).left, closeTo(40, 2));

      await tester.drag(slideArrow(), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(find.byType(OrderPickupCodeScreen), findsOneWidget);
      expect(find.text('Enter pickup code'), findsOneWidget);
    },
  );

  testWidgets('swiping anywhere on the bar opens the pickup code', (
    tester,
  ) async {
    await pumpDelivery(tester);

    await tester.drag(
      find.text('Slide when the buyer arrives'),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OrderPickupCodeScreen), findsOneWidget);
  });

  testWidgets(
    'a diagonal swipe that starts vertical still opens the pickup code',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: OrderDeliveryScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Slide when the buyer arrives'));
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Slide when the buyer arrives')),
      );
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.moveBy(const Offset(320, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(OrderPickupCodeScreen), findsOneWidget);
    },
  );

  testWidgets('tapping the slide settles the knob without navigating', (
    tester,
  ) async {
    await pumpDelivery(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    await tester.tap(find.text('Slide when the buyer arrives'));
    await tester.pumpAndSettle();

    expect(rectOf(slideArrow()).left, closeTo(346, 2));
    expect(find.byType(OrderDeliveryScreen), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: OrderDeliveryScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Delivery Details'), findsOneWidget);
  });
}
