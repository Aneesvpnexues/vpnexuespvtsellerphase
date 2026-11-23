import 'package:flutter/material.dart';

import '../data/order_store.dart';
import '../data/product_store.dart';
import '../data/sales_store.dart';
import '../screens/add_products_screen.dart';
import '../screens/bank_detaile.dart';
import '../screens/business_details_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/my_products_screen.dart';
import '../screens/order_confirmation_screen.dart';
import '../screens/order_pickup_code_screen.dart';
import '../screens/order_privew.dart';
import '../screens/product_details_screen.dart';
import '../screens/review_ratings_page.dart';
import '../screens/verify_detaile.dart';
import '../screens/verification_kyc_screen.dart';
import '../screens/wallet_page.dart';
import '../screens/profile_screen.dart';
import '../screens/seller_home_screen.dart';
import '../screens/settings_screen.dart';

/// Named routes for the bottom navigation tabs. Every screen that is pushed
/// from the bottom nav carries its name so the tab can be re-selected without
/// stacking duplicates of the same screen.
abstract final class AppRoutes {
  static const String home = '/home';
  static const String products = '/products';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String orderDetails = '/order-details';
  static const String personalDetails = '/personal-details';
  static const String businessFarm = '/business-farm';
  static const String verificationKyc = '/verification-kyc';
  static const String bankDetails = '/bank-details';
  static const String settings = '/settings';
  static const String addProduct = '/add-product';
  static const String orderPrivew = '/order-privew';
  static const String productDetails = '/product-details';
  static const String orderPickupCode = '/order-pickup-code';
  static const String orderConfirmation = '/order-confirmation';
  static const String reviewRatings = '/review-ratings';
  static const String wallet = '/wallet';
  static const String businessDetails = '/business-details';
  static const String verifyDetails = '/verify-details';
  static const String bankDetaile = '/bank-detaile';
}

/// Switches the bottom navigation tab.
///
/// The current tab is a no-op, any other tab replaces the current screen with
/// the target one, so the stack never grows a duplicate of the same screen.
void switchTab(BuildContext context, Widget screen, String routeName) {
  FocusManager.instance.primaryFocus?.unfocus();
  final NavigatorState navigator = Navigator.of(context);
  final String? current = ModalRoute.of(context)?.settings.name;
  if (current == routeName) {
    return;
  }
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: routeName),
      builder: (_) => screen,
    ),
  );
}

/// Widget for the bottom navigation tab hit areas.
class BottomNavTab extends StatelessWidget {
  const BottomNavTab({
    super.key,
    required this.onTap,
    required this.width,
    this.height = 60,
  });

  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: width, height: height),
    );
  }
}

/// Opens the Seller Home tab.
void goToHome(BuildContext context) {
  switchTab(context, const SellerHomeScreen(), AppRoutes.home);
}

/// Opens the My Products tab.
void goToProducts(BuildContext context) {
  switchTab(context, const MyProductsScreen(), AppRoutes.products);
}

/// Opens the My Orders tab.
void goToOrders(BuildContext context) {
  switchTab(context, const MyOrdersScreen(), AppRoutes.orders);
}

/// Returns to the My Orders tab after the order flow finishes, dropping the
/// completed detail/pickup/confirmation states from the stack.
///
/// Pass [completedOrderId] to move that order to delivered — the
/// confirmation screen is the "order completed / collected" state.
void goToOrdersRoot(BuildContext context, {String? completedOrderId}) {
  // TEMPORARY: local status move until the database write exists.
  if (completedOrderId != null) {
    OrderStore.instance.markOrder(completedOrderId, OrderStatus.delivered);
  }
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orders),
      builder: (_) => const MyOrdersScreen(),
    ),
    (Route<dynamic> route) => false,
  );
}

/// Opens the Profile tab.
void goToProfile(BuildContext context) {
  switchTab(context, const ProfileScreen(), AppRoutes.profile);
}

/// Opens the Settings screen from the home header.
void goToSettings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.settings),
      builder: (_) => const SettingsScreen(),
    ),
  );
}

/// Opens the Add Products flow from the My Products screen.
void goToAddProduct(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.addProduct),
      builder: (_) => const AddProductsScreen(),
    ),
  );
}

/// Opens the Add Products flow in edit mode for an existing [product].
///
/// The form opens prefilled and saving updates that same listing. The
/// returned future completes when the edit screen is closed, so callers can
/// refresh from the store afterwards.
Future<void> goToEditProduct(BuildContext context, Product product) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.addProduct),
      builder: (_) => AddProductsScreen(product: product),
    ),
  );
}

/// Opens the product-live preview (Zeplin 172).
void goToOrderPrivew(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderPrivew),
      builder: (_) => const OrderPrivewScreen(),
    ),
  );
}

/// Opens the product details page (Zeplin 171) for [product].
void goToProductDetails(BuildContext context, {Product? product}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.productDetails),
      builder: (_) => ProductDetailsScreen(product: product),
    ),
  );
}

/// Opens the pickup code entry state (Zeplin 154) for [orderId].
void goToOrderPickupCode(BuildContext context, {String orderId = '#NX4582'}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderPickupCode),
      builder: (_) => OrderPickupCodeScreen(orderId: orderId),
    ),
  );
}

/// Opens the completed confirmation state (Zeplin 259) after the correct
/// pickup code has been entered, recording the sale into [SalesStore] so
/// the home Sales Overview reflects the purchase.
void goToOrderConfirmation(
  BuildContext context, {
  double amount = 2840,
  int itemsCount = 3,
  String orderId = '#NX4582',
  DateTime? dateTime,
}) {
  SalesStore.instance.recordSale(
    amount: amount,
    itemsCount: itemsCount,
    orderId: orderId,
    dateTime: dateTime ?? DateTime.now(),
  );
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderConfirmation),
      builder: (_) => OrderConfirmationScreen(orderId: orderId),
    ),
  );
}

/// Opens the review and ratings page (Zeplin 152) from the Business tab.
void goToReviewRatings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.reviewRatings),
      builder: (_) => const ReviewRatingsPage(),
    ),
  );
}

/// Opens the wallet page (Zeplin 88) from the Business tab.
void goToWallet(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.wallet),
      builder: (_) => const WalletPage(),
    ),
  );
}

/// Opens the STEP 03 business details slide (onboarding continuation).
void goToBusinessDetails(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.businessDetails),
      builder: (_) => const Step03BusinessDetailsScreen(),
    ),
  );
}

/// Opens the verify details slide (Zeplin 84).
void goToVerifyDetails(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.verifyDetails),
      builder: (_) => const VerifyDetaileScreen(),
    ),
  );
}

/// Opens the verification (KYC) details screen (Zeplin 161).
void goToVerificationKyc(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.verificationKyc),
      builder: (_) => const VerificationKycScreen(),
    ),
  );
}

/// Opens the onboarding bank details slide (Zeplin 106).
void goToBankDetaile(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.bankDetaile),
      builder: (_) => const BankDetaileScreen(),
    ),
  );
}
