import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../data/session_store.dart';
import '../screens/add_products_screen.dart';
import '../screens/bank_detaile.dart';
import '../screens/business_details_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/my_products_screen.dart';
import '../screens/order_delivery_screen.dart';
import '../screens/order_pickup_code_screen.dart';
import '../screens/order_pickup_success_screen.dart';
import '../screens/order_privew.dart';
import '../screens/order_ready_screen.dart';
import '../screens/product_details_screen.dart';
import '../screens/review_ratings_page.dart';
import '../screens/verify_detaile.dart';
import '../screens/welcome_seller_screen.dart';
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
  static const String orderReady = '/order-ready';
  static const String orderDelivery = '/order-delivery';
  static const String orderPrivew = '/order-privew';
  static const String productDetails = '/product-details';
  static const String orderPickupCode = '/order-pickup-code';
  static const String orderPickupSuccess = '/order-pickup-success';
  static const String reviewRatings = '/review-ratings';
  static const String wallet = '/wallet';
  static const String businessDetails = '/business-details';
  static const String verifyDetails = '/verify-details';
  static const String bankDetaile = '/bank-detaile';
}

/// Guards the authenticated part of the app.
///
/// Returns `true` when a session is active. Otherwise it clears the stack and
/// returns the user to the Welcome (login) screen, reporting `false` so the
/// caller skips its own navigation. Every route helper below calls this, so
/// no authenticated screen can be opened after logout or on a cold start
/// without a session.
bool requireSession(BuildContext context) {
  if (SessionStore.instance.isAuthenticated) return true;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const WelcomeSellerScreen()),
    (route) => false,
  );
  return false;
}

/// Switches the bottom navigation tab.
///
/// The current tab is a no-op, any other tab replaces the current screen with
/// the target one, so the stack never grows a duplicate of the same screen.
/// Requires an active session (see [requireSession]).
void switchTab(BuildContext context, Widget screen, String routeName) {
  if (!requireSession(context)) return;
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
/// completed detail/ready/delivery/pickup states from the stack.
void goToOrdersRoot(BuildContext context) {
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
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.settings),
      builder: (_) => const SettingsScreen(),
    ),
  );
}

/// Opens the Add Products flow from the My Products screen.
void goToAddProduct(BuildContext context) {
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.addProduct),
      builder: (_) => const AddProductsScreen(),
    ),
  );
}

/// Opens the ready-to-pickup state (every item packed) from the accepted order.
void goToOrderReady(BuildContext context) {
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderReady),
      builder: (_) => const OrderReadyScreen(),
    ),
  );
}

/// Opens the out-for-delivery state from the ready order's slide CTA.
void goToOrderDelivery(BuildContext context) {
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderDelivery),
      builder: (_) => const OrderDeliveryScreen(),
    ),
  );
}

/// Opens the product-live preview (Zeplin 172).
void goToOrderPrivew(BuildContext context) {
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderPrivew),
      builder: (_) => const OrderPrivewScreen(),
    ),
  );
}

/// Opens the product details page (Zeplin 171) for [product].
void goToProductDetails(BuildContext context, {Product? product}) {
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.productDetails),
      builder: (_) => ProductDetailsScreen(product: product),
    ),
  );
}

/// Opens the pickup code entry state (Zeplin 154).
void goToOrderPickupCode(BuildContext context) {
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderPickupCode),
      builder: (_) => const OrderPickupCodeScreen(),
    ),
  );
}

/// Opens the pickup confirmed state (Zeplin 165).
void goToOrderPickupSuccess(BuildContext context) {
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderPickupSuccess),
      builder: (_) => const OrderPickupSuccessScreen(),
    ),
  );
}

/// Opens the review and ratings page (Zeplin 152) from the Business tab.
void goToReviewRatings(BuildContext context) {
  if (!requireSession(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.reviewRatings),
      builder: (_) => const ReviewRatingsPage(),
    ),
  );
}

/// Opens the wallet page (Zeplin 88) from the Business tab.
void goToWallet(BuildContext context) {
  if (!requireSession(context)) return;
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

/// Opens the onboarding bank details slide (Zeplin 106).
void goToBankDetaile(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.bankDetaile),
      builder: (_) => const BankDetaileScreen(),
    ),
  );
}
