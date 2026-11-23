import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/api_config.dart';
import 'data/app_storage.dart';
import 'data/product_store.dart';
import 'data/secure_session_store.dart';
import 'data/seller_profile_store.dart';
import 'data/session_store.dart';
import 'data/user_store.dart';
import 'l10n/app_languages.dart';
import 'l10n/app_strings.dart';
import 'l10n/locale_service.dart';
import 'services/cold_start_router.dart';
import 'services/geo_service.dart';
import 'services/network_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.load();
  await _hydrateStorage();
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
  //
  // The session restore runs in the same phase: the destination was already
  // chosen before the first frame (see [ColdStartRouter.resolve]), so this
  // only brings that seller's rows back, refreshes the token and re-merges
  // the onboarding flags from Supabase — it never navigates, except when the
  // server proves the session itself is dead.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.init();
    NetworkService.instance.init();
    GeoService.instance.init();
    unawaited(ColdStartRouter.restoreSessionInBackground());
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

/// Loads the persistent local storage once before the first frame, so the
/// one-time splash flag, the restored session (whether it was opened by login
/// or sign-up), every registered sign-up account, the saved onboarding
/// progress and the products saved on this device are all readable
/// synchronously from the very first build — which is what lets
/// [ColdStartRouter.resolve] pick the opening screen without a spinner in
/// between.
///
/// The session record itself is handed to [openSessionStorage], which keeps
/// it in the platform keystore and migrates the legacy plaintext copy out of
/// SharedPreferences on the first boot of this build.
///
/// If storage is unavailable (e.g. a broken platform channel or a widget
/// test without a mock) the app still boots with in-memory defaults: the
/// splash flag then reads as "not seen" and the splash shows again, which
/// matches the pre-persistence behavior.
Future<void> _hydrateStorage() async {
  try {
    final AppStorage storage = await AppStorage.create();

    // Kept in its own guard: a keystore problem must cost the session its
    // extra protection, never the attachment of the stores below it.
    KeyValueStore sessionStorage = storage;
    try {
      sessionStorage = await openSessionStorage(storage);
    } catch (error) {
      debugPrint('Secure session storage unavailable, using preferences: $error');
    }

    await SessionStore.instance.attachStorage(sessionStorage);
    await UserStore.instance.attachStorage(storage);
    await SellerProfileStore.instance.attachStorage(storage);
    // Last, so a failure here never skips the stores above; product
    // hydration also guards its own decode.
    ProductStore.instance.attachStorage(storage);
  } catch (error) {
    // Run in-memory; every store keeps its defaults. The debug log matters:
    // without persisted storage a restart looks like a fresh install and the
    // seller is asked to sign in again, so the cause must be visible.
    debugPrint('Local storage unavailable, running in-memory: $error');
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
          // Decided before this build runs, from the stores hydrated in
          // `main()`: the splash artwork only on a fresh install, Welcome
          // when there is no session, and Home for a signed-in seller — a
          // Login (OTP) session always opens Home, while a Sign Up session
          // resumes its unfinished onboarding step. A logged-in relaunch
          // therefore opens on Home with no splash and no Welcome in between.
          home: ColdStartRouter.screenFor(ColdStartRouter.resolve()),
        );
      },
    );
  }
}
