import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/otp_screen.dart';
import 'package:seller_app/theme/app_colors.dart';
import 'package:seller_app/widgets/bottom_deco.dart';

/// Pumps the OTP screen on the 412x917 artboard the design was drawn for.
Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: OtpScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the OTP screen content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('We\u2019ve sent a 6-digit code to'), findsOneWidget);
    expect(find.text('+91 1234567890'), findsOneWidget);
    expect(find.text('Resend OTP in 00:12'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
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
      borders.skip(1).every((b) => b.top.color == AppColors.otpIdleBorder),
      isTrue,
    );
    expect(
      borders.skip(1).every((b) => b.top.width == 1),
      isTrue,
    );
  });

  testWidgets('verify button keeps the design style', (tester) async {
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
      images.any((i) =>
          i.image is AssetImage &&
          (i.image as AssetImage).assetName == 'assets/otp/illustration.png'),
      isTrue,
    );
    expect(
      images.any((i) =>
          i.image is AssetImage &&
          (i.image as AssetImage).assetName == 'assets/otp/bottom_deco.png'),
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
    expect(topLeftOf(find.text('Resend OTP in 00:12')).dy, closeTo(599, 2));

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
    expect(deco.height, closeTo(131, 2));
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

  testWidgets('verify requires all six digits before opening the location '
      'page', (tester) async {
    await pumpScreen(tester);

    // Empty OTP: message, no navigation.
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the 6-digit OTP'), findsOneWidget);
    expect(find.text('STEP 01'), findsNothing);
    expect(find.text('Enter OTP'), findsOneWidget);

    // Five digits are not enough either.
    await tester.enterText(find.byType(TextField), '91827');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the 6-digit OTP'), findsOneWidget);
    expect(find.text('STEP 01'), findsNothing);

    // Six digits navigate.
    await tester.enterText(find.byType(TextField), '918273');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('STEP 01'), findsOneWidget);
    expect(find.text('Choose your location'), findsOneWidget);
    expect(find.text('Use my current Location'), findsOneWidget);
    expect(find.text('Enter OTP'), findsNothing);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('STEP 01'), findsNothing);
  });

  testWidgets('shows the dial code and phone number passed from the welcome '
      'screen', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: OtpScreen(dialCode: '+65', phoneNumber: '81234567'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+65 81234567'), findsOneWidget);
    expect(find.text('+91 1234567890'), findsNothing);
  });

  testWidgets('resend countdown ticks and turns into a tappable Resend OTP', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Resend OTP in 00:12'), findsOneWidget);
    expect(find.byKey(const Key('resendOtp')), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Resend OTP in 00:11'), findsOneWidget);

    // Let the remaining 11 seconds run out.
    await tester.pump(const Duration(seconds: 11));
    expect(find.text('Resend OTP'), findsOneWidget);
    expect(find.byKey(const Key('resendOtp')), findsOneWidget);
    expect(find.textContaining('Resend OTP in'), findsNothing);

    // Tapping it restarts the countdown.
    await tester.tap(find.byKey(const Key('resendOtp')));
    await tester.pump();
    expect(find.text('Resend OTP in 00:12'), findsOneWidget);
    expect(find.text('A new OTP has been sent.'), findsOneWidget);
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
