import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/account_help_article_screen.dart';
import 'package:seller_app/screens/account_verification_help_screen.dart';
import 'package:seller_app/screens/help_support_screen.dart';
import 'package:seller_app/screens/orders_delivery_help_screen.dart';
import 'package:seller_app/screens/payment_help_article_screen.dart';
import 'package:seller_app/screens/payments_wallet_help_screen.dart';
import 'package:seller_app/screens/products_stock_help_screen.dart';
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

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

Rect _pillRect(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(AnimatedPositioned),
        matching: find.byType(Container),
      )
      .first,
);

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
    expect(rectOf(find.text('Tell us what went wrong')).top, closeTo(703, 4));
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

  testWidgets('Orders & delivery row opens the articles page', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Orders & delivery'));
    await tester.pumpAndSettle();

    expect(find.byType(OrdersDeliveryHelpScreen), findsOneWidget);
    expect(find.text('How do I track my order?'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(OrdersDeliveryHelpScreen), findsNothing);
    expect(find.byType(HelpSupportScreen), findsOneWidget);
  });

  testWidgets('Products & stock row opens the articles page', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Products & stock'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductsStockHelpScreen), findsOneWidget);
    expect(find.text('How do I add a product?'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductsStockHelpScreen), findsNothing);
    expect(find.byType(HelpSupportScreen), findsOneWidget);
  });

  testWidgets('Payments & wallet row opens the articles page', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Payments & wallet'));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentsWalletHelpScreen), findsOneWidget);
    expect(find.text('When will I get paid?'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentsWalletHelpScreen), findsNothing);
    expect(find.byType(HelpSupportScreen), findsOneWidget);
  });

  testWidgets('Account & verification row opens the articles page', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Account & verification'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountVerificationHelpScreen), findsOneWidget);
    expect(find.text('How do I verify my account?'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(AccountVerificationHelpScreen), findsNothing);
    expect(find.byType(HelpSupportScreen), findsOneWidget);
  });

  testWidgets('Questions tab opens the 221 selected state', (tester) async {
    await pumpScreen(tester);

    expect(_styleOf(tester, 'Topics').fontWeight, FontWeight.w700);
    expect(_styleOf(tester, 'Questions').fontWeight, FontWeight.w600);
    expect(_pillRect(tester).left, closeTo(28, 0.5));

    await tester.tap(find.byKey(const Key('help-tab-questions')));
    await tester.pumpAndSettle();

    expect(_styleOf(tester, 'Questions').fontWeight, FontWeight.w700);
    expect(_styleOf(tester, 'Questions').color, const Color(0xFF144326));
    expect(_styleOf(tester, 'Topics').fontWeight, FontWeight.w600);
    expect(_styleOf(tester, 'Topics').color, const Color(0xFF6B7B6F));
    expect(_styleOf(tester, 'Tickets').fontWeight, FontWeight.w600);
    expect(_pillRect(tester).left, closeTo(150, 0.5));
    expect(_pillRect(tester).top, closeTo(388, 0.5));

    // 221 lists the four frequently asked questions instead of the topics.
    expect(find.text('When will i get my money?'), findsOneWidget);
    expect(find.text('How do i update my stock?'), findsOneWidget);
    expect(find.text('How do i accept a new order?'), findsOneWidget);
    expect(find.text('How do i get verified?'), findsOneWidget);
    expect(find.text('Orders & delivery'), findsNothing);
    expect(find.text('Report a problem'), findsNothing);
    expect(find.text('Tell us what went wrong'), findsNothing);
    expect(
      find.image(const AssetImage('assets/help/chevron.png')),
      findsNWidgets(4),
    );

    await tester.tap(find.byKey(const Key('help-tab-topics')));
    await tester.pumpAndSettle();

    expect(_styleOf(tester, 'Topics').fontWeight, FontWeight.w700);
    expect(_styleOf(tester, 'Questions').fontWeight, FontWeight.w600);
    expect(_pillRect(tester).left, closeTo(28, 0.5));
  });

  testWidgets('Questions layout matches the 221 design geometry', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('help-tab-questions')));
    await tester.pumpAndSettle();

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('When will i get my money?')).left, closeTo(42, 2));
    expect(rectOf(find.text('When will i get my money?')).top, closeTo(468, 2));
    expect(rectOf(find.text('How do i update my stock?')).top, closeTo(517, 2));
    expect(
      rectOf(find.text('How do i accept a new order?')).top,
      closeTo(566, 2),
    );
    expect(rectOf(find.text('How do i get verified?')).top, closeTo(611, 2));
  });

  testWidgets('Question rows open their articles', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('help-tab-questions')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('When will i get my money?'));
    await tester.pumpAndSettle();

    expect(find.byType(PayoutTimingHelpScreen), findsOneWidget);
    expect(find.text('When will I get paid?'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(PayoutTimingHelpScreen), findsNothing);
    expect(find.byType(HelpSupportScreen), findsOneWidget);

    await tester.tap(find.text('How do i get verified?'));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyAccountHelpScreen), findsOneWidget);
  });

  testWidgets('Tickets tab opens the 222 selected state', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('help-tab-tickets')));
    await tester.pumpAndSettle();

    expect(_styleOf(tester, 'Tickets').fontWeight, FontWeight.w700);
    expect(_styleOf(tester, 'Tickets').color, const Color(0xFF144326));
    expect(_styleOf(tester, 'Topics').fontWeight, FontWeight.w600);
    expect(_styleOf(tester, 'Questions').fontWeight, FontWeight.w600);
    expect(_pillRect(tester).left, closeTo(271, 0.5));
    expect(_pillRect(tester).top, closeTo(388, 0.5));

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);
    expect(rectOf(find.text('Topics')).left, closeTo(61, 1));
    expect(rectOf(find.text('Questions')).left, closeTo(175, 1));
    expect(rectOf(find.text('Tickets')).left, closeTo(305, 1));

    // 222 shows the single open support ticket instead of the categories.
    expect(find.text('Payout delayed'), findsOneWidget);
    expect(find.text('#HS-2026, 3Mar'), findsOneWidget);
    expect(find.text('Orders & delivery'), findsNothing);
    expect(find.text('When will i get my money?'), findsNothing);
    expect(
      find.image(const AssetImage('assets/help/tile_orders.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/help/chevron.png')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('help-tab-topics')));
    await tester.pumpAndSettle();

    expect(_styleOf(tester, 'Topics').fontWeight, FontWeight.w700);
    expect(_pillRect(tester).left, closeTo(28, 0.5));
    expect(rectOf(find.text('Questions')).left, closeTo(182, 1));
  });

  testWidgets('Tickets layout matches the 222 design geometry', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('help-tab-tickets')));
    await tester.pumpAndSettle();

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Payout delayed')).left, closeTo(91, 2));
    expect(rectOf(find.text('Payout delayed')).top, closeTo(456, 2));
    expect(rectOf(find.text('#HS-2026, 3Mar')).left, closeTo(91, 2));
    expect(rectOf(find.text('#HS-2026, 3Mar')).top, closeTo(471, 2));

    final chevron = rectOf(
      find.image(const AssetImage('assets/help/chevron.png')),
    );
    expect(chevron.left, closeTo(355, 2));
    expect(chevron.top, closeTo(467, 2));
    expect(chevron.width, closeTo(18, 1));
  });

  testWidgets('golden: 222 help support tickets tab at 412x917', (
    tester,
  ) async {
    await _loadFonts();
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('help-tab-tickets')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HelpSupportScreen),
      matchesGoldenFile('goldens/help_support_222.png'),
    );
  });

  testWidgets('golden: 221 help support questions tab at 412x917', (
    tester,
  ) async {
    await _loadFonts();
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('help-tab-questions')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HelpSupportScreen),
      matchesGoldenFile('goldens/help_support_221.png'),
    );
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
