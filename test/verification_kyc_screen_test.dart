import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/verification_kyc_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: VerificationKycScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 161 verification kyc content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Verification (KYC)'), findsOneWidget);
    expect(find.text('Verified Seller'), findsOneWidget);
    expect(find.text('Buyer see a green tick on your profile'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Aadhaar Card'), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    expect(find.text('Pan Card'), findsOneWidget);
    expect(find.text('ABCDE'), findsOneWidget);
    expect(find.text('f'), findsOneWidget);
    expect(find.text('Farm Ownership\nCertificate'), findsOneWidget);
    expect(find.text('Submitted 10 Mar 2024'), findsOneWidget);
    expect(find.text('Verfied'), findsNWidgets(2));
    expect(find.text('Under review'), findsOneWidget);
    expect(
      find.text(
        'Your documents are encrypted and only used\nto verify your identity',
      ),
      findsOneWidget,
    );
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Verification (KYC)')).left, closeTo(68, 3));
    expect(rectOf(find.text('Verification (KYC)')).top, closeTo(22, 4));
    expect(rectOf(find.text('Verified Seller')).left, closeTo(116, 3));
    expect(rectOf(find.text('Verified Seller')).top, closeTo(105, 6));
    expect(
      rectOf(find.text('Buyer see a green tick on your profile')).top,
      closeTo(133, 4),
    );
    expect(rectOf(find.text('Documents')).left, closeTo(46, 3));
    expect(rectOf(find.text('Documents')).top, closeTo(199, 4));
    expect(rectOf(find.text('Aadhaar Card')).left, closeTo(90, 3));
    expect(rectOf(find.text('Aadhaar Card')).top, closeTo(239, 5));
    expect(rectOf(find.text('4821')).left, closeTo(132, 3));
    expect(rectOf(find.text('4821')).top, closeTo(254, 5));
    expect(rectOf(find.text('Pan Card')).left, closeTo(90, 3));
    expect(rectOf(find.text('Pan Card')).top, closeTo(297, 5));
    expect(
      rectOf(find.text('Farm Ownership\nCertificate')).left,
      closeTo(90, 3),
    );
    expect(
      rectOf(find.text('Farm Ownership\nCertificate')).top,
      closeTo(360, 5),
    );
    expect(rectOf(find.text('Submitted 10 Mar 2024')).left, closeTo(90, 3));
    expect(rectOf(find.text('Submitted 10 Mar 2024')).top, closeTo(381, 5));
    expect(rectOf(find.text('Verfied').first).left, closeTo(321, 3));
    expect(rectOf(find.text('Verfied').first).top, closeTo(246, 5));
    expect(rectOf(find.text('Under review')).left, closeTo(294, 3));
    expect(rectOf(find.text('Under review')).top, closeTo(369, 5));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: VerificationKycScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Verification (KYC)'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
  });

  testWidgets('the verification row of the profile opens this screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 924);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verification (KYC)'));
    await tester.pumpAndSettle();

    expect(find.byType(VerificationKycScreen), findsOneWidget);
    expect(find.text('Verified Seller'), findsOneWidget);
  });
}

