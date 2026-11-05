import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/order_help_article_screen.dart';
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

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 205 track order article', (tester) async {
    await pumpScreen(tester, const TrackOrderHelpScreen());

    expect(find.text('Orders & delivery'), findsNWidgets(2));
    expect(find.text('How do I track my order?'), findsOneWidget);
    expect(find.text('2 min read'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
    expect(find.text('Open My Orders'), findsOneWidget);
    expect(find.text('Select the order'), findsOneWidget);
    expect(find.text('Tap Track order'), findsOneWidget);
    expect(find.text('Still need help?'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
  });

  testWidgets('renders the 206 cancel order article', (tester) async {
    await pumpScreen(tester, const CancelOrderHelpScreen());

    expect(find.text('Can I cancel an order?'), findsOneWidget);
    expect(find.text('While the order is Packed'), findsOneWidget);
    expect(find.text('After pickup'), findsOneWidget);
    expect(find.text('Refund timeline'), findsOneWidget);
    expect(
      find.text(
        'Approved refunds return to your wallet within 3 to 5 working days.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders the 207 delayed order article', (tester) async {
    await pumpScreen(tester, const DelayedOrderHelpScreen());

    expect(find.text('What if my order is delayed?'), findsOneWidget);
    expect(find.text('Check the delivery window'), findsOneWidget);
    expect(find.text('Report the delay'), findsOneWidget);
    expect(find.text('What happens next'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester, const TrackOrderHelpScreen());

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Orders & delivery').first).left, closeTo(68, 3));
    expect(rectOf(find.text('Orders & delivery').first).top, closeTo(22, 4));
    expect(rectOf(find.text('How do I track my order?')).left, closeTo(45, 3));
    expect(rectOf(find.text('What to do')).left, closeTo(45, 3));
    expect(rectOf(find.text('What to do')).top, closeTo(269, 4));
    expect(rectOf(find.text('Still need help?')).top, closeTo(739, 4));
    expect(rectOf(find.text('Report a problem')).top, closeTo(755, 4));
  });

  testWidgets('back button pops the article', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('home'))),
    );
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.text('home'));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TrackOrderHelpScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TrackOrderHelpScreen), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(TrackOrderHelpScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Still need help opens the report form', (tester) async {
    await pumpScreen(tester, const TrackOrderHelpScreen());

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TrackOrderHelpScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('How do I track my order?'), findsOneWidget);
  });

  testWidgets('golden: 205 track order at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const TrackOrderHelpScreen());

    await expectLater(
      find.byType(TrackOrderHelpScreen),
      matchesGoldenFile('goldens/order_help_205.png'),
    );
  });

  testWidgets('golden: 206 cancel order at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const CancelOrderHelpScreen());

    await expectLater(
      find.byType(CancelOrderHelpScreen),
      matchesGoldenFile('goldens/order_help_206.png'),
    );
  });

  testWidgets('golden: 207 delayed order at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const DelayedOrderHelpScreen());

    await expectLater(
      find.byType(DelayedOrderHelpScreen),
      matchesGoldenFile('goldens/order_help_207.png'),
    );
  });
}

