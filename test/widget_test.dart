import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/main.dart';
import 'package:seller_app/screens/splash_screen.dart';

/// Pumps the app on the 412x917 artboard the design was drawn for.
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SellerApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app boots into the splash, then taps through to Welcome', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.text('Welcome Seller!', findRichText: true), findsNothing);

    await tester.tap(find.byKey(const Key('splashTap')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Seller!', findRichText: true), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('splash stays put until the arrow button is tapped', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.text('Welcome Seller!', findRichText: true), findsNothing);

    // Time passes well beyond the old two-second auto-advance delay; the
    // splash must not navigate on its own.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.text('Welcome Seller!', findRichText: true), findsNothing);
  });
}