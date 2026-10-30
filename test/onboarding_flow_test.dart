import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/business_details_screen.dart';
import 'package:seller_app/screens/location_screen.dart';
import 'package:seller_app/screens/otp_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/seller_type_screen.dart';
import 'package:seller_app/screens/verify_detaile.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';

Future<void> pumpFlow(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: WelcomeSellerScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Step03BusinessDetailsScreen.debugProfileSaver = ({
      required String name,
      required String mobile,
      required String sellerType,
      required String businessName,
      required String businessLocation,
      required String businessAddress,
    }) async => '9df39d4b-5d7a-457e-80a9-8f40dd0807e9';
  });

  tearDown(() => Step03BusinessDetailsScreen.debugProfileSaver = null);

  testWidgets('login and onboarding flow ends at the home page', (
    tester,
  ) async {
    await pumpFlow(tester);

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.byType(OtpScreen), findsOneWidget);

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.byType(Step01LocationScreen), findsOneWidget);

    await tester.tap(find.text('Use my current Location'));
    await tester.pumpAndSettle();
    expect(find.byType(Step02SellerTypeScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('seller-type-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(Step03BusinessDetailsScreen), findsOneWidget);

    await tester.enterText(find.byKey(const Key('businessName')), 'Ravi');
    await tester.enterText(find.byKey(const Key('businessFarm')), 'Green Farm');
    await tester.enterText(
      find.byKey(const Key('businessAddress')),
      '12 Main Street',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('business-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyDetaileScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('verify-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(BankDetaileScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('bank-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(BankDetaileScreen), findsOneWidget);
    expect(find.byType(SellerHomeScreen), findsNothing);
  });
}
