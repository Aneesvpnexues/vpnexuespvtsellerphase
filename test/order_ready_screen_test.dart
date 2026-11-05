import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/order_delivery_screen.dart';
import 'package:seller_app/screens/order_ready_screen.dart';

Future<void> pumpReady(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OrderReadyScreen()));
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

  testWidgets('renders the 140 order ready content', (tester) async {
    await pumpReady(tester);

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Buyer Pickup'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('ORDER #NX4582'), findsOneWidget);
    expect(find.text('Order Accepted'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Ready'), findsNWidgets(2));
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('BUYER DETAILS'), findsOneWidget);
    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('Retailer'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('+91 12345 67890'), findsOneWidget);
    expect(find.text('Call'), findsNWidgets(2));
    expect(find.text('Packing checklist'), findsOneWidget);
    expect(find.text('3/3 packed'), findsOneWidget);
    expect(find.text('Fresh Tomatoes'), findsOneWidget);
    expect(find.text('Green Chillies'), findsNWidgets(2));
    expect(find.text('50 kg'), findsOneWidget);
    expect(find.text('30 kg'), findsOneWidget);
    expect(find.text('20 kg'), findsOneWidget);
    expect(find.text('Slide to mark as ready'), findsOneWidget);
    expect(find.text('0/3 packed'), findsNothing);
    expect(find.text('Pack all items to continue'), findsNothing);
  });

  testWidgets('the completed step draws a white tick without a white box', (
    tester,
  ) async {
    await pumpReady(tester);

    expect(
      find.image(const AssetImage('assets/order/ic_step_tick_white.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/order/ic_step_tick.png')),
      findsNothing,
    );
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpReady(tester);

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

    // The canvas trims the 49px status bar, so screen y = design y - 49.
    expect(rectOf(find.text('Order Details')).left, closeTo(68, 3));
    expect(rectOf(find.text('Order Details')).top, closeTo(22, 4));
    expect(rectOf(find.text('ORDER #NX4582')).left, closeTo(41, 3));
    expect(rectOf(find.text('ORDER #NX4582')).top, closeTo(135, 4));
    expect(rectOf(find.text('Order Accepted')).left, closeTo(41, 3));
    expect(rectOf(find.text('Order Accepted')).top, closeTo(157, 5));
    expect(rectOf(find.text('Akash Stores')).left, closeTo(119, 3));
    expect(rectOf(find.text('Akash Stores')).top, closeTo(353, 5));
    expect(rectOf(find.text('Packing checklist')).left, closeTo(80, 3));
    expect(rectOf(find.text('Packing checklist')).top, closeTo(522, 5));
    expect(rectOf(find.text('3/3 packed')).left, closeTo(304, 3));
    expect(rectOf(find.text('3/3 packed')).top, closeTo(523, 5));
    expect(rectOf(find.text('Fresh Tomatoes')).left, closeTo(107, 3));
    expect(rectOf(find.text('Fresh Tomatoes')).top, closeTo(590, 5));
    expect(rectOf(find.text('Slide to mark as ready')).left, closeTo(133, 3));
    expect(rectOf(find.text('Slide to mark as ready')).top, closeTo(813, 5));

    // The Ready hero pill sits at the right end of the hero.
    final Rect pill = rectOf(labelAt('Ready', 308));
    expect(pill.left, closeTo(308, 3));
    expect(pill.top, closeTo(131, 5));

    expect(rectOf(slideArrow()).left, closeTo(40, 2));
    expect(rectOf(slideArrow()).top, closeTo(814, 2));
  });

  testWidgets('the five step labels sit at the design x offsets', (
    tester,
  ) async {
    await pumpReady(tester);

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

  testWidgets('a short slide springs back and a full one opens 141', (
    tester,
  ) async {
    await pumpReady(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(slideArrow()).left, closeTo(40, 2));

    await tester.drag(slideArrow(), const Offset(50, 0));
    await tester.pumpAndSettle();
    expect(rectOf(slideArrow()).left, closeTo(40, 2));
    expect(find.byType(OrderDeliveryScreen), findsNothing);

    await tester.drag(slideArrow(), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.byType(OrderDeliveryScreen), findsOneWidget);
  });

  testWidgets('swiping anywhere on the bar opens 141', (tester) async {
    await pumpReady(tester);

    await tester.drag(
      find.text('Slide to mark as ready'),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OrderDeliveryScreen), findsOneWidget);
  });

  testWidgets('tapping the slide settles the knob without navigating', (
    tester,
  ) async {
    await pumpReady(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    await tester.tap(find.text('Slide to mark as ready'));
    await tester.pumpAndSettle();

    expect(rectOf(slideArrow()).left, closeTo(346, 2));
    expect(find.byType(OrderReadyScreen), findsOneWidget);
  });

  testWidgets('each checklist row toggles independently', (tester) async {
    await pumpReady(tester);

    expect(find.text('3/3 packed'), findsOneWidget);

    await tester.tap(find.text('Fresh Tomatoes'));
    await tester.pumpAndSettle();
    expect(find.text('2/3 packed'), findsOneWidget);

    await tester.tap(find.text('Green Chillies').first);
    await tester.pumpAndSettle();
    expect(find.text('1/3 packed'), findsOneWidget);

    await tester.tap(find.text('Green Chillies').last);
    await tester.pumpAndSettle();
    expect(find.text('0/3 packed'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order_ready/ic_badge_check.png')),
      findsNothing,
    );

    await tester.tap(find.text('Green Chillies').last);
    await tester.pumpAndSettle();
    expect(find.text('1/3 packed'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order_ready/ic_badge_check.png')),
      findsOneWidget,
    );
  });

  testWidgets('the checklist drives the counter, rail and slide gate', (
    tester,
  ) async {
    await pumpReady(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(
      rectOf(find.byKey(const Key('packing_progress_fill'))).width,
      closeTo(330, 0.5),
    );
    expect(find.text('Slide to mark as ready'), findsOneWidget);

    await tester.tap(find.text('Fresh Tomatoes'));
    await tester.pumpAndSettle();

    expect(find.text('2/3 packed'), findsOneWidget);
    expect(
      rectOf(find.byKey(const Key('packing_progress_fill'))).width,
      closeTo(220, 0.5),
    );
    expect(find.text('Pack all items to continue'), findsOneWidget);
    expect(find.text('Slide to mark as ready'), findsNothing);

    await tester.dragFrom(tester.getCenter(slideArrow()), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(find.byType(OrderDeliveryScreen), findsNothing);
    expect(rectOf(slideArrow()).left, closeTo(40, 2));

    await tester.tap(find.text('Fresh Tomatoes'));
    await tester.pumpAndSettle();
    expect(find.text('3/3 packed'), findsOneWidget);
    expect(find.text('Slide to mark as ready'), findsOneWidget);

    await tester.drag(
      find.text('Slide to mark as ready'),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrderDeliveryScreen), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: OrderReadyScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Packing checklist'), findsOneWidget);
  });
}

