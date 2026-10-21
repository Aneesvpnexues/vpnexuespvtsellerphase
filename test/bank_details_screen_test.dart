import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/bank_details_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: BankDetailsScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 162 bank details content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Bank Details'), findsOneWidget);
    expect(find.text('State Bank of India'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('3421'), findsOneWidget);
    expect(find.text('Account holder'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('IFSC'), findsOneWidget);
    expect(find.text('SBINOOO1234'), findsOneWidget);
    expect(
      find.text(
        'Withdrawals go to your primary account \n'
        'within 1 working day',
      ),
      findsOneWidget,
    );
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('ramesh@upi'), findsOneWidget);
    expect(find.text('Linked to this account'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Add another bank account'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Bank Details')).left, closeTo(68, 3));
    expect(rectOf(find.text('Bank Details')).top, closeTo(24, 6));
    expect(rectOf(find.text('State Bank of India')).left, closeTo(45, 3));
    expect(rectOf(find.text('State Bank of India')).top, closeTo(99, 5));
    expect(rectOf(find.text('3421')).left, closeTo(228, 3));
    expect(rectOf(find.text('3421')).top, closeTo(145, 6));
    expect(rectOf(find.text('Account holder')).left, closeTo(45, 3));
    expect(rectOf(find.text('Account holder')).top, closeTo(193, 6));
    expect(rectOf(find.text('Ramesh Kumar')).left, closeTo(45, 3));
    expect(rectOf(find.text('Ramesh Kumar')).top, closeTo(211, 6));
    expect(rectOf(find.text('IFSC')).left, closeTo(343, 3));
    expect(rectOf(find.text('IFSC')).top, closeTo(193, 6));
    expect(rectOf(find.text('SBINOOO1234')).left, closeTo(270, 3));
    expect(rectOf(find.text('SBINOOO1234')).top, closeTo(211, 6));
    expect(rectOf(find.text('UPI')).left, closeTo(47, 3));
    expect(rectOf(find.text('UPI')).top, closeTo(280, 6));
    expect(rectOf(find.text('ramesh@upi')).left, closeTo(91, 3));
    expect(rectOf(find.text('ramesh@upi')).top, closeTo(320, 6));
    expect(rectOf(find.text('Linked to this account')).left, closeTo(92, 3));
    expect(rectOf(find.text('Linked to this account')).top, closeTo(335, 6));
    expect(rectOf(find.text('Active')).left, closeTo(325, 3));
    expect(rectOf(find.text('Active')).top, closeTo(327, 6));
    expect(rectOf(find.text('Add another bank account')).left, closeTo(124, 3));
    expect(rectOf(find.text('Add another bank account')).top, closeTo(421, 6));
    expect(rectOf(find.text('Add another bank account')).center.dx, closeTo(216.5, 6));
  });

  testWidgets('the withdrawals note is centred under the add row', (
    tester,
  ) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    final Rect note = tester
        .getRect(
          find.text(
            'Withdrawals go to your primary account \n'
            'within 1 working day',
          ),
        )
        .translate(-origin.dx, -origin.dy);

    expect(note.center.dx, closeTo(206, 6));
    expect(note.top, closeTo(474, 6));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: BankDetailsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Bank Details'), findsOneWidget);
    expect(find.text('Add another bank account'), findsOneWidget);
  });

  testWidgets('the bank details row of the profile opens this screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(120, 780));
    await tester.pumpAndSettle();

    expect(find.byType(BankDetailsScreen), findsOneWidget);
    expect(find.text('State Bank of India'), findsOneWidget);
  });
}
