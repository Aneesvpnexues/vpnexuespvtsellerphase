import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/order_confirmation_screen.dart';

Future<void> _loadFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    final FontLoader roboto = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await roboto.load();

    final FontLoader inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-ExtraBold.ttf'));
    await inter.load();

    final FontLoader icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
}

Future<void> pumpConfirmation(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 868);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OrderConfirmationScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SessionStore.instance.startSession(
      phone: '9876543210',
      userName: 'Test Seller',
      method: 'login',
    );
  });

  testWidgets('renders the 259 order confirmation content', (tester) async {
    await pumpConfirmation(tester);

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Buyer Pickup'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('Order completed'), findsOneWidget);
    expect(find.text('Akash Stores collected the order.'), findsOneWidget);
    expect(
      find.text('Order #NX4582 \u00B7 3 items', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Added to your wallet'), findsOneWidget);
    expect(find.text('\u20B92,840'), findsOneWidget);
    expect(find.text('Back to orders'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await _loadFonts(tester);
    await pumpConfirmation(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Order Details')).left, closeTo(68, 2));
    expect(rectOf(find.text('Order Details')).top, closeTo(28, 3));
    expect(rectOf(find.text('Buyer Pickup')).left, closeTo(78, 3));
    expect(rectOf(find.text('Buyer Pickup')).top, closeTo(83.5, 3));
    expect(rectOf(find.text('Delivery')).left, closeTo(262, 3));
    expect(rectOf(find.text('Delivery')).top, closeTo(83.5, 3));

    final Rect completed = rectOf(find.text('Order completed'));
    expect(completed.center.dx, closeTo(206, 2));
    expect(completed.top, closeTo(331, 3));

    expect(
      rectOf(find.text('Akash Stores collected the order.')).top,
      closeTo(374, 3),
    );
    expect(
      rectOf(find.text('Added to your wallet')).left,
      closeTo(98, 2),
    );
    expect(rectOf(find.text('\u20B92,840')).left, closeTo(98, 2));
    expect(rectOf(find.text('\u20B92,840')).top, closeTo(462.5, 3));

    final Rect back = rectOf(find.text('Back to orders'));
    expect(back.center.dx, closeTo(206, 2));
    expect(back.center.dy, closeTo(812, 3));
  });

  testWidgets('back button returns to the My Orders tab', (tester) async {
    await pumpConfirmation(tester);

    await tester.tap(find.text('Back to orders'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Order completed'), findsNothing);
  });

  testWidgets('golden: 259 order confirmation at 412x868', (tester) async {
    await _loadFonts(tester);
    await pumpConfirmation(tester);

    await expectLater(
      find.byType(OrderConfirmationScreen),
      matchesGoldenFile('goldens/order_confirmation_259.png'),
    );
  });
}
