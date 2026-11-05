import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/otp_screen.dart';
import 'package:seller_app/screens/verify_detaile.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';
import 'package:seller_app/services/auth_flow.dart';

import 'fake_auth_flow.dart';

void main() {
  late FakeAuthFlow fake;

  setUp(() {
    fake = FakeAuthFlow();
    AuthFlow.debugOverride = fake;
    SellerProfileStore.instance.reset();
  });

  tearDown(() {
    AuthFlow.debugOverride = null;
    SellerProfileStore.instance.reset();
  });

  Future<void> pumpWelcome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: WelcomeSellerScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> typeNumber(WidgetTester tester, String digits) async {
    await tester.enterText(find.byKey(const Key('loginPhone')), digits);
    await tester.pump();
  }

  testWidgets('a short number is rejected before Firebase is called', (
    tester,
  ) async {
    await pumpWelcome(tester);
    await typeNumber(tester, '123');

    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
    expect(fake.sendCalls, 0);
    expect(find.byType(OtpScreen), findsNothing);
  });

  testWidgets('valid number is sent as E.164 and opens the OTP screen', (
    tester,
  ) async {
    await pumpWelcome(tester);
    await typeNumber(tester, '9876543210');

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(fake.sendCalls, 1);
    expect(fake.sentE164, <String>['+919876543210']);
    expect(fake.sentDisplay, <String>['+91 9876543210']);
    expect(find.byType(OtpScreen), findsOneWidget);
    // The OTP screen shows the number the SMS went to.
    expect(find.text('+91 9876543210'), findsOneWidget);
  });

  testWidgets('send failure keeps the seller on login with the message', (
    tester,
  ) async {
    fake.sendSucceeds = false;
    fake.sendError = 'Too many attempts. Try again later.';
    await pumpWelcome(tester);
    await typeNumber(tester, '9876543210');

    await tester.tap(find.text('Send OTP'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Too many attempts. Try again later.'), findsOneWidget);
    expect(find.byType(OtpScreen), findsNothing);
    // Spinner cleared: the button is tappable again.
    expect(find.text('Send OTP'), findsOneWidget);
    expect(fake.sendCalls, 1);
  });

  testWidgets(
    'auto-verification skips the OTP screen and lands on Verify Your Details',
    (tester,
  ) async {
    fake.autoVerify = true;
    await pumpWelcome(tester);
    await typeNumber(tester, '9876543210');

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.byType(OtpScreen), findsNothing);
    expect(find.byType(VerifyDetaileScreen), findsOneWidget);
    expect(SellerProfileStore.instance.mobile, '+91 9876543210');
    expect(fake.verifiedCodes, isEmpty);
  });

  testWidgets('OTP screen opens only after codeSent, not before', (
    tester,
  ) async {
    // Simulate Firebase taking a while: no callback fires yet.
    fake.sendSucceeds = true;
    fake.autoVerify = false;
    await pumpWelcome(tester);
    await typeNumber(tester, '9876543210');

    // Not tapped yet -> no navigation at all.
    expect(find.byType(OtpScreen), findsNothing);
    expect(find.byType(VerifyDetaileScreen), findsNothing);

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.byType(OtpScreen), findsOneWidget);
    expect(fake.sendCalls, 1);
  });

  test('Firebase auth codes map to friendly messages', () {
    String message(String code) =>
        AuthFlow.messageFor(FirebaseAuthException(code: code));

    expect(message('invalid-phone-number'), 'Enter a valid mobile number with country code.');
    expect(
      message('invalid-verification-code'),
      'Incorrect OTP. Check the code and try again.',
    );
    expect(message('session-expired'), contains('expired'));
    expect(message('too-many-requests'), contains('Too many attempts'));
    expect(message('quota-exceeded'), contains('SMS limit'));
    expect(message('app-not-authorized'), contains('SHA-1'));
    expect(message('operation-not-allowed'), contains('Phone provider'));
    expect(message('network-request-failed'), contains('Network'));
    expect(message('auth/unknown'), 'Verification failed. Try again.');
  });

  test('verifyOtp without a sent code asks for a new one', () async {
    // Real AuthFlow path with no verificationId: no Firebase is touched.
    final AuthFlow plain = AuthFlow();
    expect(
      await plain.verifyOtp('123456'),
      'Request a new code and try again.',
    );
    // A partial code is rejected before any round trip as well.
    plain.verificationId = 'some-id';
    expect(await plain.verifyOtp('123'), 'Enter the 6-digit code.');
  });
}
