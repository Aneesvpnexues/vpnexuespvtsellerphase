import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/add_product_screen.dart';
import 'package:seller_app/screens/bank_details_screen.dart';
import 'package:seller_app/screens/business_farm_screen.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';
import 'package:seller_app/screens/order_accepted_screen.dart';
import 'package:seller_app/screens/order_details_screen.dart';
import 'package:seller_app/screens/order_ready_screen.dart';
import 'package:seller_app/screens/otp_screen.dart';
import 'package:seller_app/screens/personal_details_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/settings_screen.dart';
import 'package:seller_app/screens/step01_location_screen.dart';
import 'package:seller_app/screens/step02_seller_type_screen.dart';
import 'package:seller_app/screens/verification_kyc_screen.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';

/// Zeplin labels sit in boxes that hug the text, and the app bundles the design
/// font (Inter) so the advances match. Inter is slightly wider than the Roboto
/// the app used to fall back to, so a label box taken 1:1 from Zeplin can be a
/// pixel or two short. `LabelText` disables wrapping for that reason; this test
/// guards the whole app against silently wrapping to two lines.
Future<void> _loadInter() async {
  const List<String> files = <String>[
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-ExtraBold.ttf',
  ];
  final FontLoader loader = FontLoader('Inter');
  for (final String file in files) {
    loader.addFont(rootBundle.load(file));
  }
  await loader.load();
}

void main() {
  testWidgets('no text wraps when the design font (Inter) is used', (
    WidgetTester tester,
  ) async {
    await _loadInter();
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final Map<String, Widget> screens = <String, Widget>{
      'WelcomeSellerScreen': const WelcomeSellerScreen(),
      'OtpScreen': const OtpScreen(),
      'Step01LocationScreen': const Step01LocationScreen(),
      'Step02SellerTypeScreen': const Step02SellerTypeScreen(),
      'SellerHomeScreen': const SellerHomeScreen(),
      'MyProductsScreen': const MyProductsScreen(),
      'MyOrdersScreen': const MyOrdersScreen(),
      'OrderDetailsScreen': const OrderDetailsScreen(),
      'OrderAcceptedScreen': const OrderAcceptedScreen(),
      'OrderReadyScreen': const OrderReadyScreen(),
      'ProfileScreen': const ProfileScreen(),
      'PersonalDetailsScreen': const PersonalDetailsScreen(),
      'BusinessFarmScreen': const BusinessFarmScreen(),
      'VerificationKycScreen': const VerificationKycScreen(),
      'BankDetailsScreen': const BankDetailsScreen(),
      'SettingsScreen': const SettingsScreen(),
      'AddProductScreen': const AddProductScreen(),
    };

    final List<String> wrapped = <String>[];
    final List<String> overflowing = <String>[];
    int checked = 0;

    for (final MapEntry<String, Widget> entry in screens.entries) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: entry.value,
        ),
      );
      await tester.pumpAndSettle();

      for (final Element element in find.byType(Text).evaluate()) {
        final RenderObject? renderObject = element.renderObject;
        if (renderObject is! RenderParagraph) {
          continue;
        }
        final TextPainter intrinsic = TextPainter(
          text: renderObject.text,
          textDirection: TextDirection.ltr,
        )..layout();
        checked++;

        if (renderObject.size.height > intrinsic.height + 0.5) {
          wrapped.add(
            '${entry.key}: "${renderObject.text.toPlainText()}" '
            'renders ${renderObject.size.height.toStringAsFixed(1)}px tall '
            'but needs only ${intrinsic.height.toStringAsFixed(1)}px',
          );
        } else if (intrinsic.width > renderObject.size.width + 0.5) {
          overflowing.add(
            '${entry.key}: "${renderObject.text.toPlainText()}" '
            'overflows by ${(intrinsic.width - renderObject.size.width).toStringAsFixed(1)}px',
          );
        }
      }
    }

    debugPrint('measured $checked text runs on ${screens.length} screens');
    for (final String line in overflowing) {
      debugPrint('overflow (paints in full, no wrap): $line');
    }
    expect(wrapped, isEmpty, reason: wrapped.join('\n'));
  });
}
