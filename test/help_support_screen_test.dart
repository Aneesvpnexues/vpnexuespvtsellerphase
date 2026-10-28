import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/help_support_screen.dart';
import 'package:seller_app/screens/report_problem_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the help topics by default', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Orders & delivery'), findsOneWidget);
    expect(find.text('Products & stock'), findsOneWidget);
    expect(find.text('Payments & wallet'), findsOneWidget);
    expect(find.text('Account & verification'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('3 articles'), findsNWidgets(4));
  });

  testWidgets('Questions and Tickets switch the panel content', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('help-tab-questions')));
    await tester.pumpAndSettle();

    expect(find.text('How do I mark an order as ready?'), findsOneWidget);
    expect(find.text('Tap to read answer'), findsNWidgets(5));
    expect(find.text('Orders & delivery'), findsNothing);

    await tester.tap(find.byKey(const Key('help-tab-tickets')));
    await tester.pumpAndSettle();

    expect(find.text('No support tickets yet'), findsOneWidget);
    expect(find.text('How do I mark an order as ready?'), findsNothing);

    await tester.tap(find.byKey(const Key('help-tab-topics')));
    await tester.pumpAndSettle();

    expect(find.text('Orders & delivery'), findsOneWidget);
    expect(find.text('No support tickets yet'), findsNothing);
  });

  testWidgets('an FAQ row opens its answer sheet', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('help-tab-questions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('help-faq-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help-answer-sheet')), findsOneWidget);
    expect(
      find.textContaining('review the items and pickup details'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('help-answer-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help-answer-sheet')), findsNothing);
  });

  testWidgets('the Tickets empty state opens the report form', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('help-tab-tickets')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('help-create-ticket')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
  });

  testWidgets('the Topics report row opens the report form', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
  });
}
