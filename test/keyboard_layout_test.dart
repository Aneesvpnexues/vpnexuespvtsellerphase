import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/location_screen.dart';
import 'package:seller_app/screens/otp_screen.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';

const double _keyboardHeight = 300;

Future<void> _pumpWithKeyboard(
  WidgetTester tester,
  Widget screen,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardHeight);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

Rect _rectOf(WidgetTester tester, Finder finder) {
  final origin = tester.getTopLeft(find.byType(MaterialApp));
  return tester.getRect(finder).translate(-origin.dx, -origin.dy);
}

void main() {
  testWidgets('Welcome keeps its full-width layout above the keyboard', (
    tester,
  ) async {
    await _pumpWithKeyboard(
      tester,
      const WelcomeSellerScreen(),
      const Size(412, 917),
    );

    expect(tester.takeException(), isNull);
    expect(
      _rectOf(tester, find.text('Welcome back')).left,
      closeTo(24, 1),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('OTP keeps its full-width layout above the keyboard', (
    tester,
  ) async {
    await _pumpWithKeyboard(tester, const OtpScreen(phone: '+91 1234567890'), const Size(412, 917));

    expect(tester.takeException(), isNull);
    final title = _rectOf(tester, find.text('Enter OTP'));
    expect(title.left, closeTo(24, 1));
    expect(title.top, closeTo(373, 2));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('Location keeps its full-width layout above the keyboard', (
    tester,
  ) async {
    await _pumpWithKeyboard(
      tester,
      const Step01LocationScreen(),
      const Size(412, 917),
    );

    expect(tester.takeException(), isNull);
    expect(
      _rectOf(tester, find.text('Use my current Location')).left,
      closeTo(24, 1),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });







  testWidgets('Bank IFSC field scrolls above the Continue button', (
    tester,
  ) async {
    await _pumpWithKeyboard(
      tester,
      const BankDetaileScreen(),
      const Size(412, 936),
    );

    await tester.enterText(
      find.byKey(const Key('bank-ifsc-field')),
      'SBIN0001234',
    );
    await tester.pumpAndSettle();

    final field = _rectOf(tester, find.byKey(const Key('bank-ifsc-field')));
    final button = _rectOf(tester, find.byKey(const Key('bank-continue')));
    expect(field.bottom, lessThan(button.top));
  });
}
