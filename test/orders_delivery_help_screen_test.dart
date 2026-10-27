import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/order_help_article_screen.dart';
import 'package:seller_app/screens/orders_delivery_help_screen.dart';
import 'package:seller_app/screens/report_problem_screen.dart';

Future<void> _loadFonts() async {
  const List<String> interFiles = <String>[
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-ExtraBold.ttf',
  ];
  final FontLoader inter = FontLoader('Inter');
  for (final String file in interFiles) {
    inter.addFont(rootBundle.load(file));
  }
  await inter.load();
}

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OrdersDeliveryHelpScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the Orders & delivery help content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Orders & delivery'), findsOneWidget);
    expect(find.text('Help center'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Delivery help'), findsOneWidget);
    expect(find.text('Track, change or fix an order.'), findsOneWidget);
    expect(find.text('Articles'), findsOneWidget);
    expect(find.text('How do I track my order?'), findsOneWidget);
    expect(find.text('Can I cancel an order?'), findsOneWidget);
    expect(find.text('What if my order is delayed?'), findsOneWidget);
    expect(find.text('Follow every step to delivery'), findsOneWidget);
    expect(find.text('Still need help?'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/help/tile_orders.png')),
      findsNWidgets(3),
    );
    expect(
      find.image(const AssetImage('assets/help/chevron.png')),
      findsNWidgets(4),
    );
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Orders & delivery')).left, closeTo(68, 3));
    expect(rectOf(find.text('Orders & delivery')).top, closeTo(24, 4));
    expect(rectOf(find.text('Delivery help')).left, closeTo(45, 3));
    expect(rectOf(find.text('Delivery help')).top, closeTo(124, 5));
    expect(rectOf(find.text('Articles')).left, closeTo(25, 3));
    expect(rectOf(find.text('Articles')).top, closeTo(214, 4));
    expect(rectOf(find.text('How do I track my order?')).left, closeTo(91, 3));
    expect(rectOf(find.text('How do I track my order?')).top, closeTo(252, 4));
    expect(rectOf(find.text('Can I cancel an order?')).top, closeTo(328, 4));
    expect(
      rectOf(find.text('What if my order is delayed?')).top,
      closeTo(404, 4),
    );
    expect(rectOf(find.text('Still need help?')).top, closeTo(525, 4));
    expect(rectOf(find.text('Report a problem')).top, closeTo(541, 4));
  });

  testWidgets('article rows open their Zeplin pages', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('How do I track my order?'));
    await tester.pumpAndSettle();

    expect(find.byType(TrackOrderHelpScreen), findsOneWidget);
    expect(find.text('Open My Orders'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(OrdersDeliveryHelpScreen), findsOneWidget);

    await tester.tap(find.text('Can I cancel an order?'));
    await tester.pumpAndSettle();

    expect(find.byType(CancelOrderHelpScreen), findsOneWidget);
    expect(find.text('Refund timeline'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('What if my order is delayed?'));
    await tester.pumpAndSettle();

    expect(find.byType(DelayedOrderHelpScreen), findsOneWidget);
    expect(find.text('What happens next'), findsOneWidget);
  });

  testWidgets('Still need help opens the report form', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsNothing);
    expect(find.byType(OrdersDeliveryHelpScreen), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: OrdersDeliveryHelpScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Orders & delivery'), findsOneWidget);
    expect(find.text('How do I track my order?'), findsOneWidget);
  });

  testWidgets('golden: 204 orders & delivery help at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester);

    await expectLater(
      find.byType(OrdersDeliveryHelpScreen),
      matchesGoldenFile('goldens/orders_delivery_204.png'),
    );
  });
}
