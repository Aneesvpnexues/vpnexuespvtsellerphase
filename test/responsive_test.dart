import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/add_products_screen.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/business_details_screen.dart';
import 'package:seller_app/screens/location_screen.dart';
import 'package:seller_app/screens/otp_screen.dart';
import 'package:seller_app/screens/personal_details_screen.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/review_ratings_page.dart';
import 'package:seller_app/screens/seller_type_screen.dart';
import 'package:seller_app/screens/verify_detaile.dart';
import 'package:seller_app/screens/wallet_page.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';
import 'package:seller_app/widgets/bottom_nav_bar.dart';

/// Every screen is a fixed Zeplin artboard that must render cleanly across
/// device sizes: scale down on small phones, keep 1:1 at the design size,
/// and scale up (capped at 1.5x) on tablets/foldables/large phones.
void main() {
  // Small phone -> landscape phone -> design -> large -> tablet -> huge.
  const sizes = <Size>[
    Size(320, 568),
    Size(390, 844),
    Size(412, 917),
    Size(892, 420),
    Size(768, 1024),
    Size(1024, 1366),
    Size(2000, 2000),
  ];

  final screens = <String, Widget Function()>{
    'WelcomeSellerScreen': () => const WelcomeSellerScreen(),
    'OtpScreen': () => const OtpScreen(phone: '+91 1234567890'),
    'Step01LocationScreen': () => const Step01LocationScreen(),
    'Step02SellerTypeScreen': () => const Step02SellerTypeScreen(),
    'Step03BusinessDetailsScreen': () => const Step03BusinessDetailsScreen(),
    'VerifyDetaileScreen': () => const VerifyDetaileScreen(),
    'BankDetaileScreen': () => const BankDetaileScreen(),
    'PersonalDetailsScreen': () => const PersonalDetailsScreen(),
    'AddProductsScreen': () => const AddProductsScreen(),
    'WalletPage': () => const WalletPage(),
    'ProfileScreen': () => const ProfileScreen(),
    'ReviewRatingsPage': () => const ReviewRatingsPage(),
  };
  final landmarks = <String, String>{
    'WelcomeSellerScreen': 'Send OTP',
    'OtpScreen': 'Enter OTP',
    'Step01LocationScreen': 'Choose your location',
    'Step02SellerTypeScreen': 'What best',
    'Step03BusinessDetailsScreen': 'Tell us about',
    'VerifyDetaileScreen': 'Verify your',
    'BankDetaileScreen': 'Fill Your Bank Details',
    'PersonalDetailsScreen': 'Full Name',
    'AddProductsScreen': 'Add Products',
    'WalletPage': 'Wallet',
    'ProfileScreen': 'Withdrawal balance',
    'ReviewRatingsPage': 'Average rating',
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders without overflow at every size', (
      tester,
    ) async {
      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(home: entry.value()));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} at $size overflowed',
        );
        expect(
          find.text(landmarks[entry.key]!),
          findsOneWidget,
          reason: '${entry.key} landmark missing at $size',
        );
      }
    });
  }

  testWidgets('Profile artboard scales up on large screens', (tester) async {
    Future<double> headerLeft(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpAndSettle();
      return tester.getRect(find.text('Profile').first).left;
    }

    // ProfileShell's trimmed artboard is 412x924.
    final atDesign = await headerLeft(const Size(412, 924));
    final atLarge = await headerLeft(const Size(800, 1280));

    // 800x1280 is height-bound: scale = 1280/924 ~= 1.385, so the header
    // sits further right than at the design size (proof of upscale).
    expect(atDesign, closeTo(68, 1));
    expect(atLarge, greaterThan(atDesign + 100));
  });

  testWidgets('artboard scale is capped at 1.5x on huge screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    // scale = min(2000/412, 3000/924, 1.5) = 1.5 -> artboard 618x1386,
    // centered horizontally at x = (2000-618)/2 = 691; header at artboard
    // rel x68 -> 691 + 68*1.5 = 793.
    final header = tester.getRect(find.text('Profile').first);
    expect(header.left, closeTo(793, 2));
    expect(header.top, closeTo(28 * 1.5, 2));
  });

  testWidgets('Add Products nav scales with the scrollable artboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: AddProductsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Content scale = min(1024/412, 1.5) = 1.5 -> nav box is 88*1.5 tall.
    final nav = tester.getRect(find.byType(BottomNavBar));
    expect(nav.height, closeTo(BottomNavBar.barHeight * 1.5, 1));
  });
}
