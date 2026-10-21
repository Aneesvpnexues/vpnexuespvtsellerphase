import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/personal_details_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';

Future<void> pumpProfile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 980);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 151 profile content', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Profile'), findsNWidgets(2));
    expect(find.text('Withdrawal balance'), findsOneWidget);
    expect(find.text('\u20B912,480'), findsOneWidget);
    expect(find.text('\u20B923,480 earned from 12 orders'), findsOneWidget);
    expect(find.text('This month'), findsNWidgets(2));
    expect(find.text('Withdraw'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Farmer, Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('Verfiled Seller'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Orders'), findsNWidgets(2));
    expect(find.text('\u20B92,480'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('App'), findsOneWidget);
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Name, phone, email'), findsOneWidget);
    expect(find.text('Business & Farm'), findsOneWidget);
    expect(find.text('Farm details, location, pickup & delivery'), findsOneWidget);
    expect(find.text('Verification (KYC)'), findsOneWidget);
    expect(find.text('Aadhaar, PAN, farm proof'), findsOneWidget);
    expect(find.text('Bank Details'), findsOneWidget);
    expect(find.text('SBI'), findsOneWidget);
    expect(find.text('3421'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('layout matches the 412x980 design geometry', (tester) async {
    await pumpProfile(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Profile').first).left, closeTo(68, 3));
    expect(rectOf(find.text('Profile').first).top, closeTo(24, 4));
    expect(rectOf(find.text('Withdrawal balance')).left, closeTo(45, 3));
    expect(rectOf(find.text('Withdrawal balance')).top, closeTo(92, 4));
    expect(rectOf(find.text('\u20B912,480')).left, closeTo(45, 4));
    expect(rectOf(find.text('\u20B912,480')).top, closeTo(124, 8));
    expect(rectOf(find.text('Ramesh Kumar')).left, closeTo(104, 3));
    expect(rectOf(find.text('Ramesh Kumar')).top, closeTo(361, 5));
    expect(rectOf(find.text('Farmer, Salem, Tamil Nadu')).left, closeTo(104, 3));
    expect(rectOf(find.text('Farmer, Salem, Tamil Nadu')).top, closeTo(385, 4));
    expect(rectOf(find.text('Personal Details')).left, closeTo(91, 3));
    expect(rectOf(find.text('Personal Details')).top, closeTo(586, 5));
    expect(rectOf(find.text('Bank Details')).left, closeTo(91, 3));
    expect(rectOf(find.text('Bank Details')).top, closeTo(760, 5));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Withdrawal balance'), findsOneWidget);
  });

  testWidgets('the personal details row opens the 159 screen', (tester) async {
    await pumpProfile(tester);

    await tester.tapAt(const Offset(120, 606));
    await tester.pumpAndSettle();

    expect(find.byType(PersonalDetailsScreen), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('the profile tab of the bottom nav opens the profile screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1071);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SellerHomeScreen()));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(374, 982));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Withdrawal balance'), findsOneWidget);
  });
}
