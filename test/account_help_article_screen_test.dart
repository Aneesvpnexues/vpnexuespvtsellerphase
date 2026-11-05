import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/account_help_article_screen.dart';
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
  testWidgets('renders the 218 verify account article', (tester) async {
    await pumpScreen(tester, const VerifyAccountHelpScreen());

    expect(find.text('Account & verification'), findsNWidgets(2));
    expect(find.text('How do I verify my account?'), findsOneWidget);
    expect(find.text('2 min read'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
    expect(find.text('Open Verification'), findsOneWidget);
    expect(find.text('Upload your documents'), findsOneWidget);
    expect(find.text('Wait for review'), findsOneWidget);
    expect(find.text('Still need help?'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
  });

  testWidgets('renders the 219 rejected verification article', (tester) async {
    await pumpScreen(tester, const VerificationRejectedHelpScreen());

    expect(find.text('Why was my verification rejected?'), findsOneWidget);
    expect(find.text('Check the reason'), findsOneWidget);
    expect(find.text('Upload it again'), findsOneWidget);
    expect(find.text('Still rejected?'), findsOneWidget);
  });

  testWidgets('renders the 220 update business details article', (
    tester,
  ) async {
    await pumpScreen(tester, const UpdateBusinessDetailsHelpScreen());

    expect(find.text('How do I update my business details?'), findsOneWidget);
    expect(find.text('Open Business & Farm'), findsOneWidget);
    expect(find.text('Update the details'), findsOneWidget);
    expect(find.text('Re-verification'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester, const VerifyAccountHelpScreen());

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(
      rectOf(find.text('Account & verification').first).left,
      closeTo(68, 3),
    );
    expect(
      rectOf(find.text('Account & verification').first).top,
      closeTo(22, 4),
    );
    expect(
      rectOf(find.text('How do I verify my account?')).left,
      closeTo(45, 3),
    );
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
      MaterialPageRoute<void>(builder: (_) => const VerifyAccountHelpScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VerifyAccountHelpScreen), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyAccountHelpScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Still need help opens the report form', (tester) async {
    await pumpScreen(tester, const VerifyAccountHelpScreen());

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: VerifyAccountHelpScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('How do I verify my account?'), findsOneWidget);
  });

  testWidgets('golden: 218 verify account at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const VerifyAccountHelpScreen());

    await expectLater(
      find.byType(VerifyAccountHelpScreen),
      matchesGoldenFile('goldens/account_help_218.png'),
    );
  });

  testWidgets('golden: 219 rejected verification at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const VerificationRejectedHelpScreen());

    await expectLater(
      find.byType(VerificationRejectedHelpScreen),
      matchesGoldenFile('goldens/account_help_219.png'),
    );
  });

  testWidgets('golden: 220 business details at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester, const UpdateBusinessDetailsHelpScreen());

    await expectLater(
      find.byType(UpdateBusinessDetailsHelpScreen),
      matchesGoldenFile('goldens/account_help_220.png'),
    );
  });
}

