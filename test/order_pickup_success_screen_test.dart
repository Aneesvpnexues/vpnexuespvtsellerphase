import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/order_pickup_success_screen.dart';

const List<String> _assets = [
  'assets/order/ic_back.png',
  'assets/order/ic_step_tick.png',
  'assets/order/ic_step_flag.png',
  'assets/order/ic_slide.png',
];

Future<void> _loadRoboto(WidgetTester tester) async {
  await tester.runAsync(() async {
    final FontLoader loader = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();
  });
}

Future<void> pumpPickupSuccess(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 868);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OrderPickupSuccessScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 165 pickup success content', (tester) async {
    await pumpPickupSuccess(tester);

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Buyer Pickup'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('ORDER #NX4582'), findsOneWidget);
    expect(find.text('Pick up'), findsOneWidget);
    expect(find.text('Ready for Pickup'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Total Amount'), findsOneWidget);
    expect(find.text('\u20B92,840'), findsOneWidget);
    expect(find.text('Order'), findsOneWidget);
    expect(find.text('#NX4582'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Picked up'), findsOneWidget);
    expect(find.text('25 Mar 2024'), findsOneWidget);
    expect(find.text('Added to your earnings'), findsOneWidget);
    expect(find.text('Back to orders'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await _loadRoboto(tester);
    await pumpPickupSuccess(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Order Details')).left, closeTo(68, 2));
    expect(rectOf(find.text('Order Details')).top, closeTo(28, 3));
    expect(rectOf(find.text('Ready for Pickup')).left, closeTo(41, 2));
    expect(rectOf(find.text('Ready for Pickup')).top, closeTo(153.6, 3));
    expect(rectOf(find.text('Total Amount')).center.dx, closeTo(205.5, 3));
    expect(rectOf(find.text('Total Amount')).center.dy, closeTo(488.3, 3));
    expect(rectOf(find.text('\u20B92,840')).center.dx, closeTo(205.5, 3));
    expect(rectOf(find.text('\u20B92,840')).center.dy, closeTo(516.6, 3));
    expect(rectOf(find.text('Order')).center.dx, closeTo(101.5, 3));
    expect(rectOf(find.text('Order')).center.dy, closeTo(582.9, 3));
    expect(rectOf(find.text('Items')).center.dx, closeTo(196.4, 3));
    expect(rectOf(find.text('Picked up')).center.dx, closeTo(300, 3));
    expect(rectOf(find.text('#NX4582')).center.dx, closeTo(101.5, 3));
    expect(rectOf(find.text('#NX4582')).center.dy, closeTo(599.8, 3));
    expect(rectOf(find.text('3')).center.dx, closeTo(196.4, 3));
    expect(rectOf(find.text('25 Mar 2024')).center.dx, closeTo(300, 3));
    expect(rectOf(find.text('Added to your earnings')).left, closeTo(155, 3));
    expect(rectOf(find.text('Added to your earnings')).top, closeTo(645.4, 3));

    final Rect button = rectOf(find.text('Back to orders'));
    expect(button.center.dx, closeTo(212.25, 3));
    expect(button.center.dy, closeTo(827, 3));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: OrderPickupSuccessScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final double scale = 360 / 412;
    final Rect title = tester.getRect(find.text('Order Details'));
    expect(title.left, closeTo(68 * scale, 1.5));
  });

  testWidgets('swiping back to orders returns to My Orders', (tester) async {
    await pumpPickupSuccess(tester);

    await tester.drag(find.text('Back to orders'), const Offset(320, 0));
    await tester.pumpAndSettle();

    expect(find.byType(MyOrdersScreen), findsOneWidget);
  });

  testWidgets('a short swipe on the bar springs back', (tester) async {
    await pumpPickupSuccess(tester);

    await tester.drag(find.text('Back to orders'), const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(find.byType(MyOrdersScreen), findsNothing);
    expect(find.text('Back to orders'), findsOneWidget);
  });

  testWidgets('golden: 165 pickup success at 412x868', (tester) async {
    await _loadRoboto(tester);
    await pumpPickupSuccess(tester);
    await tester.runAsync(() async {
      final BuildContext context = tester.element(
        find.byType(OrderPickupSuccessScreen),
      );
      for (final String asset in _assets) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OrderPickupSuccessScreen),
      matchesGoldenFile('goldens/order_pickup_success_165.png'),
    );
  });
}
