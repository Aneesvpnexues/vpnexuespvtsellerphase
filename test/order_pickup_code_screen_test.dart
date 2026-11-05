import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/order_pickup_code_screen.dart';

const List<String> _assets = [
  'assets/order/ic_back.png',
  'assets/order/ic_shop.png',
  'assets/order/ic_step_tick.png',
  'assets/order/ic_step_download.png',
  'assets/order/ic_step_flag.png',
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

Future<void> pumpPickupCode(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 868);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OrderPickupCodeScreen()));
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

  testWidgets('renders the 154 pickup code content', (tester) async {
    await pumpPickupCode(tester);

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
    expect(find.text('Akash Stores'), findsOneWidget);
    expect(find.text('\u20B92,840'), findsOneWidget);
    expect(find.text('Enter pickup code'), findsOneWidget);
    expect(
      find.text('Ask the buyer for the 4-digital code shown in their app'),
      findsOneWidget,
    );
    expect(find.text('Enter the code to continus'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await _loadRoboto(tester);
    await pumpPickupCode(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Order Details')).left, closeTo(68, 2));
    expect(rectOf(find.text('Order Details')).top, closeTo(28, 3));
    expect(rectOf(find.text('Buyer Pickup')).left, closeTo(78, 3));
    expect(rectOf(find.text('Buyer Pickup')).top, closeTo(83.5, 3));
    expect(rectOf(find.text('Delivery')).left, closeTo(262, 3));
    expect(rectOf(find.text('Delivery')).top, closeTo(83.5, 3));
    expect(rectOf(find.text('ORDER #NX4582')).left, closeTo(41, 2));
    expect(rectOf(find.text('ORDER #NX4582')).top, closeTo(134.6, 3));
    expect(rectOf(find.text('Pick up')).left, closeTo(322.5, 3));
    expect(rectOf(find.text('Ready for Pickup')).left, closeTo(41, 2));
    expect(rectOf(find.text('Ready for Pickup')).top, closeTo(153.6, 3));
    expect(rectOf(find.text('Active')).left, closeTo(61, 3));
    expect(rectOf(find.text('Active')).top, closeTo(254.5, 3));
    expect(rectOf(find.text('Accepted')).left, closeTo(118, 3));
    expect(rectOf(find.text('Completed')).left, closeTo(309.5, 3));
    expect(rectOf(find.text('Akash Stores')).left, closeTo(155, 3));
    expect(rectOf(find.text('Akash Stores')).top, closeTo(352.3, 3));
    expect(rectOf(find.text('\u20B92,840')).left, closeTo(299, 3));
    expect(rectOf(find.text('\u20B92,840')).top, closeTo(358.2, 3));
    expect(rectOf(find.text('Enter pickup code')).left, closeTo(115.8, 3));
    expect(rectOf(find.text('Enter pickup code')).top, closeTo(442.3, 3));
    expect(
      rectOf(
        find.text('Ask the buyer for the 4-digital code shown in their app'),
      ).left,
      closeTo(74, 3),
    );

    final Rect button = rectOf(find.text('Enter the code to continus'));
    expect(button.center.dx, closeTo(215, 3));
    expect(button.center.dy, closeTo(827, 3));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: OrderPickupCodeScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final double scale = 360 / 412;
    final Rect title = tester.getRect(find.text('Order Details'));
    expect(title.left, closeTo(68 * scale, 1.5));
  });

  testWidgets('continue button opens the pickup success screen', (
    tester,
  ) async {
    await pumpPickupCode(tester);

    await tester.tap(find.text('Enter the code to continus'));
    await tester.pumpAndSettle();
    expect(find.text('Back to orders'), findsOneWidget);
    expect(find.text('Total Amount'), findsOneWidget);

    await tester.tap(find.text('Back to orders'));
    await tester.pumpAndSettle();
    expect(find.text('Enter pickup code'), findsOneWidget);
  });

  testWidgets('swiping the continue bar opens the pickup success screen', (
    tester,
  ) async {
    await pumpPickupCode(tester);

    await tester.drag(
      find.text('Enter the code to continus'),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Back to orders'), findsOneWidget);
  });

  testWidgets('a short swipe on the continue bar springs back', (tester) async {
    await pumpPickupCode(tester);

    await tester.drag(
      find.text('Enter the code to continus'),
      const Offset(30, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter pickup code'), findsOneWidget);
    expect(find.text('Back to orders'), findsNothing);
  });

  testWidgets('golden: 154 pickup code at 412x868', (tester) async {
    await _loadRoboto(tester);
    await pumpPickupCode(tester);
    await tester.runAsync(() async {
      final BuildContext context = tester.element(
        find.byType(OrderPickupCodeScreen),
      );
      for (final String asset in _assets) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OrderPickupCodeScreen),
      matchesGoldenFile('goldens/order_pickup_code_154.png'),
    );
  });
}
