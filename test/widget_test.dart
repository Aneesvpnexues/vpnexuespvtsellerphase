import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/main.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';

/// Pumps the app on the 412x917 artboard the design was drawn for.
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SellerApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('only the splash arrow continues to the login screen', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);

    await tester.tapAt(const Offset(40, 120));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);

    await tester.tap(find.byKey(const Key('splashTap')));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeSellerScreen), findsOneWidget);
  });
}