import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/account_help_article_screen.dart';
import 'package:seller_app/screens/account_verification_help_screen.dart';
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
  await tester.pumpWidget(
    const MaterialApp(home: AccountVerificationHelpScreen()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the Account & verification help content', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Account & verification'), findsOneWidget);
    expect(find.text('Help center'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Account help'), findsOneWidget);
    expect(find.text('KYC, documents and business details.'), findsOneWidget);
    expect(find.text('Articles'), findsOneWidget);
    expect(find.text('How do I verify my account?'), findsOneWidget);
    expect(find.text('Why was my verification rejected?'), findsOneWidget);
    expect(find.text('How do I update my business details?'), findsOneWidget);
    expect(find.text('Complete KYC in a few steps'), findsOneWidget);
    expect(find.text('Still need help?'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/help/tile_account.png')),
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

    expect(rectOf(find.text('Account & verification')).left, closeTo(68, 3));
    expect(rectOf(find.text('Account & verification')).top, closeTo(22, 4));
    expect(rectOf(find.text('Account help')).left, closeTo(45, 3));
    expect(rectOf(find.text('Account help')).top, closeTo(124, 5));
    expect(rectOf(find.text('Articles')).left, closeTo(25, 3));
    expect(rectOf(find.text('Articles')).top, closeTo(214, 4));
    expect(
      rectOf(find.text('How do I verify my account?')).left,
      closeTo(91, 3),
    );
    expect(
      rectOf(find.text('How do I verify my account?')).top,
      closeTo(252, 4),
    );
    expect(
      rectOf(find.text('Why was my verification rejected?')).top,
      closeTo(328, 4),
    );
    expect(
      rectOf(find.text('How do I update my business details?')).top,
      closeTo(404, 4),
    );
    expect(rectOf(find.text('Still need help?')).top, closeTo(525, 4));
    expect(rectOf(find.text('Report a problem')).top, closeTo(541, 4));
  });

  testWidgets('article rows open their Zeplin pages', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('How do I verify my account?'));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyAccountHelpScreen), findsOneWidget);
    expect(find.text('Open Verification'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(AccountVerificationHelpScreen), findsOneWidget);

    await tester.tap(find.text('Why was my verification rejected?'));
    await tester.pumpAndSettle();

    expect(find.byType(VerificationRejectedHelpScreen), findsOneWidget);
    expect(find.text('Check the reason'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('How do I update my business details?'));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateBusinessDetailsHelpScreen), findsOneWidget);
    expect(find.text('Open Business & Farm'), findsOneWidget);
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
    expect(find.byType(AccountVerificationHelpScreen), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: AccountVerificationHelpScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Account & verification'), findsOneWidget);
    expect(find.text('How do I verify my account?'), findsOneWidget);
  });

  testWidgets('golden: 217 account & verification at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester);

    await expectLater(
      find.byType(AccountVerificationHelpScreen),
      matchesGoldenFile('goldens/account_verification_217.png'),
    );
  });
}

