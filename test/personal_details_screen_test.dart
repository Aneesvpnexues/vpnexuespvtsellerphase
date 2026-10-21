import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/personal_details_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: PersonalDetailsScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 159 personal details content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('RK'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('+91 12345 67890'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('(optional)'), findsOneWidget);
    expect(find.text('you@example.com'), findsOneWidget);
    expect(find.text('Seller Type'), findsOneWidget);
    expect(find.text('Farmer'), findsOneWidget);
    expect(find.text('Trader'), findsOneWidget);
    expect(find.text('FPO / Group'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Personal Details')).left, closeTo(68, 3));
    expect(rectOf(find.text('Personal Details')).top, closeTo(24, 4));
    expect(rectOf(find.text('RK')).center.dx, closeTo(206, 12));
    expect(rectOf(find.text('RK')).center.dy, closeTo(153, 12));
    expect(rectOf(find.text('Full Name')).left, closeTo(46, 3));
    expect(rectOf(find.text('Full Name')).top, closeTo(255, 5));
    expect(rectOf(find.text('Ramesh Kumar')).left, closeTo(92, 3));
    expect(rectOf(find.text('Ramesh Kumar')).top, closeTo(289, 5));
    expect(rectOf(find.text('+91 12345 67890')).left, closeTo(92, 3));
    expect(rectOf(find.text('+91 12345 67890')).top, closeTo(365, 5));
    expect(rectOf(find.text('you@example.com')).left, closeTo(92, 3));
    expect(rectOf(find.text('you@example.com')).top, closeTo(441, 5));
    expect(rectOf(find.text('Seller Type')).left, closeTo(46, 3));
    expect(rectOf(find.text('Seller Type')).top, closeTo(483, 5));
    expect(rectOf(find.text('Save changes')).center.dx, closeTo(206, 6));
    expect(rectOf(find.text('Save changes')).center.dy, closeTo(827, 10));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: PersonalDetailsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });
}
