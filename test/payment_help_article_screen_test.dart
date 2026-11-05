import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/payment_help_article_screen.dart';
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
  testWidgets('renders the 214 payout timing article', (tester) async {
    await pumpScreen(tester, const PayoutTimingHelpScreen());

    expect(find.text('Payments & wallet'), findsNWidgets(2));
    expect(find.text('When will I get paid?'), findsOneWidget);
    expect(find.text('2 min read'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
    expect(find.text('Payout schedule'), findsOneWidget);
    expect(find.text('Check your balance'), findsOneWidget);
    expect(find.text('Payout on hold'), findsOneWidget);
    expect(find.text('Still need help?'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
  });

  testWidgets('renders the 215 withdraw article', (tester) async {
    await pumpScreen(tester, const WithdrawMoneyHelpScreen());

    expect(find.text('How do I withdraw money?'), findsOneWidget);
    expect(find.text('Check the balance'), findsOneWidget);
    expect(find.text('Start a withdrawal'), findsOneWidget);
    expect(find.text('Confirm the transfer'), findsOneWidget);
    expect(
      find.text(
        'Withdrawals usually reach your bank within 1 to 2 working days.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders the 216 pending withdrawal article', (tester) async {
    await pumpScreen(tester, const WithdrawalPendingHelpScreen());

    expect(find.text('Why is my withdrawal pending?'), findsOneWidget);
    expect(find.text('Check your bank details'), findsOneWidget);
    expect(find.text('Wait for the transfer'), findsOneWidget);
    expect(find.text('Still pending?'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester, const PayoutTimingHelpScreen());

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Payments & wallet').first).left, closeTo(68, 3));
    expect(rectOf(find.text('Payments & wallet').first).top, closeTo(24, 4));
    expect(rectOf(find.text('When will I get paid?')).left, closeTo(45, 3));
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
      MaterialPageRoute<void>(builder: (_) => const PayoutTimingHelpScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PayoutTimingHelpScreen), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(PayoutTimingHelpScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Still need help opens the report form', (tester) async {
    await pumpScreen(tester, const PayoutTimingHelpScreen());

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: PayoutTimingHelpScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('When will I get paid?'), findsOneWidget);
  });

  testWidgets('golden: 214 payout timing at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const PayoutTimingHelpScreen());

    await expectLater(
      find.byType(PayoutTimingHelpScreen),
      matchesGoldenFile('goldens/payment_help_214.png'),
    );
  });

  testWidgets('golden: 215 withdraw at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const WithdrawMoneyHelpScreen());

    await expectLater(
      find.byType(WithdrawMoneyHelpScreen),
      matchesGoldenFile('goldens/payment_help_215.png'),
    );
  });

  testWidgets('golden: 216 pending withdrawal at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const WithdrawalPendingHelpScreen());

    await expectLater(
      find.byType(WithdrawalPendingHelpScreen),
      matchesGoldenFile('goldens/payment_help_216.png'),
    );
  });
}
