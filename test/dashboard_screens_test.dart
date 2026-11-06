import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/product_store.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/add_products_screen.dart';
import 'package:seller_app/screens/bank_details_screen.dart';
import 'package:seller_app/screens/business_farm_screen.dart';
import 'package:seller_app/screens/help_support_screen.dart';
import 'package:seller_app/screens/my_orders_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';
import 'package:seller_app/screens/order_privew.dart';
import 'package:seller_app/screens/personal_details_screen.dart';
import 'package:seller_app/screens/product_details_screen.dart';
import 'package:seller_app/screens/profile_app.dart';
import 'package:seller_app/screens/profile_business.dart';
import 'package:seller_app/screens/profile_screen.dart';
import 'package:seller_app/screens/report_problem_screen.dart';
import 'package:seller_app/screens/review_ratings_page.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/settings_screen.dart';
import 'package:seller_app/screens/verification_kyc_screen.dart';
import 'package:seller_app/screens/wallet_page.dart';
import 'package:seller_app/theme/app_colors.dart';
import 'package:seller_app/widgets/bottom_nav_bar.dart';
import 'package:seller_app/widgets/page_header.dart';
import 'package:seller_app/widgets/profile_shell.dart';

/// Pumps [widget] on the 412x924 artboard the profile design was drawn for
/// (Zeplin 980 minus the 56px top-padding trim).
Future<void> pumpProfile(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(412, 924);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: widget));
  await tester.pumpAndSettle();
}

/// Pumps the Add Products screen on a 412x917 phone viewport.
Future<void> pumpAddProducts(
  WidgetTester tester, {
  ProductPhotoPicker? photoPicker,
  ProductSaver? productSaver,
}) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AddProductsScreen(
        photoPicker: photoPicker,
        productSaver:
            productSaver ??
            (ProductDraft draft, List<ProductPhoto> photos) async {
              return ProductStore.instance.addProduct(
                name: draft.name,
                category: draft.category,
                price: draft.price,
                unit: draft.unit,
                quantity: draft.quantity,
                description: draft.description,
                status: draft.status,
                photos: photos,
              );
            },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _photoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6Q'
  'AAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhX'
  'Y/jPwPAfAAUAAf+mXJtdAAAAAElFTkSuQmCC',
);

void main() {
  setUp(() {
    SellerProfileStore.instance.reset();
    PersonalDetailsScreen.debugProfileSaver = ({
      required String name,
      required String mobile,
      required String sellerType,
      required String businessName,
      required String businessLocation,
      required String businessAddress,
    }) async => '9df39d4b-5d7a-457e-80a9-8f40dd0807e9';
  });

  tearDown(() => PersonalDetailsScreen.debugProfileSaver = null);

  group('ProfileScreen (Account, Zeplin 151)', () {
    testWidgets('renders the Account content', (tester) async {
      await pumpProfile(tester, const ProfileScreen());

      expect(find.text('Withdrawal balance'), findsOneWidget);
      expect(find.text('₹12,480'), findsOneWidget);
      expect(find.text('₹23,480 earned from 12 orders'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      // "This month" appears in the pill and the stats card.
      expect(find.text('This month'), findsNWidgets(2));
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Farmer, Salem, Tamil Nadu'), findsOneWidget);
      expect(find.text('Verfiled Seller'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      // "Orders" appears in the stats card and the nav label.
      expect(find.text('Orders'), findsNWidgets(2));
      expect(find.text('₹2,480'), findsOneWidget);
      expect(find.text('4.8 ★'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      // Tab bar.
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('App'), findsOneWidget);
      // Account list rows.
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Name, phone, email'), findsOneWidget);
      expect(find.text('Business & Farm'), findsOneWidget);
      expect(
        find.text('Farm details, location, pickup & delivery'),
        findsOneWidget,
      );
      expect(find.text('Verification (KYC)'), findsOneWidget);
      expect(find.text('Aadhaar, PAN, farm proof'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('SBI •••• 3421'), findsOneWidget);
      // Bottom nav ("Orders" also appears in the stats card).
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Orders'), findsNWidgets(2));
      // Header title + nav label (Zeplin 151 has both).
      expect(find.text('Profile'), findsNWidgets(2));
    });

    testWidgets('geometry matches the design', (tester) async {
      await pumpProfile(tester, const ProfileScreen());

      final origin = tester.getTopLeft(find.byType(MaterialApp));
      Rect rectOf(Finder finder) =>
          tester.getRect(finder).translate(-origin.dx, -origin.dy);

      // Balance card: x 22..390, y 65..315 (design 121..371, top trim -56).
      final balance = rectOf(find.text('Withdrawal balance').hitTestable());
      expect(balance.left, closeTo(48, 1));

      final withdraw = rectOf(find.text('Withdraw'));
      // Label is vertically centered inside the y 255..292 button.
      expect(withdraw.top, closeTo(255 + 11, 3));

      // Seller card top at y 336 (design 392, -56).
      final seller = rectOf(find.text('Ramesh Kumar'));
      expect(seller.top, closeTo(336 + 22, 2));

      // Tab bar top at y 502 (design 558, -56).
      final accountTab = rectOf(find.text('Account'));
      expect(accountTab.top, closeTo(502 + 12, 3));

      // List card top at y 560 (design 616, -56).
      final personal = rectOf(find.text('Personal Details'));
      expect(personal.top, closeTo(560 + 14, 4));

      // Bottom nav present.
      expect(find.byType(BottomNavBar), findsOneWidget);
      expect(find.byType(ProfileShell), findsOneWidget);
    });

    testWidgets('header back opens the home page', (tester) async {
      await pumpProfile(tester, const ProfileScreen());

      await tester.tap(find.byKey(PageHeader.backKey));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(SellerHomeScreen), findsOneWidget);
    });

    testWidgets('Business tab pushes the Business screen', (tester) async {
      await pumpProfile(tester, const ProfileScreen());

      await tester.tap(find.text('Business'));
      await tester.pumpAndSettle();

      expect(find.text('Wallet & Transactions'), findsOneWidget);
      expect(find.text('Balance, withdrawals'), findsOneWidget);
      expect(find.text('Review & Ratings'), findsOneWidget);
      expect(find.text('125 reviews'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      // Account list is gone.
      expect(find.text('Personal Details'), findsNothing);
    });

    testWidgets('Personal Details row opens PersonalDetailsScreen', (
      tester,
    ) async {
      await pumpProfile(tester, const ProfileScreen());

      await tester.tap(find.text('Personal Details'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsWidgets);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('(optional)'), findsOneWidget);
      expect(find.text('Seller Type'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('Trader'), findsOneWidget);
      expect(find.text('FPO / Group'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('saving Personal Details updates the Profile seller card', (
      tester,
    ) async {
      await pumpProfile(tester, const ProfileScreen());

      await tester.tap(find.text('Personal Details'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('personal-name-field')),
        'Sita Devi',
      );
      await tester.enterText(
        find.byKey(const ValueKey('personal-mobile-field')),
        '9876543210',
      );
      await tester.tap(find.byKey(const ValueKey('seller-type-trader')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save-personal-details')));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Sita Devi'), findsOneWidget);
      expect(find.text('SD'), findsOneWidget);
      expect(find.text('Trader, Salem, Tamil Nadu'), findsOneWidget);
    });

    testWidgets('Business & Farm, Verification and Bank rows navigate', (
      tester,
    ) async {
      // All three profile screens share the PageHeader back circle.
      final back = find.byKey(PageHeader.backKey);

      // Business & Farm -> BusinessFarmScreen.
      await pumpProfile(tester, const ProfileScreen());
      await tester.tap(find.text('Business & Farm'));
      await tester.pumpAndSettle();
      expect(find.byType(BusinessFarmScreen), findsOneWidget);
      expect(find.text('Kumar Organic Farm'), findsWidgets);
      expect(find.text('Farm / Business Name'), findsOneWidget);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(BusinessFarmScreen), findsNothing);

      // Verification (KYC) -> VerificationKycScreen.
      await tester.tap(find.text('Verification (KYC)'));
      await tester.pumpAndSettle();
      expect(find.byType(VerificationKycScreen), findsOneWidget);
      expect(find.text('Verified Seller'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(VerificationKycScreen), findsNothing);

      // Bank Details -> BankDetailsScreen (the profile 162 screen, distinct
      // from the onboarding bank_detaile flow).
      await tester.tap(find.text('Bank Details'));
      await tester.pumpAndSettle();
      expect(find.byType(BankDetailsScreen), findsOneWidget);
      expect(find.text('State Bank of India'), findsOneWidget);
      expect(find.text('Account holder'), findsOneWidget);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(BankDetailsScreen), findsNothing);

      // All three came back to the profile tab.
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);
    });

    testWidgets('FAB opens AddProductsScreen', (tester) async {
      await pumpProfile(tester, const ProfileScreen());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Add Products'), findsOneWidget);
      expect(find.text('Product Photos'), findsOneWidget);
    });

    testWidgets('bottom nav tabs are fully wired', (tester) async {
      Finder navText(String label) => find.descendant(
        of: find.byType(BottomNavBar),
        matching: find.text(label),
      );

      await pumpProfile(tester, const ProfileScreen());
      await tester.tap(navText('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(SellerHomeScreen), findsOneWidget);

      await pumpProfile(tester, const ProfileScreen());
      await tester.tap(navText('Products'));
      await tester.pumpAndSettle();
      expect(find.byType(MyProductsScreen), findsOneWidget);

      await pumpProfile(tester, const ProfileScreen());
      await tester.tap(navText('Orders'));
      await tester.pumpAndSettle();
      expect(find.byType(MyOrdersScreen), findsOneWidget);
    });

    testWidgets('layout scales down instead of overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Withdrawal balance'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);

      // Nothing may stick out past the viewport on the right.
      final origin = tester.getTopLeft(find.byType(MaterialApp));
      for (final finder in [
        find.text('This month').first,
        find.text('Verfiled Seller'),
        find.text('Rating'),
        find.text('Profile').first,
      ]) {
        final right = tester.getRect(finder).right - origin.dx;
        expect(right, lessThanOrEqualTo(360));
      }
    });
  });

  group('ProfileBusinessScreen (Zeplin 152)', () {
    testWidgets('renders the Business content', (tester) async {
      await pumpProfile(tester, const ProfileBusinessScreen());

      expect(find.text('Wallet & Transactions'), findsOneWidget);
      expect(find.text('Balance, withdrawals'), findsOneWidget);
      expect(find.text('Review & Ratings'), findsOneWidget);
      expect(find.text('125 reviews'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      // Account rows are not shown.
      expect(find.text('Personal Details'), findsNothing);
      expect(find.text('Bank Details'), findsNothing);
      // Shared chrome still present.
      expect(find.text('Withdrawal balance'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
    });

    testWidgets('Account tab returns to the Account screen', (tester) async {
      await pumpProfile(tester, const ProfileBusinessScreen());

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Wallet & Transactions'), findsNothing);
    });
  });

  group('ProfileAppScreen (Zeplin 153)', () {
    testWidgets('renders the App content', (tester) async {
      await pumpProfile(tester, const ProfileAppScreen());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language, notifications'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      // Log out lives in Settings, not on the App tab.
      expect(find.text('Log out'), findsNothing);
      // Assert no Account/Business rows leak in.
      expect(find.text('Personal Details'), findsNothing);
      expect(find.text('Wallet & Transactions'), findsNothing);
      // Chevrons on Settings/Help.
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
      // Shared chrome + App tab selected.
      expect(find.text('Withdrawal balance'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('App'), findsOneWidget);
      expect(find.text('Profile'), findsNWidgets(2));
      expect(find.byType(ProfileShell), findsOneWidget);
    });

    testWidgets('geometry matches the design', (tester) async {
      await pumpProfile(tester, const ProfileAppScreen());

      final origin = tester.getTopLeft(find.byType(MaterialApp));
      Rect rectOf(Finder finder) =>
          tester.getRect(finder).translate(-origin.dx, -origin.dy);

      // Header: back circle (24,24) d26, title Text top 28.
      final header = rectOf(find.text('Profile').first);
      expect(header.left, closeTo(92, 1));
      expect(header.top, closeTo(28, 1));

      // List card top at y560; Settings title Text at card-rel (68,23).
      final settings = rectOf(find.text('Settings'));
      expect(settings.left, closeTo(24 + 68, 1));
      expect(settings.top, closeTo(560 + 23, 3));

      // Help title at card-rel (68,89).
      final help = rectOf(find.text('Help & Support'));
      expect(help.top, closeTo(560 + 89, 3));

      // Subtitle below Settings.
      final sub = rectOf(find.text('Language, notifications'));
      expect(sub.top, closeTo(560 + 40, 3));
    });

    testWidgets('Account tab returns to the Account screen', (tester) async {
      await pumpProfile(tester, const ProfileAppScreen());

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('Business tab opens the Business screen', (tester) async {
      await pumpProfile(tester, const ProfileAppScreen());

      await tester.tap(find.text('Business'));
      await tester.pumpAndSettle();

      expect(find.text('Wallet & Transactions'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('App tab opens from the Account screen', (tester) async {
      await pumpProfile(tester, const ProfileScreen());

      await tester.tap(find.text('App'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Personal Details'), findsNothing);
    });

    testWidgets('Settings row opens the settings page', (tester) async {
      await pumpProfile(tester, const ProfileAppScreen());

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Preferences'), findsWidgets);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);

      // Header back returns to the profile App tab.
      await tester.tap(find.byKey(PageHeader.backKey));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Log out'), findsNothing);
    });

    testWidgets('Help row opens the Help & Support screen', (tester) async {
      await pumpProfile(tester, const ProfileAppScreen());

      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      expect(find.byType(HelpSupportScreen), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('How can we help?'), findsOneWidget);

      await tester.tap(find.text('Report a problem'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportProblemScreen), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);

      await tester.tap(
        find.image(const AssetImage('assets/order/ic_back.png')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HelpSupportScreen), findsOneWidget);

      await tester.tap(
        find.image(const AssetImage('assets/order/ic_back.png')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HelpSupportScreen), findsNothing);
      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('Help & Suppport row opens the help screen', (tester) async {
      await pumpProfile(tester, const ProfileAppScreen());

      await tester.tap(find.byKey(const Key('profile-help')));
      await tester.pumpAndSettle();

      expect(find.byType(HelpSupportScreen), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
    });
  });

  group('WalletPage (Zeplin 156)', () {
    Future<void> pumpWallet(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: WalletPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('renders the Wallet content', (tester) async {
      await pumpWallet(tester);

      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Available balance'), findsOneWidget);
      expect(find.text('₹12,480'), findsOneWidget);
      expect(
        find.text('₹3,480 more coming from orders in prog.'),
        findsOneWidget,
      );
      // Button label + transactions card title.
      expect(find.text('Withdraw'), findsOneWidget);
      expect(find.text('Transactions'), findsNWidgets(2));
      // Filter chips.
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Credited'), findsOneWidget);
      expect(find.text('Withdrawn'), findsOneWidget);
      // Transaction rows (design keeps the double spaces).
      expect(find.text('Order #NX4852  Akash Stores'), findsOneWidget);
      expect(find.text('12 Mar 2024'), findsOneWidget);
      expect(find.text('+₹12,480'), findsOneWidget);
      expect(find.text('Withdrawal to SBI  2341'), findsOneWidget);
      expect(find.text('10 Mar 2024'), findsOneWidget);
      expect(find.text('-₹5,000'), findsOneWidget);
      expect(find.text('Order #NX4579  Nilgiri'), findsOneWidget);
      expect(find.text('9 Mar 2024'), findsOneWidget);
      expect(find.text('+₹3,500'), findsNWidgets(2));
      expect(find.text('Order #NX4578  Daily Store'), findsOneWidget);
      expect(find.text('8 Mar 2024'), findsOneWidget);
      // Standalone page — no bottom nav / profile chrome.
      expect(find.byType(BottomNavBar), findsNothing);
      expect(find.byType(ProfileShell), findsNothing);
    });

    testWidgets('geometry matches the design', (tester) async {
      await pumpWallet(tester);

      final origin = tester.getTopLeft(find.byType(MaterialApp));
      Rect rectOf(Finder finder) =>
          tester.getRect(finder).translate(-origin.dx, -origin.dy);

      // Header title at (68, 28).
      final header = rectOf(find.text('Wallet'));
      expect(header.left, closeTo(68, 1));
      expect(header.top, closeTo(28, 1));

      // Balance card at (24, 65); label rel (21, 20), amount rel (22, 44).
      final label = rectOf(find.text('Available balance'));
      expect(label.left, closeTo(22 + 21, 1));
      expect(label.top, closeTo(65 + 20, 2));
      final amount = rectOf(find.text('\u20B912,480'));
      expect(amount.left, closeTo(22 + 22, 1));
      expect(amount.top, closeTo(65 + 44, 2));
      final sub = rectOf(
        find.text('\u20B93,480 more coming from orders in prog.'),
      );
      expect(sub.top, closeTo(65 + 95, 2));

      // "All" chip pill at (24, 271).
      final chip = rectOf(find.text('All'));
      expect(chip.left, greaterThanOrEqualTo(24));
      expect(chip.top, greaterThanOrEqualTo(271));
      expect(chip.top, lessThanOrEqualTo(271 + 31));

      // Transactions card at (24, 320); title rel (22, 17).
      final cardTitle = rectOf(find.text('Transactions').last);
      expect(cardTitle.left, closeTo(22 + 22, 1));
      expect(cardTitle.top, closeTo(320 + 17, 2));

      // Row 1: tile top rel 55, title rel 58.5, date rel 74.5, amount rel 70
      // - all card-rel, card origin (24, 320).
      final rowTitle = rectOf(find.text('Order #NX4852  Akash Stores'));
      expect(rowTitle.left, closeTo(22 + 67, 1));
      expect(rowTitle.top, closeTo(320 + 58.5, 2));
      final date = rectOf(find.text('12 Mar 2024'));
      expect(date.top, closeTo(320 + 74.5, 2));
      final credit = rectOf(find.text('+\u20B912,480'));
      expect(credit.right, closeTo(22 + 364 - 21, 1.5));
      expect(credit.top, closeTo(320 + 70, 2));

      // Row 4 sits 174 lower (3 pitches).
      final row4 = rectOf(find.text('Order #NX4578  Daily Store'));
      expect(row4.top, closeTo(320 + 58.5 + 174, 2));
    });

    testWidgets('Business Wallet row opens the Wallet page and back pops', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ProfileBusinessScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wallet & Transactions'));
      await tester.pumpAndSettle();
      expect(find.byType(WalletPage), findsOneWidget);
      expect(find.text('Available balance'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();
      expect(find.byType(WalletPage), findsNothing);
      expect(find.text('Wallet & Transactions'), findsOneWidget);
    });

    testWidgets('filter chips toggle the transactions list', (tester) async {
      await pumpWallet(tester);

      // All (default): three credits + one withdrawal.
      expect(find.text('Withdrawal to SBI  2341'), findsOneWidget);
      expect(find.text('Order #NX4578  Daily Store'), findsOneWidget);

      // Credited: hides the withdrawal, keeps the credits.
      await tester.tap(find.text('Credited'));
      await tester.pumpAndSettle();
      expect(find.text('Withdrawal to SBI  2341'), findsNothing);
      expect(find.text('-₹5,000'), findsNothing);
      expect(find.text('Order #NX4852  Akash Stores'), findsOneWidget);
      expect(find.text('Order #NX4579  Nilgiri'), findsOneWidget);
      expect(find.text('Order #NX4578  Daily Store'), findsOneWidget);
      // Selected chip flips to the lime label.
      final credited = tester.widget<Text>(find.text('Credited'));
      expect(credited.style?.color, AppColors.chipActiveText);

      // Withdrawn: shows only the withdrawal.
      await tester.tap(find.text('Withdrawn'));
      await tester.pumpAndSettle();
      expect(find.text('Withdrawal to SBI  2341'), findsOneWidget);
      expect(find.text('-₹5,000'), findsOneWidget);
      expect(find.text('Order #NX4852  Akash Stores'), findsNothing);
      expect(find.text('Order #NX4579  Nilgiri'), findsNothing);
      expect(find.text('Order #NX4578  Daily Store'), findsNothing);

      // Back to All: everything returns.
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Withdrawal to SBI  2341'), findsOneWidget);
      expect(find.text('Order #NX4852  Akash Stores'), findsOneWidget);
      expect(find.text('Order #NX4579  Nilgiri'), findsOneWidget);
      expect(find.text('Order #NX4578  Daily Store'), findsOneWidget);
    });

    testWidgets('layout scales down instead of overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: WalletPage()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Available balance'), findsOneWidget);
      expect(find.text('Order #NX4852  Akash Stores'), findsOneWidget);

      // Nothing may stick out past the viewport on the right.
      final origin = tester.getTopLeft(find.byType(MaterialApp));
      for (final finder in [
        find.text('₹12,480'),
        find.text('Withdraw'),
        find.text('Withdrawn'),
        find.text('+₹12,480'),
      ]) {
        final right = tester.getRect(finder).right - origin.dx;
        expect(right, lessThanOrEqualTo(360));
      }
    });
  });

  group('ReviewRatingsPage', () {
    Future<void> pumpReviews(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ReviewRatingsPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('renders the Review & Ratings content', (tester) async {
      await pumpReviews(tester);

      expect(find.text('Review & Ratings'), findsOneWidget);
      expect(find.text('Average rating'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('125 reviews'), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
      // Reviewer rows.
      expect(find.text('Anees'), findsOneWidget);
      expect(find.text('14 Mar 2024'), findsOneWidget);
      expect(
        find.text(
          'Fresh tomatoes every time and quick delivery. Excellent quality!',
        ),
        findsOneWidget,
      );
      expect(find.text('Jhon'), findsOneWidget);
      expect(find.text('Anjith'), findsOneWidget);
      expect(find.text('Senthil'), findsOneWidget);
      // Standalone page — no bottom nav / profile chrome.
      expect(find.byType(BottomNavBar), findsNothing);
      expect(find.byType(ProfileShell), findsNothing);
    });

    testWidgets('geometry matches the layout', (tester) async {
      await pumpReviews(tester);

      final origin = tester.getTopLeft(find.byType(MaterialApp));
      Rect rectOf(Finder finder) =>
          tester.getRect(finder).translate(-origin.dx, -origin.dy);

      // Header title at (68, 28).
      final header = rectOf(find.text('Review & Ratings'));
      expect(header.left, closeTo(68, 1));
      expect(header.top, closeTo(28, 1));

      // Summary card at (24, 65); label rel (21, 20), amount rel (22, 44).
      final label = rectOf(find.text('Average rating'));
      expect(label.left, closeTo(22 + 21, 1));
      expect(label.top, closeTo(65 + 20, 2));
      final amount = rectOf(find.text('4.8'));
      expect(amount.left, closeTo(22 + 22, 1));
      expect(amount.top, closeTo(65 + 44, 2));
      final sub = rectOf(find.text('125 reviews'));
      expect(sub.top, closeTo(65 + 100, 2));

      // Reviews card title rel (22, 17); card origin (24, 265).
      final cardTitle = rectOf(find.text('Reviews'));
      expect(cardTitle.left, closeTo(22 + 22, 1));
      expect(cardTitle.top, closeTo(265 + 17, 2));

      // Row 1 name rel (70, 10), row 4 sits 336 lower (3 pitches of 112).
      final row1 = rectOf(find.text('Anees'));
      expect(row1.left, closeTo(22 + 70, 1));
      expect(row1.top, closeTo(265 + 55 + 10, 2));
      final row4 = rectOf(find.text('Senthil'));
      expect(row4.top, closeTo(265 + 55 + 10 + 336, 2));
    });

    testWidgets('Business Review & Ratings row opens the page and back pops', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ProfileBusinessScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review & Ratings'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewRatingsPage), findsOneWidget);
      expect(find.text('Average rating'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();
      expect(find.byType(ReviewRatingsPage), findsNothing);
      expect(find.text('Wallet & Transactions'), findsOneWidget);
    });

    testWidgets('layout scales down instead of overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ReviewRatingsPage()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Average rating'), findsOneWidget);
      expect(find.text('Anees'), findsOneWidget);

      // Nothing may stick out past the viewport on the right.
      final origin = tester.getTopLeft(find.byType(MaterialApp));
      for (final finder in [
        find.text('Review & Ratings'),
        find.text('4.8'),
        find.text('Senthil'),
        find.text('14 Mar 2024'),
      ]) {
        final right = tester.getRect(finder).right - origin.dx;
        expect(right, lessThanOrEqualTo(360));
      }
    });
  });

  group('AddProductsScreen (Zeplin 124)', () {
    setUp(ProductStore.instance.clear);

    testWidgets('renders all sections', (tester) async {
      await pumpAddProducts(tester);

      expect(find.text('Add Products'), findsOneWidget);
      expect(find.text('Step1'), findsOneWidget);
      expect(find.text('of 5 • Product Photos'), findsOneWidget);
      expect(find.text('Product Photos'), findsOneWidget);
      expect(find.text('Add clear photos of your product'), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-tomato')), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('Tell us about your product'), findsWidgets);
      expect(find.text('Product Name'), findsOneWidget);
      expect(find.text('e.g Fresh Tomates'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('Fruits'), findsOneWidget);
      expect(find.text('Grains & pulses'), findsOneWidget);
      expect(find.text('Pricing & Quantity'), findsOneWidget);
      expect(find.text('et your price and available quantity'), findsOneWidget);
      expect(find.text('Price per unit'), findsOneWidget);
      expect(find.text('Unit'), findsWidgets);
      expect(find.text('e.g. 48'), findsOneWidget);
      expect(find.text('Available Quantity'), findsOneWidget);
      expect(find.text('e.g. 50 kg'), findsOneWidget);
      // Description + status share the design's typo title.
      expect(find.text('Product Descrption'), findsNWidgets(2));
      expect(
        find.text('Help buyers know more about your product.'),
        findsNWidgets(2),
      );
      expect(find.text('0/500'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      // Bottom nav is pinned (no FAB tab selected).
      expect(find.byType(BottomNavBar), findsOneWidget);
    });

    testWidgets('Continue adds the product with the entered details', (
      tester,
    ) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);

      await tester.enterText(
        find.byKey(const ValueKey('product-name')),
        'Mango',
      );
      await tester.enterText(
        find.byKey(const ValueKey('product-price')),
        '120',
      );
      await tester.tap(find.text('Fruits'));
      await tester.pump();

      await tester.dragUntilVisible(
        find.byKey(const ValueKey('add-photo')),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Draft'),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Draft'));
      await tester.pump();

      await tester.dragUntilVisible(
        find.byKey(const ValueKey('add-product-continue')),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-product-continue')));
      await tester.pumpAndSettle();

      final product = ProductStore.instance.products.single;
      expect(product.name, 'Mango');
      expect(product.category, 'Fruits');
      expect(product.price, 120);
      expect(product.unit, 'kg');
      expect(product.quantity, 50);
      expect(product.status, ProductStatus.draft);
      expect(product.photos, hasLength(1));
    });

    testWidgets('Continue includes the selected photos', (tester) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('product-name')),
        'Tomato',
      );
      await tester.enterText(find.byKey(const ValueKey('product-price')), '48');
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('add-product-continue')),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-product-continue')));
      await tester.pumpAndSettle();

      final product = ProductStore.instance.products.single;
      expect(product.photos, hasLength(1));
      expect(product.photos.single.bytes, same(_photoBytes));
    });

    testWidgets('Continue requires a product name', (tester) async {
      await pumpAddProducts(tester);

      await tester.dragUntilVisible(
        find.byKey(const ValueKey('add-product-continue')),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-product-continue')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a product name.'), findsOneWidget);
      expect(ProductStore.instance.products, isEmpty);
    });

    testWidgets('Continue requires a valid price', (tester) async {
      await pumpAddProducts(tester);

      await tester.enterText(
        find.byKey(const ValueKey('product-name')),
        'Beans',
      );
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('add-product-continue')),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-product-continue')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid price.'), findsOneWidget);
      expect(ProductStore.instance.products, isEmpty);
    });

    testWidgets('keeps the original photo strip geometry', (tester) async {
      await pumpAddProducts(tester);

      final tomato = tester.getRect(find.byKey(const ValueKey('photo-tomato')));
      expect(tomato.left, closeTo(0, 0.5));
      expect(tomato.top, closeTo(219, 0.5));
      expect(tomato.size, const Size(127, 127));

      final add = tester.getRect(find.byKey(const ValueKey('add-photo')));
      expect(add.left, closeTo(112, 0.5));
      expect(add.top, closeTo(219, 0.5));
      expect(add.size, const Size(188, 127));

      final next = tester.getRect(find.byKey(const ValueKey('photo-next')));
      expect(next.left, closeTo(356, 0.5));
      expect(next.top, closeTo(269, 0.5));
      expect(next.size, const Size(24, 24));

      final dot = tester.getRect(find.byKey(const ValueKey('photo-dot-0')));
      expect(dot.top, closeTo(362, 0.5));
      expect(dot.size, const Size(13, 7));
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(ValueKey('photo-dot-$i')), findsOneWidget);
      }
      expect(find.text('0/5'), findsOneWidget);
    });

    testWidgets('adds a photo in place of the tomato', (tester) async {
      var picks = 0;
      Future<ProductPhoto?> picker() async {
        picks++;
        return ProductPhoto(bytes: _photoBytes);
      }

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();

      expect(picks, 1);
      expect(find.byKey(const ValueKey('photo-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('product-photo-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('add-photo')), findsOneWidget);
      expect(find.text('1/5'), findsOneWidget);

      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const ValueKey('product-photo-0')),
          matching: find.byType(Image),
        ),
      );
      expect(image.image, isA<MemoryImage>());
    });

    testWidgets('puts the remove button at the active image top-right', (
      tester,
    ) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();

      final photo = tester.getRect(
        find.byKey(const ValueKey('product-photo-0')),
      );
      final remove = tester.getRect(find.byKey(const ValueKey('photo-remove')));
      expect(remove.size, const Size(20, 20));
      expect(remove.top, closeTo(photo.top + 4, 0.5));
      expect(remove.right, closeTo(photo.right - 4, 0.5));
    });

    testWidgets('right arrow reveals the add photo box', (tester) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(const ValueKey('product-photo-0'))).center.dx,
        closeTo(206, 0.5),
      );
      expect(find.byKey(const ValueKey('photo-remove')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();

      final add = tester.getRect(find.byKey(const ValueKey('add-photo')));
      expect(add.center.dx, closeTo(206, 0.5));
      expect(add.size, const Size(188, 127));
      expect(find.text('Add photo'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-remove')), findsNothing);
    });

    testWidgets('updates the counter and active dot across transitions', (
      tester,
    ) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      Color dotColor(int index) {
        final dot = tester.widget<Container>(
          find.byKey(ValueKey('photo-dot-$index')),
        );
        return (dot.decoration! as BoxDecoration).color!;
      }

      await pumpAddProducts(tester, photoPicker: picker);
      expect(find.text('0/5'), findsOneWidget);
      expect(dotColor(0), AppColors.darkGreenInk);
      expect(dotColor(1), AppColors.dotInactive);

      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsOneWidget);
      expect(dotColor(0), AppColors.darkGreenInk);

      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsOneWidget);
      expect(dotColor(1), AppColors.darkGreenInk);

      await tester.tap(find.byKey(const ValueKey('photo-previous')));
      await tester.pumpAndSettle();
      expect(dotColor(0), AppColors.darkGreenInk);

      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      expect(find.text('2/5'), findsOneWidget);
      expect(dotColor(1), AppColors.darkGreenInk);

      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();
      expect(find.text('2/5'), findsOneWidget);
      expect(dotColor(2), AppColors.darkGreenInk);
    });

    testWidgets('previews an uploaded photo from the carousel', (tester) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('product-photo-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo-preview-image')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('photo-preview-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo-preview-image')), findsNothing);
      expect(find.byKey(const ValueKey('product-photo-0')), findsOneWidget);
    });

    testWidgets('shows a loading state while the picker is open', (
      tester,
    ) async {
      final completer = Completer<ProductPhoto?>();
      await pumpAddProducts(tester, photoPicker: () => completer.future);

      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pump();
      expect(find.byKey(const ValueKey('photo-loading')), findsOneWidget);

      completer.complete(ProductPhoto(bytes: _photoBytes));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo-loading')), findsNothing);
      expect(find.byKey(const ValueKey('product-photo-0')), findsOneWidget);
      expect(find.text('1/5'), findsOneWidget);
    });

    testWidgets('ignores rapid arrow taps during an animation', (tester) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-previous')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(const ValueKey('product-photo-1'))).center.dx,
        closeTo(206, 0.5),
      );
    });

    testWidgets('adds up to five photos and hides the add tile', (
      tester,
    ) async {
      var picks = 0;
      Future<ProductPhoto?> picker() async {
        picks++;
        return ProductPhoto(bytes: _photoBytes);
      }

      await pumpAddProducts(tester, photoPicker: picker);
      for (var i = 0; i < AddProductsScreen.maxPhotos; i++) {
        await tester.tap(find.byKey(const ValueKey('add-photo')));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('product-photo-$i')), findsOneWidget);
        expect(find.text('${i + 1}/5'), findsOneWidget);

        if (i < AddProductsScreen.maxPhotos - 1) {
          await tester.tap(find.byKey(const ValueKey('photo-next')));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.byKey(const ValueKey('add-photo'))).center.dx,
            closeTo(206, 0.5),
          );
        }
      }

      expect(picks, AddProductsScreen.maxPhotos);
      expect(find.byKey(const ValueKey('photo-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('add-photo')), findsNothing);
      expect(find.text('Add photo'), findsNothing);
      expect(find.byKey(const ValueKey('product-photo-4')), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('photo-remove')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('product-photo-4')), findsNothing);
      expect(find.byKey(const ValueKey('add-photo')), findsOneWidget);
      expect(find.text('4/5'), findsOneWidget);
    });

    testWidgets('cancelling the gallery keeps the tomato', (tester) async {
      var picks = 0;
      Future<ProductPhoto?> picker() async {
        picks++;
        return null;
      }

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();

      expect(picks, 1);
      expect(find.byKey(const ValueKey('photo-tomato')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-photo-0')), findsNothing);
      expect(find.text('0/5'), findsOneWidget);
    });

    testWidgets('shows an error when the gallery picker fails', (tester) async {
      Future<ProductPhoto?> picker() async {
        throw Exception('gallery unavailable');
      }

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();

      expect(find.text('Could not open the photo picker.'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-tomato')), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);
    });

    testWidgets('animates between centered photos', (tester) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();

      const cardCenterX = 206.0;
      expect(
        tester.getRect(find.byKey(const ValueKey('product-photo-1'))).center.dx,
        closeTo(cardCenterX, 0.5),
      );

      final before = tester
          .getRect(find.byKey(const ValueKey('product-photo-0')))
          .center
          .dx;
      await tester.tap(find.byKey(const ValueKey('photo-previous')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester
          .getRect(find.byKey(const ValueKey('product-photo-0')))
          .center
          .dx;
      expect(mid, greaterThan(before));

      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('product-photo-0'))).center.dx,
        closeTo(cardCenterX, 0.5),
      );

      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('product-photo-1'))).center.dx,
        closeTo(cardCenterX, 0.5),
      );

      await tester.flingFrom(
        const Offset(200, 280),
        const Offset(140, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('product-photo-0'))).center.dx,
        closeTo(cardCenterX, 0.5),
      );
    });

    testWidgets('centers the active photo with side slivers', (tester) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-previous')));
      await tester.pumpAndSettle();

      final active = tester.getRect(
        find.byKey(const ValueKey('product-photo-1')),
      );
      final previous = tester.getRect(
        find.byKey(const ValueKey('product-photo-0')),
      );
      final next = tester.getRect(
        find.byKey(const ValueKey('product-photo-2')),
      );

      expect(active.center.dx, closeTo(206, 0.5));
      expect(active.size, const Size(188, 127));
      expect(previous.right, lessThan(active.left));
      expect(next.left, greaterThan(active.right));
    });

    testWidgets('removes a photo and restores the tomato', (tester) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo-tomato')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('photo-remove')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('photo-tomato')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-photo-0')), findsNothing);
      expect(find.text('0/5'), findsOneWidget);
    });

    testWidgets('keeps carousel indices correct after a middle removal', (
      tester,
    ) async {
      Future<ProductPhoto?> picker() async => ProductPhoto(bytes: _photoBytes);

      await pumpAddProducts(tester, photoPicker: picker);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('add-photo')));
        await tester.pumpAndSettle();
        if (i < 2) {
          await tester.tap(find.byKey(const ValueKey('photo-next')));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('3/5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('photo-previous')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-remove')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('product-photo-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-photo-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('product-photo-2')), findsNothing);
      expect(find.text('2/5'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const ValueKey('product-photo-1'))).center.dx,
        closeTo(206, 0.5),
      );
    });

    testWidgets('bottom nav tabs all fit inside the 412-wide artboard', (
      tester,
    ) async {
      await pumpAddProducts(tester);

      // The nav is pinned inside the artboard, so every tab label must sit
      // within x[0, 412]. Regression: the old fixed-left layout pushed the
      // Profile box to x422, clipping its label off the right edge.
      for (final label in ['Home', 'Products', 'Orders', 'Profile']) {
        final rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$label left');
        expect(
          rect.right,
          lessThanOrEqualTo(412 + 0.5),
          reason: '$label right ${rect.right}',
        );
      }
    });

    testWidgets('bottom nav opens the Home and Products tabs', (tester) async {
      Finder navText(String label) => find.descendant(
        of: find.byType(BottomNavBar),
        matching: find.text(label),
      );

      await pumpAddProducts(tester);
      await tester.tap(navText('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(SellerHomeScreen), findsOneWidget);

      await pumpAddProducts(tester);
      await tester.tap(navText('Products'));
      await tester.pumpAndSettle();
      expect(find.byType(MyProductsScreen), findsOneWidget);
    });

    testWidgets('quantity stepper increments and decrements', (tester) async {
      await pumpAddProducts(tester);

      // Stepper sits below the fold — scroll it into view.
      await tester.dragUntilVisible(
        find.byKey(const Key('qty-plus')),
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(find.text('e.g. 50 kg'), findsOneWidget);
      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pump();
      expect(find.text('51 kg'), findsOneWidget);
      await tester.tap(find.byKey(const Key('qty-minus')));
      await tester.pump();
      expect(find.text('50 kg'), findsOneWidget);
    });

    testWidgets('tapping the quantity display opens the kg input dialog', (
      tester,
    ) async {
      await pumpAddProducts(tester);
      await tester.dragUntilVisible(
        find.byKey(const Key('qty-display')),
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('qty-display')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qty-dialog')), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('qty-dialog-input')),
      );
      expect(field.controller?.text, '50');

      await tester.enterText(find.byKey(const Key('qty-dialog-input')), '137');
      await tester.tap(find.byKey(const Key('qty-dialog-set')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qty-dialog')), findsNothing);
      expect(find.text('137 kg'), findsOneWidget);
      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pump();
      expect(find.text('138 kg'), findsOneWidget);
    });

    testWidgets('category and status chips select', (tester) async {
      await pumpAddProducts(tester);

      await tester.tap(find.text('Fruits'));
      await tester.pump();

      // Selected chip text flips to lime.
      final fruits = tester.widget<Text>(find.text('Fruits'));
      expect(fruits.style?.color, AppColors.chipActiveText);

      // Draft sits below the fold — scroll it into view before tapping.
      await tester.dragUntilVisible(
        find.text('Draft'),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Draft'));
      await tester.pump();
      final draft = tester.widget<Text>(find.text('Draft'));
      expect(draft.style?.color, AppColors.chipActiveText);
    });

    testWidgets('description counts characters', (tester) async {
      await pumpAddProducts(tester);

      await tester.enterText(
        find.byType(TextField).last,
        'Fresh organic tomatoes',
      );
      await tester.pump();

      expect(find.text('22/500'), findsOneWidget);
    });

    testWidgets('back arrow opens the home page', (tester) async {
      // Push from a stub route to prove the header back is not a plain pop.
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductsScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductsScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();
      expect(find.byType(AddProductsScreen), findsNothing);
      expect(find.byType(SellerHomeScreen), findsOneWidget);
    });

    testWidgets('bottom nav FAB pops and Profile tab opens ProfileScreen', (
      tester,
    ) async {
      // Tall viewport fits the whole 1397-tall artboard, nav included.
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductsScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AddProductsScreen), findsOneWidget);

      // The nav FAB pops back to the stub home.
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavBar),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AddProductsScreen), findsNothing);

      // Profile tab pushes the Account profile screen.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('bottom nav stays fixed at the bottom while the form scrolls', (
      tester,
    ) async {
      // Phone viewport shorter than the 1397-tall artboard, so the form
      // actually scrolls under the fixed nav.
      tester.view.physicalSize = const Size(412, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: AddProductsScreen()));
      await tester.pumpAndSettle();

      Rect navRect() => tester.getRect(find.byType(BottomNavBar));
      final before = navRect();
      expect(before.bottom, closeTo(800, 1));

      // Scroll the form down by 400px.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Nav bottom/top/left unchanged: it did NOT scroll with the content.
      final after = navRect();
      expect(after.bottom, closeTo(800, 1));
      expect(after.top, closeTo(before.top, 1));
      expect(after.left, closeTo(before.left, 1));

      // The content scrolled: the header is now above the viewport.
      final header = tester.getRect(find.text('Add Products'));
      expect(header.top, lessThan(0));
    });

    testWidgets('Orders tab opens the My Orders page', (tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductsScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AddProductsScreen), findsOneWidget);
      expect(find.byType(MyOrdersScreen), findsNothing);

      // Orders tab (in the fixed nav) pushes the My Orders screen.
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(find.byType(MyOrdersScreen), findsOneWidget);
      expect(find.byType(AddProductsScreen), findsNothing);
    });

    testWidgets('layout scales down instead of overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: AddProductsScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add Products'), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-tomato')), findsOneWidget);

      // The 412-wide artboard scales to the 360 viewport (no horizontal
      // overflow exception above); the form stays scrollable vertically.
      final scroller = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final align = scroller.child as Align;
      final artboard = align.child as SizedBox;
      expect(artboard.width, closeTo(360, 0.5));
    });
  });

  group('OrderPrivewScreen (Fresh Tomatoes is live!, Zeplin 172)', () {
    testWidgets('Add another product opens the add product flow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: OrderPrivewScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductsScreen), findsNothing);

      await tester.tap(find.byKey(const Key('order-add-product')));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductsScreen), findsOneWidget);
      expect(find.text('Add Products'), findsOneWidget);
    });

    testWidgets('Preview product opens the product details page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 1515);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: OrderPrivewScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preview product'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailsScreen), findsOneWidget);
      expect(find.text('Go back to order'), findsOneWidget);
      expect(find.text('Fresh Tomatoes'), findsOneWidget);

      await tester.tap(find.text('Go back to order'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderPrivewScreen), findsOneWidget);
      expect(find.byType(ProductDetailsScreen), findsNothing);
    });

    testWidgets('renders at the measured 412x917 geometry', (tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: OrderPrivewScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFFAFBF3));

      // Floating back circle sits in the empty band above the hero.
      final back = tester.getRect(find.byKey(const Key('order-preview-back')));
      expect(back.left, closeTo(22, 0.6));
      expect(back.top, closeTo(56, 0.6));
      expect(back.size, const Size(26, 26));

      // Baked hero (card + shadow, baked title erased in the asset).
      final hero = tester.getRect(
        find.image(const AssetImage(OrderPrivewScreen.heroAsset)),
      );
      expect(hero.left, closeTo(0, 0.6));
      expect(hero.top, closeTo(103, 0.6));
      expect(hero.width, closeTo(412, 0.6));
      expect(hero.height, closeTo(332, 0.6));

      final title = tester.getRect(find.text('Fresh Tomatoes is live!'));
      expect(title.left, closeTo(0, 0.6));
      expect(title.top, closeTo(400.9, 0.6));

      final subtitle = tester.getRect(
        find.text('Buyers can noww see it and place orders.'),
      );
      expect(subtitle.top, closeTo(437.9, 0.6));

      final tile = tester.getRect(
        find.image(const AssetImage(OrderPrivewScreen.tileAsset)),
      );
      expect(tile.left, closeTo(40.5, 0.6));
      expect(tile.top, closeTo(491, 0.6));
      expect(tile.width, closeTo(75, 0.6));
      expect(tile.height, closeTo(74, 0.6));

      final cardTitle = tester.getRect(find.text('Fresh Tomatoes'));
      expect(cardTitle.left, closeTo(141.8, 0.6));
      expect(cardTitle.top, closeTo(496.6, 0.6));

      final category = tester.getRect(find.text('Vegetables'));
      expect(category.left, closeTo(141.7, 0.6));
      expect(category.top, closeTo(513.4, 0.6));

      final price = tester.getRect(find.text('\u20B948'));
      expect(price.left, closeTo(142, 0.6));
      expect(price.top, closeTo(539.9, 0.6));

      final availability = tester.getRect(find.text('50 kg available'));
      expect(availability.left, closeTo(278, 0.6));
      expect(availability.top, closeTo(546.2, 0.6));

      final pillLabel = tester.getRect(find.text('Active'));
      expect(pillLabel.left, closeTo(330, 0.6));
      expect(pillLabel.top, closeTo(500, 0.6));

      final preview = tester.getRect(find.text('Preview product'));
      expect(preview.center.dx, closeTo(206, 0.6));
      expect(preview.center.dy, closeTo(808.5, 0.6));

      final addLabel = tester.getRect(find.text('Add another product'));
      expect(addLabel.center.dy, closeTo(872.5, 0.6));
    });
  });
}


