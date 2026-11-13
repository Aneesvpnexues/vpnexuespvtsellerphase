import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/api_config.dart';
import 'data/product_store.dart';
import 'l10n/app_languages.dart';
import 'l10n/app_strings.dart';
import 'l10n/locale_service.dart';
import 'screens/splash_screen.dart';
import 'services/geo_service.dart';
import 'services/network_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.load();
  await LocaleService.instance.hydrate();
  await _initFirebase();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  await seedDemoProducts();
  runApp(const SellerApp());
  // After the first frame the notification permission dialog (Android 13+)
  // and the FCM token request can show over real UI instead of a blank
  // window. Never blocks startup and never runs in widget tests.
  // NetworkService shows the "Search for Network" toast when WiFi/data
  // drops; it also needs the first frame so the messenger key exists.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.init();
    NetworkService.instance.init();
    GeoService.instance.init();
  });
}

/// Firebase reads its options from `android/app/google-services.json`, so
/// no generated `firebase_options.dart` is needed on Android. Desktop/web
/// runs have no such config and simply skip Firebase instead of crashing.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (error) {
    debugPrint('Firebase unavailable, skipping init: $error');
  }
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when the seller applies a new language; the
    // AppStrings scope below is what screens translate through.
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Seller App',
          locale: locale,
          supportedLocales: AppLanguages.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AppStrings(
            languageCode: locale.languageCode,
            child: child ?? const SizedBox.shrink(),
          ),
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: NetworkService.instance.messengerKey,
          theme: ThemeData(fontFamily: 'Inter'),
          home: const SplashScreen(),
        );
      },
    );
  }
}
