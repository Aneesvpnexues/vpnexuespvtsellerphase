import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seller_app/screens/bank_detaile.dart';

void main() {
  testWidgets('debug ifsc step 4', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BankDetaileScreen()),
    );
    await tester.pumpAndSettle();

    Future<void> tapContinue() async {
      await tester.tap(find.byKey(const Key('bank-continue')));
      await tester.pumpAndSettle();
    }

    await tapContinue();
    debugPrint('STEP1: '
        '${ tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().where((s) => s.toLowerCase().contains('account') || s.toLowerCase().contains('bank') || s.toLowerCase().contains('ifsc')).join(' | ') }');

    await tester.enterText(
      find.byKey(const Key('bank-holder-name-field')),
      'Sita Devi',
    );
    await tester.pump();
    await tapContinue();

    await tester.tap(find.byKey(const Key('bank-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-option-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bank-account-number-field')),
      '123',
    );
    await tester.pump();
    await tapContinue();

    await tester.enterText(
      find.byKey(const Key('bank-account-number-field')),
      '987654321098',
    );
    await tester.enterText(
      find.byKey(const Key('bank-ifsc-field')),
      'SBIN0001234',
    );
    await tester.pump();
    await tapContinue();
    debugPrint('STEP4 texts: '
        '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().join(' | ')}');
    expect(find.text('Verify your IFSC code to continue'), findsOneWidget);
  });
}
