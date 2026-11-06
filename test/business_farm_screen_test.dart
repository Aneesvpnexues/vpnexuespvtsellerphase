import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/business_farm_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1103);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: BusinessFarmScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 160 business and farm content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Business & Farm'), findsOneWidget);
    // Hero shows static text; the Farm / Business Name field renders it as
    // an editable TextField, so find.text matches both widgets.
    expect(find.text('Kumar Organic Farm'), findsNWidgets(2));
    expect(find.text('Salem, Tamil Nadu'), findsNWidgets(2));
    expect(find.text('Farm / Business Name'), findsOneWidget);
    expect(find.text('Farm Size'), findsOneWidget);
    expect(find.text('What you grow'), findsOneWidget);
    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('Spinach'), findsOneWidget);
    expect(find.text('Carrots'), findsOneWidget);
    expect(find.text('Onions'), findsOneWidget);
    expect(find.text('Green Chillies'), findsOneWidget);
    expect(find.text('Potatoes'), findsOneWidget);
    expect(find.text('Address & Location'), findsOneWidget);
    expect(find.text('How buyers get orders'), findsOneWidget);
    expect(find.text('Buyer Pickup'), findsOneWidget);
    expect(find.text('Buyers collect from your location'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('You delivery to the buyer'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('acres'), findsOneWidget);
  });

  testWidgets('layout matches the 412x1103 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Business & Farm').first).left, closeTo(68, 3));
    expect(rectOf(find.text('Business & Farm').first).top, closeTo(22, 4));
    expect(rectOf(find.text('Kumar Organic Farm').last).left, closeTo(92, 3));
    expect(rectOf(find.text('Kumar Organic Farm').last).top, closeTo(309, 5));
    expect(rectOf(find.text('Farm / Business Name')).left, closeTo(46, 3));
    expect(rectOf(find.text('Farm / Business Name')).top, closeTo(275, 4));
    expect(rectOf(find.text('Farm Size')).left, closeTo(46, 3));
    expect(rectOf(find.text('Farm Size')).top, closeTo(351, 4));
    expect(rectOf(find.text('What you grow')).left, closeTo(46, 3));
    expect(rectOf(find.text('What you grow')).top, closeTo(427, 4));
    expect(rectOf(find.text('Address & Location')).left, closeTo(46, 3));
    expect(rectOf(find.text('Address & Location')).top, closeTo(573, 4));
    expect(rectOf(find.text('How buyers get orders')).left, closeTo(46, 3));
    expect(rectOf(find.text('How buyers get orders')).top, closeTo(814, 4));
    expect(rectOf(find.text('Buyer Pickup')).left, closeTo(90, 3));
    expect(rectOf(find.text('Buyer Pickup')).top, closeTo(854, 4));
    expect(rectOf(find.text('Delivery')).left, closeTo(90, 3));
    expect(rectOf(find.text('Delivery')).top, closeTo(914, 6));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: BusinessFarmScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Business & Farm'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('the business and farm row of the profile opens this screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 924);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Business & Farm'));
    await tester.pumpAndSettle();

    expect(find.byType(BusinessFarmScreen), findsOneWidget);
    expect(find.text('Address & Location'), findsOneWidget);
  });
}

