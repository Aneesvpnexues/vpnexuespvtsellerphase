import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/location_screen.dart';
import 'package:seller_app/screens/otp_screen.dart';
import 'package:seller_app/services/auth_flow.dart';
import 'package:seller_app/theme/app_colors.dart';
import 'package:seller_app/widgets/bottom_deco.dart';

import 'fake_auth_flow.dart';

/// Pumps the OTP screen on the 412x917 artboard the design was drawn for.
Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: OtpScreen(phone: '+91 1234567890')),
  );
  await tester.pumpAndSettle();
}

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

  testWidgets('renders the OTP screen content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('We\u2019ve sent a 6-digit code to'), findsOneWidget);
    expect(find.text('+91 1234567890'), findsOneWidget);
    // The resend label counts down, so only its key is stable across the
    // pumpAndSettle above (it may show '00:60' or already have ticked).
    expect(find.byKey(const Key('otpResendLabel')), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('resend countdown starts at 00:60 and unlocks Resend OTP', (
    tester,
  ) async {
    // The resend path re-sends the number of the round already in flight.
    fake.e164Phone = '+919876543210';
    fake.displayPhone = '+91 9876543210';
    fake.verificationId = 'fake-verification-id';
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: OtpScreen(phone: '+91 1234567890')),
    );
    await tester.pump();

    expect(find.text('Resent OTP in 00:60'), findsOneWidget);

    for (var elapsed = 0; elapsed < 59; elapsed++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('Resent OTP in 00:01'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Resend OTP'), findsOneWidget);

    await tester.tap(find.text('Resend OTP'));
    await tester.pump();
    expect(fake.resendCalls, 1);
    expect(find.text('Resent OTP in 00:60'), findsOneWidget);
  });

  testWidgets('renders six OTP boxes', (tester) async {
    await pumpScreen(tester);

    final borders = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration)
        .map((c) => c.decoration! as BoxDecoration)
        .where((d) => d.border != null)
        .map((d) => d.border! as Border)
        .toList();

    expect(borders.length, 6);
    expect(borders.first.top.color, AppColors.otpActiveBorder);
    expect(borders.first.top.width, 2);
    expect(
      borders.skip(1).every((d) => d.top.color == AppColors.otpIdleBorder),
      isTrue,
    );
    expect(
      borders.skip(1).every((d) => d.top.width == 1),
      isTrue,
    );
  });

  testWidgets('verify button is visual only', (tester) async {
    await pumpScreen(tester);

    final verify = tester.widget<Text>(find.text('Verify'));
    expect(verify.style?.color, AppColors.surface);

    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .toList();
    expect(decorations.any((d) => d.color == AppColors.primary), isTrue);
  });

  testWidgets('bottom decoration and illustration assets load', (tester) async {
    await pumpScreen(tester);

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images.length, 2);
    expect(
      images.any(
        (i) =>
            i.image is AssetImage &&
            (i.image as AssetImage).assetName == 'assets/otp/illustration.png',
      ),
      isTrue,
    );
    expect(
      images.any(
        (i) =>
            i.image is AssetImage &&
            (i.image as AssetImage).assetName == 'assets/otp/bottom_deco.png',
      ),
      isTrue,
    );
  });

  testWidgets('layout matches the design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Offset topLeftOf(Finder finder) => tester.getTopLeft(finder) - origin;
    Rect rectOf(Finder finder) => tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Horizontal margin is 24 on the 412 artboard.
    expect(topLeftOf(find.text('Enter OTP')).dx, closeTo(24, 1));
    expect(topLeftOf(find.text('We\u2019ve sent a 6-digit code to')).dx,
        closeTo(24, 1));
    expect(topLeftOf(find.text('+91 1234567890')).dx, closeTo(24, 1));

    // Vertical anchors, measured from the design PNG.
    expect(topLeftOf(find.text('Enter OTP')).dy, closeTo(373, 2));
    expect(topLeftOf(find.text('We\u2019ve sent a 6-digit code to')).dy,
        closeTo(425, 2));
    expect(topLeftOf(find.text('+91 1234567890')).dy, closeTo(455, 2));
    expect(topLeftOf(find.byKey(const Key('otpResendLabel'))).dy,
        closeTo(599, 2));

    // OTP row: x 24..388, y 521..583, height 62.
    final otpRow = rectOf(find.byType(Row).first);
    expect(otpRow.left, closeTo(24, 1));
    expect(otpRow.right, closeTo(388, 1));
    expect(otpRow.top, closeTo(521, 2));
    expect(otpRow.height, closeTo(62, 2));

    // Verify button: y 731..785, full width inside the 24px margins.
    final button = rectOf(_findVerifyButton());
    expect(button.left, closeTo(24, 1));
    expect(button.right, closeTo(388, 1));
    expect(button.top, closeTo(731, 2));
    expect(button.height, closeTo(54, 2));

    // Bottom artwork sits flush against the bottom edge, 131 tall.
    final deco = rectOf(find.byType(Image).first);
    expect(deco.left, closeTo(0, 1));
    expect(deco.width, closeTo(412, 1));
    expect(deco.bottom, closeTo(917, 1));
    expect(deco.height, closeTo(131, 1));
  });

  testWidgets('otp boxes render typed digits', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(OtpCaret), findsOneWidget);

    await tester.enterText(find.byType(TextField), '918273');
    await tester.pump();

    expect(find.text('9'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Caret sits in the box that would receive the next digit; all six filled
    // means no caret left.
    expect(find.byType(OtpCaret), findsNothing);

    await tester.enterText(find.byType(TextField), '91827');
    await tester.pump();

    expect(find.text('3'), findsNothing);
    expect(find.byType(OtpCaret), findsOneWidget);
  });

  testWidgets('verify stays put while fewer than six digits are typed', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '91827');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.byType(Step01LocationScreen), findsNothing);
    expect(find.text('Enter OTP'), findsOneWidget);
    expect(fake.verifiedCodes, isEmpty);
  });

  testWidgets('rejected code shows an error, clears the boxes and stays', (
    tester,
  ) async {
    await pumpScreen(tester);
    fake.verifyError = 'Incorrect OTP. Check the code and try again.';

    await tester.enterText(find.byType(TextField), '111111');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    // Two pumps: one to run the verify microtask, one to paint the snackbar.
    // (pumpAndSettle would wait out the 4s snackbar timer and hide it again.)
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Incorrect OTP. Check the code and try again.'),
      findsOneWidget,
    );
    expect(find.byType(Step01LocationScreen), findsNothing);
    expect(find.text('Enter OTP'), findsOneWidget);
    // Boxes are empty again: caret back in the first box, no digits left.
    expect(find.byType(OtpCaret), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('verify navigates to the location page and back', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '918273');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('STEP 01'), findsOneWidget);
    expect(find.text('Choose your location'), findsOneWidget);
    expect(find.text('Use my current Location'), findsOneWidget);
    expect(find.text('Enter OTP'), findsNothing);
    // The verified number is handed to the profile store for STEP 03-05.
    expect(SellerProfileStore.instance.mobile, '+91 1234567890');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('STEP 01'), findsNothing);
  });
}

Finder _findVerifyButton() {
  return find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == AppColors.primary,
  );
}
