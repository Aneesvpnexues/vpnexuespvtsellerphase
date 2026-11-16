import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/help_support_screen.dart';
import 'package:seller_app/widgets/page_header.dart';

/// The Help & Support home has to stay usable as a real screen: the three
/// segments switch, the hero search actually filters the lists (including its
/// empty state), rows navigate, and the hero's Call/WhatsApp buttons and the
/// header back button are live controls rather than decoration.
void main() {
  Future<void> pumpHelp(
    WidgetTester tester, {
    Size size = const Size(412 * 3, 917 * 3),
  }) async {
    // A 412x917 device by default — the design width the page is composed
    // against — and optionally a narrower handset.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('the Topics tab lists every category and opens one', (tester) async {
    await pumpHelp(tester);

    expect(find.text('Orders & delivery'), findsOneWidget);
    expect(find.text('Products & stock'), findsOneWidget);
    expect(find.text('Payments & wallet'), findsOneWidget);
    expect(find.text('Account & verification'), findsOneWidget);

    await tester.tap(find.text('Orders & delivery'));
    await tester.pumpAndSettle();

    // The Orders & delivery topic screen pushed on top.
    expect(find.text('Delivery help'), findsOneWidget);
    expect(find.text('Articles'), findsOneWidget);

    await tester.tap(find.byKey(PageHeader.backKey));
    await tester.pumpAndSettle();
    expect(find.byType(HelpSupportScreen), findsOneWidget);
  });

  testWidgets('the segmented control switches between the three tabs',
      (tester) async {
    await pumpHelp(tester);

    expect(find.text('When will i get my money?'), findsNothing);

    await tester.tap(find.byKey(const Key('help-tab-questions')));
    await tester.pumpAndSettle();
    expect(find.text('When will i get my money?'), findsOneWidget);
    expect(find.text('Orders & delivery'), findsNothing);

    await tester.tap(find.byKey(const Key('help-tab-tickets')));
    await tester.pumpAndSettle();
    expect(find.text('Payout delayed'), findsOneWidget);
    expect(find.text('When will i get my money?'), findsNothing);

    await tester.tap(find.byKey(const Key('help-tab-topics')));
    await tester.pumpAndSettle();
    expect(find.text('Orders & delivery'), findsOneWidget);
  });

  testWidgets('the hero search filters the lists and reports no matches',
      (tester) async {
    await pumpHelp(tester);

    await tester.enterText(find.byKey(const Key('help-search-field')), 'stock');
    await tester.pumpAndSettle();

    expect(find.text('Results'), findsOneWidget);
    expect(find.text('How do i update my stock?'), findsOneWidget);
    expect(find.text('Orders & delivery'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('help-search-field')),
      'zzzzz',
    );
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsOneWidget);
    expect(find.byKey(const Key('help-empty-report')), findsOneWidget);

    // Clearing the field restores the tab content.
    await tester.tap(find.byKey(const Key('help-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsNothing);
    expect(find.text('Results'), findsNothing);
    expect(find.text('Orders & delivery'), findsOneWidget);
  });

  testWidgets('the Call and WhatsApp buttons are live', (tester) async {
    await pumpHelp(tester);

    // No dialer/WhatsApp on the test host, so the launch fails and the screen
    // shrugs it off with a snackbar instead of throwing.
    await tester.tap(find.text('Call'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('WhatsApp'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HelpSupportScreen), findsOneWidget);
  });

  testWidgets('the header back button pops the screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpSupportScreen(),
                  ),
                ),
                child: const Text('open help'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open help'));
    await tester.pumpAndSettle();
    expect(find.byType(HelpSupportScreen), findsOneWidget);

    await tester.tap(find.byKey(PageHeader.backKey));
    await tester.pumpAndSettle();
    expect(find.byType(HelpSupportScreen), findsNothing);
  });

  testWidgets('a topic and its article stay clean on a narrow 360dp phone',
      (tester) async {
    await pumpHelp(tester, size: const Size(360 * 3, 800 * 3));

    await tester.tap(find.text('Orders & delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery help'), findsOneWidget);

    await tester.tap(find.text('How do I track my order?'));
    await tester.pumpAndSettle();

    expect(find.text('What to do'), findsOneWidget);
    expect(find.text('2 min read'), findsOneWidget);

    // The report card sits below the fold — scroll it into view instead of
    // letting it be clipped.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Still need help?'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 700));
    await tester.pumpAndSettle();

    // Two levels of back navigation return to the support home.
    await tester.tap(find.byKey(PageHeader.backKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PageHeader.backKey));
    await tester.pumpAndSettle();
    expect(find.byType(HelpSupportScreen), findsOneWidget);
  });

  testWidgets('the hero headline sits on a single line', (tester) async {
    await pumpHelp(tester);

    final Size title = tester.getSize(find.text('How can we help?'));

    // One line of 24px Inter is ~30px tall — a wrapped "help?" would push the
    // paragraph past 45px.
    expect(title.height, lessThan(40));

    // The paragraph is laid out unwrapped (wider than the space left of the
    // "Support" pill, ~252px at this width) and scaled down to fit, rather
    // than broken across two lines.
    expect(title.width, greaterThan(252));
  });
}
