import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/order_accepted_screen.dart';
import 'package:seller_app/screens/order_ready_screen.dart';

Future<void> pumpAccepted(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OrderAcceptedScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 139 order accepted content', (tester) async {
    await pumpAccepted(tester);

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Buyer Pickup'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('ORDER #NX4582'), findsOneWidget);
    expect(find.text('Order Accepted'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Accepted'), findsNWidgets(2));
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('BUYER DETAILS'), findsOneWidget);
    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('Retailer'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('+91 12345 67890'), findsOneWidget);
    expect(find.text('Call'), findsNWidgets(2));
    expect(find.text('Packing checklist'), findsOneWidget);
    expect(find.text('0/3 packed'), findsOneWidget);
    expect(find.text('Fresh Tomatoes'), findsOneWidget);
    expect(find.text('Green Chillies'), findsNWidgets(2));
    expect(find.text('50 kg'), findsOneWidget);
    expect(find.text('30 kg'), findsOneWidget);
    expect(find.text('20 kg'), findsOneWidget);
    expect(find.text('Pack all items to continue'), findsOneWidget);
    expect(find.text('Slide to accept order'), findsNothing);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpAccepted(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Order Details')).left, closeTo(68, 3));
    expect(rectOf(find.text('Order Details')).top, closeTo(24, 4));
    expect(rectOf(find.text('ORDER #NX4582')).left, closeTo(41, 3));
    expect(rectOf(find.text('ORDER #NX4582')).top, closeTo(135, 4));
    expect(rectOf(find.text('Order Accepted')).left, closeTo(41, 3));
    expect(rectOf(find.text('Order Accepted')).top, closeTo(157, 5));
    expect(rectOf(find.text('Akash Stores')).left, closeTo(119, 3));
    expect(rectOf(find.text('Akash Stores')).top, closeTo(353, 5));
    expect(rectOf(find.text('Packing checklist')).left, closeTo(80, 3));
    expect(rectOf(find.text('Packing checklist')).top, closeTo(522, 5));
    expect(rectOf(find.text('0/3 packed')).left, closeTo(305, 3));
    expect(rectOf(find.text('Fresh Tomatoes')).left, closeTo(107, 3));
    expect(rectOf(find.text('Fresh Tomatoes')).top, closeTo(590, 5));
    expect(
      rectOf(find.text('Pack all items to continue')).left,
      closeTo(128, 3),
    );
    expect(
      rectOf(find.text('Pack all items to continue')).top,
      closeTo(813, 5),
    );
  });

  testWidgets('the five step labels line up under the step rail', (
    tester,
  ) async {
    await pumpAccepted(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    const List<String> labels = [
      'Active',
      'Accepted',
      'Ready',
      'Pickup',
      'Completed',
    ];
    Finder railLabel(String text, double expectedLeft) {
      final int count = find.text(text).evaluate().length;
      for (int i = 0; i < count; i++) {
        if ((rectOf(find.text(text).at(i)).left - expectedLeft).abs() < 12) {
          return find.text(text).at(i);
        }
      }
      return find.text(text).first;
    }

    for (int i = 0; i < labels.length; i++) {
      final double expectedLeft = 61 + i * 65;
      final Rect rect = rectOf(railLabel(labels[i], expectedLeft));
      expect(rect.left, closeTo(expectedLeft, 3));
      expect(rect.top, closeTo(249, 5));
    }
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: OrderAcceptedScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Packing checklist'), findsOneWidget);
  });

  testWidgets('tapping a checklist row packs it and the rail follows', (
    tester,
  ) async {
    await pumpAccepted(tester);

    expect(find.text('0/3 packed'), findsOneWidget);

    await tester.tap(find.text('Fresh Tomatoes'));
    await tester.pumpAndSettle();
    expect(find.text('1/3 packed'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order_ready/ic_badge_check.png')),
      findsOneWidget,
    );

    await tester.tap(find.text('Green Chillies').first);
    await tester.pumpAndSettle();
    expect(find.text('2/3 packed'), findsOneWidget);

    await tester.tap(find.text('Green Chillies').last);
    await tester.pumpAndSettle();
    expect(find.text('3/3 packed'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order_ready/ic_badge_check.png')),
      findsNWidgets(3),
    );

    await tester.tap(find.text('Green Chillies').last);
    await tester.pumpAndSettle();
    expect(find.text('2/3 packed'), findsOneWidget);
  });

  testWidgets('the packing CTA slides on once every item is packed', (
    tester,
  ) async {
    await pumpAccepted(tester);

    await tester.drag(
      find.text('Pack all items to continue'),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrderReadyScreen), findsNothing);

    await tester.tap(find.text('Fresh Tomatoes'));
    await tester.tap(find.text('Green Chillies').first);
    await tester.tap(find.text('Green Chillies').last);
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('Pack all items to continue'),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OrderReadyScreen), findsOneWidget);
    expect(find.text('Slide to mark as ready'), findsOneWidget);
  });
}
