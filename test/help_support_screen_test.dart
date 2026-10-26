import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/help_support_screen.dart';
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

  final FontLoader inder = FontLoader('Inder')
    ..addFont(rootBundle.load('assets/fonts/Inder-Regular.ttf'));
  await inder.load();
}

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 199 Help & Support content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Help center'), findsOneWidget);
    expect(find.text('How can we help?'), findsOneWidget);
    expect(find.text('Search answers or talk to our team.'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Search for help'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Orders & delivery'), findsOneWidget);
    expect(find.text('Products & stock'), findsOneWidget);
    expect(find.text('Payments & wallet'), findsOneWidget);
    expect(find.text('Account & verification'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Tell us what went wrong'), findsOneWidget);
    expect(find.text('3 articles'), findsNWidgets(4));
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/help/tile_orders.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/help/chevron.png')),
      findsNWidgets(5),
    );
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Help & Support')).left, closeTo(68, 3));
    expect(rectOf(find.text('Help & Support')).top, closeTo(24, 4));
    expect(rectOf(find.text('How can we help?')).left, closeTo(45, 3));
    expect(rectOf(find.text('How can we help?')).top, closeTo(124, 5));
    expect(
      rectOf(find.text('Search answers or talk to our team.')).top,
      closeTo(149, 5),
    );
    expect(rectOf(find.text('Search for help')).top, closeTo(205, 4));
    expect(rectOf(find.text('Call')).top, closeTo(322, 4));
    expect(rectOf(find.text('WhatsApp')).top, closeTo(322, 4));
    expect(rectOf(find.text('Topics')).top, closeTo(394, 4));
    expect(rectOf(find.text('Questions')).top, closeTo(393, 4));
    expect(rectOf(find.text('Orders & delivery')).top, closeTo(456, 4));
    expect(rectOf(find.text('Products & stock')).top, closeTo(514, 4));
    expect(rectOf(find.text('Payments & wallet')).top, closeTo(572, 4));
    expect(rectOf(find.text('Account & verification')).top, closeTo(630, 4));
    expect(rectOf(find.text('Report a problem')).top, closeTo(688, 4));
    expect(
      rectOf(find.text('Tell us what went wrong')).top,
      closeTo(703, 4),
    );
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
  });

  testWidgets('Report a problem row opens the report form', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsNothing);
    expect(find.byType(HelpSupportScreen), findsOneWidget);
  });

  testWidgets('golden: 199 help support at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester);

    await expectLater(
      find.byType(HelpSupportScreen),
      matchesGoldenFile('goldens/help_support_199.png'),
    );
  });
}
