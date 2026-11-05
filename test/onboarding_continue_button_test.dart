import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/business_details_screen.dart';
import 'package:seller_app/screens/seller_type_screen.dart';
import 'package:seller_app/screens/verify_detaile.dart';
import 'package:seller_app/theme/app_colors.dart';

void main() {
  final screens = <(String, Widget, double, Key)>[
    (
      'seller type',
      const Step02SellerTypeScreen(),
      Step02SellerTypeScreen.designHeight,
      const Key('seller-type-continue'),
    ),
    (
      'business details',
      const Step03BusinessDetailsScreen(),
      Step03BusinessDetailsScreen.designHeight,
      const Key('business-continue'),
    ),
    (
      'verify details',
      const VerifyDetaileScreen(),
      VerifyDetaileScreen.designHeight,
      const Key('verify-continue'),
    ),
    (
      'bank details',
      const BankDetaileScreen(),
      BankDetaileScreen.designHeight,
      const Key('bank-continue'),
    ),
  ];

  for (final (name, screen, designHeight, key) in screens) {
    testWidgets('$name uses the shared Continue size and placement', (
      tester,
    ) async {
      tester.view.physicalSize = Size(412, designHeight);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();

      if (key == const Key('business-continue')) {
        await tester.enterText(find.byKey(const Key('businessName')), 'Ravi');
        await tester.enterText(
          find.byKey(const Key('businessFarm')),
          'Green Farm',
        );
        await tester.enterText(
          find.byKey(const Key('businessAddress')),
          '12 Main Street',
        );
        await tester.pump();
      }

      final Rect rect = tester.getRect(find.byKey(key));
      expect(rect.left, closeTo(22, 1));
      expect(rect.width, closeTo(368, 1));
      expect(rect.height, closeTo(54, 1));
      expect(rect.bottom, closeTo(designHeight - 16, 1));

      final BoxDecoration decoration =
          tester.widget<Container>(find.byKey(key)).decoration!
              as BoxDecoration;
      expect(
        decoration.borderRadius,
        const BorderRadius.all(Radius.circular(18)),
      );
      expect((decoration.gradient! as LinearGradient).colors, const [
        AppColors.continueGradientStart,
        AppColors.continueGradientEnd,
      ]);
    });
  }
}

