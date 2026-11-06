import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/business_details_screen.dart';
import 'package:seller_app/screens/otp_screen.dart';
import 'package:seller_app/screens/personal_details_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/verify_detaile.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';
import 'package:seller_app/services/auth_flow.dart';

import 'fake_auth_flow.dart';

Future<void> pumpFlow(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: WelcomeSellerScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AuthFlow.debugOverride = FakeAuthFlow();
    SellerProfileStore.instance.reset();
    Step03BusinessDetailsScreen.debugProfileSaver = ({
      required String name,
      required String mobile,
      required String sellerType,
      required String businessName,
      required String businessLocation,
      required String businessAddress,
    }) async => '9df39d4b-5d7a-457e-80a9-8f40dd0807e9';
  });

  tearDown(() {
    AuthFlow.debugOverride = null;
    SellerProfileStore.instance.reset();
    Step03BusinessDetailsScreen.debugProfileSaver = null;
  });

  testWidgets(
    'login and onboarding flow walks Verify -> Registration -> Bank',
    (tester) async {
      await pumpFlow(tester);

      await tester.enterText(find.byKey(const Key('loginPhone')), '9876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();
      expect(find.byType(OtpScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // A brand-new seller starts at step 1: Verify Your Details.
      expect(find.byType(VerifyDetaileScreen), findsOneWidget);
      expect(SellerProfileStore.instance.mobile, '+91 9876543210');

      // No documents were picked (uploads need the network), so KYC stays
      // incomplete and the flow moves on to Personal Details.
      await tester.tap(find.byKey(const Key('verify-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalDetailsScreen), findsOneWidget);

      // Mark personal details as complete so the flow continues to Business
      // Details.
      SellerProfileStore.instance.setCompletion(
        profileComplete: SellerProfileStore.instance.profileComplete,
        bankComplete: SellerProfileStore.instance.bankComplete,
        verificationComplete: SellerProfileStore.instance.verificationComplete,
        personalComplete: true,
      );

      await tester.tap(find.byKey(const Key('save-personal-details')));
      await tester.pumpAndSettle();
      expect(find.byType(Step03BusinessDetailsScreen), findsOneWidget);

      // The seller would have uploaded documents on the previous screen;
      // mark KYC done here because the upload path cannot run in tests.
      SellerProfileStore.instance.setCompletion(
        profileComplete: SellerProfileStore.instance.profileComplete,
        bankComplete: SellerProfileStore.instance.bankComplete,
        verificationComplete: true,
        personalComplete: true,
      );

      await tester.enterText(find.byKey(const Key('businessName')), 'Ravi');
      await tester.enterText(find.byKey(const Key('businessFarm')), 'Green Farm');
      await tester.enterText(
        find.byKey(const Key('businessAddress')),
        '12 Main Street',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('business-continue')));
      await tester.pumpAndSettle();

      // Step 3: Bank Details — KYC and registration are both done.
      expect(find.byType(BankDetaileScreen), findsOneWidget);
      expect(find.byType(VerifyDetaileScreen), findsNothing);

      await tester.tap(find.byKey(const Key('bank-continue')));
      await tester.pumpAndSettle();

      // The empty bank form fails local validation, so the seller stays on
      // Bank Details and Home is not reached yet.
      expect(find.byType(BankDetaileScreen), findsOneWidget);
      expect(find.byType(SellerHomeScreen), findsNothing);
    },
  );
}
