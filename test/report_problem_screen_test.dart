import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/report_problem_screen.dart';

Future<void> _loadInter() async {
  const List<String> files = <String>[
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-ExtraBold.ttf',
  ];
  final FontLoader loader = FontLoader('Inter');
  for (final String file in files) {
    loader.addFont(rootBundle.load(file));
  }
  await loader.load();
}

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: ReportProblemScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the Report a problem content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('New request'), findsOneWidget);
    expect(find.text('Tell us the issue'), findsOneWidget);
    expect(find.text('We’ll look into it and get back to you'), findsOneWidget);
    expect(find.text('What is this about?'), findsNWidgets(2));
    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Order ID'), findsOneWidget);
    expect(find.text('e.g.'), findsOneWidget);
    expect(find.text('#NX4582'), findsOneWidget);
    expect(find.text('Tell us what happened'), findsOneWidget);
    expect(find.text('Describe the problem in a few words'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
    expect(
      find.text('A screenshot or photo helps us fix it faster'),
      findsOneWidget,
    );
    expect(find.text('Call me'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Report a problem')).left, closeTo(68, 3));
    expect(rectOf(find.text('Report a problem')).top, closeTo(24, 4));
    expect(rectOf(find.text('Tell us the issue')).left, closeTo(45, 3));
    expect(rectOf(find.text('Tell us the issue')).top, closeTo(124, 5));
    expect(rectOf(find.text('What is this about?').first).left, closeTo(45, 3));
    expect(rectOf(find.text('What is this about?').first).top, closeTo(223, 4));
    expect(rectOf(find.text('Order')).left, closeTo(62, 3));
    expect(rectOf(find.text('Order')).top, closeTo(256, 4));
    expect(rectOf(find.text('Order ID')).top, closeTo(335, 4));
    expect(rectOf(find.text('e.g.')).top, closeTo(369, 4));
    expect(rectOf(find.text('Tell us what happened')).top, closeTo(413, 4));
    expect(rectOf(find.text('Add a photo')).top, closeTo(551, 4));
    expect(rectOf(find.text('What is this about?').last).top, closeTo(643, 4));
    expect(rectOf(find.text('Call me')).left, closeTo(62, 3));
    expect(rectOf(find.text('Call me')).top, closeTo(676, 4));
    expect(rectOf(find.text('Submit')).left, closeTo(181, 3));
    expect(rectOf(find.text('Submit')).top, closeTo(815, 4));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ReportProblemScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('golden: 200 report a problem at 412x917', (tester) async {
    await _loadInter();
    await pumpScreen(tester);

    await expectLater(
      find.byType(ReportProblemScreen),
      matchesGoldenFile('goldens/report_problem_200.png'),
    );
  });
}
