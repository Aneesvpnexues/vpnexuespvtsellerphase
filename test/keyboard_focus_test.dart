import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/business_details_screen.dart';
import 'package:seller_app/screens/settings_screen.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';

/// The soft keyboard must open when a field is tapped *and stay open*: the
/// screens below used to rebuild a different widget subtree the moment
/// `viewInsets.bottom` flipped from 0 to >0, which disposed the focused
/// field's FocusNode and immediately dismissed the keypad. The focused field
/// must also end up above the keypad ("only the relevant form column is
/// visible while typing").
const double _keyboard = 300;

bool _focusInsideTextInput(FocusNode? node) {
  final BuildContext? context = node?.context;
  if (context == null) return false;
  if (context.widget is EditableText) return true;
  return context.findAncestorWidgetOfExactType<EditableText>() != null;
}

Future<void> _pump(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

Future<void> _tapAndOpenKeyboard(
  WidgetTester tester,
  Finder field,
) async {
  await tester.tap(field);
  await tester.pump();
  expect(
    _focusInsideTextInput(FocusManager.instance.primaryFocus),
    isTrue,
    reason: 'tapping the field must give it focus',
  );

  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Welcome phone field keeps focus and stays above the keyboard', (
    tester,
  ) async {
    await _pump(tester, const WelcomeSellerScreen(), const Size(412, 917));

    await _tapAndOpenKeyboard(tester, find.byKey(const Key('loginPhone')));

    expect(
      _focusInsideTextInput(FocusManager.instance.primaryFocus),
      isTrue,
      reason: 'the keyboard opening must not drop focus on the phone field',
    );
    final field = tester.getRect(find.byKey(const Key('loginPhone')));
    expect(
      field.bottom,
      lessThanOrEqualTo(917 - _keyboard + 1),
      reason: 'the focused field must be revealed above the keypad',
    );
  });

  testWidgets('Business address keeps focus and scrolls above the keyboard', (
    tester,
  ) async {
    await _pump(
      tester,
      const Step03BusinessDetailsScreen(),
      const Size(412, 917),
    );

    await _tapAndOpenKeyboard(tester, find.byKey(const Key('businessAddress')));

    expect(
      _focusInsideTextInput(FocusManager.instance.primaryFocus),
      isTrue,
      reason: 'the keyboard opening must not drop focus on the address field',
    );
    final field = tester.getRect(find.byKey(const Key('businessAddress')));
    expect(field.bottom, lessThanOrEqualTo(917 - _keyboard + 1));
  });

  testWidgets('Bank IFSC field keeps focus and stays above the keyboard', (
    tester,
  ) async {
    await _pump(tester, const BankDetaileScreen(), const Size(412, 936));

    await _tapAndOpenKeyboard(tester, find.byKey(const Key('bank-ifsc-field')));

    expect(
      _focusInsideTextInput(FocusManager.instance.primaryFocus),
      isTrue,
      reason: 'the keyboard opening must not drop focus on the IFSC field',
    );
    final field = tester.getRect(find.byKey(const Key('bank-ifsc-field')));
    expect(field.bottom, lessThanOrEqualTo(936 - _keyboard + 1));
  });

  testWidgets('Settings mobile field keeps focus when the keyboard opens', (
    tester,
  ) async {
    await _pump(tester, const SettingsScreen(), const Size(412, 917));

    // The notifications card overlaps the bottom of the mobile field
    // (pre-existing layout overlap), so tap the top strip of the editable.
    await tester.tapAt(
      Offset(
        tester.getRect(find.byType(TextField)).center.dx,
        tester.getRect(find.byType(TextField)).top + 15,
      ),
    );
    await tester.pump();

    expect(
      _focusInsideTextInput(FocusManager.instance.primaryFocus),
      isTrue,
      reason: 'the keyboard opening must not drop focus on the field',
    );
  });
}
