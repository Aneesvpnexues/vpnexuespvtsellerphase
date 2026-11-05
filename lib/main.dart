import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_storage.dart';
import 'data/product_store.dart';
import 'data/seller_profile_store.dart';
import 'data/session_store.dart';
import 'data/user_store.dart';
import 'screens/seller_home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_seller_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  await _hydrateStores();
  runApp(const SellerApp());
}

/// Loads the persistent local storage and restores every store before the
/// first frame, so the splash screen already knows whether a session exists
/// and the profile / product screens render saved data immediately.
///
/// If storage is unavailable (e.g. a broken platform channel) the app still
/// boots with the in-memory defaults instead of hanging on the splash.
Future<void> _hydrateStores() async {
  try {
    final AppStorage storage = await AppStorage.create();
    await SessionStore.instance.attachStorage(storage);
    await UserStore.instance.attachStorage(storage);
    await SellerProfileStore.instance.attachStorage(storage);
    await ProductStore.instance.attachStorage(storage);
  } catch (_) {
    // Run in-memory; every store keeps its defaults.
  }
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  /// The screen the app opens on.
  ///
  /// The splash is a one-time, first-run-only screen: it shows on the very
  /// first launch after installing, and once the seller taps through it the
  /// flag [StorageKeys.splashSeenKey] is persisted. Every later launch goes
  /// straight to the last reached destination — home for an active session,
  /// the Welcome / login screen otherwise.
  ///
  /// If storage never hydrated (e.g. a broken platform channel) the flag is
  /// unreadable and the splash is shown again, matching the old behavior.
  static Widget _initialScreen() {
    if (!SplashScreen.hasSeenSplash) {
      return const SplashScreen();
    }
    return SessionStore.instance.isAuthenticated
        ? const SellerHomeScreen()
        : const WelcomeSellerScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seller App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Inter'),
      home: _initialScreen(),
    );
  }
}
