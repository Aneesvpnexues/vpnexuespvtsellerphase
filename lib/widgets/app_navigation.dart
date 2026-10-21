import 'package:flutter/material.dart';

import '../screens/add_product_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/my_products_screen.dart';
import '../screens/order_accepted_screen.dart';
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
  static const String orderAccepted = '/order-accepted';
}

/// Switches the bottom navigation tab.
///
/// The current tab is a no-op, any other tab replaces the current screen with
/// the target one, so the stack never grows a duplicate of the same screen.
void switchTab(BuildContext context, Widget screen, String routeName) {
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
      builder: (_) => const AddProductScreen(),
    ),
  );
}

/// Opens the accepted-order state when the seller accepts an order.
void goToOrderAccepted(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.orderAccepted),
      builder: (_) => const OrderAcceptedScreen(),
    ),
  );
}
