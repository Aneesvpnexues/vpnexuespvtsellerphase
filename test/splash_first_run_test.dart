import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/app_storage.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/splash_screen.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';
import 'package:seller_app/services/cold_start_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one-time splash.
///
/// Two rules are guarded here:
///  * the artwork is shown on the **first launch after installation**, and
///    only ever ends on the Welcome screen (via its arrow);
///  * it is never built again — every later launch resolves to Welcome, Home
///    or the unfinished onboarding step instead.
void main() {
  void resetState() {
    SessionStore.instance.endSession();
    SellerProfileStore.instance.reset();
  }

  /// Hydrates the stores exactly like `main()` before the first frame.
  Future<AppStorage> bootStorage({bool splashSeen = false}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (splashSeen) StorageKeys.splashSeenKey: 'true',
    });
    final AppStorage storage = await AppStorage.create();
    await SessionStore.instance.attachStorage(storage);
    await SellerProfileStore.instance.attachStorage(storage);
    return storage;
  }

  /// Pumps a screen on a phone-sized viewport and gives every pending
  /// post-frame callback a chance to run. Bounded instead of
  /// `pumpAndSettle` so a looping spinner cannot time the test.
  Future<void> pumpFrames(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: home));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  setUp(resetState);

  testWidgets(
      'first launch: the artwork shows and its arrow opens Welcome and '
      'marks the splash as served', (WidgetTester tester) async {
    resetState();
    await bootStorage();

    expect(SplashScreen.hasSeenSplash, isFalse);
    expect(ColdStartRouter.resolve(), ColdStart.firstRunSplash);

    await pumpFrames(
      tester,
      ColdStartRouter.screenFor(ColdStartRouter.resolve()),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const Key('splashTap')), findsOneWidget);

    await tester.tap(find.byKey(const Key('splashTap')));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(WelcomeSellerScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);

    // This is what makes the artwork one-per-install: the flag is readable
    // synchronously, so the very next resolve already skips it.
    expect(SplashScreen.hasSeenSplash, isTrue);
    expect(ColdStartRouter.resolve(), ColdStart.welcome);
    expect(
      ColdStartRouter.screenFor(ColdStartRouter.resolve()),
      isA<WelcomeSellerScreen>(),
    );
  });

  testWidgets(
      'a later launch never builds the splash again, with or without a session',
      (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);

    // Signed out → Welcome.
    expect(
      ColdStartRouter.screenFor(ColdStartRouter.resolve()),
      isA<WelcomeSellerScreen>(),
    );

    // Signed in with every section done → Home, straight away.
    SessionStore.instance.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
      uid: '',
    );
    SellerProfileStore.instance
      ..setLocationComplete(true)
      ..setSellerTypeComplete(true)
      ..setCompletion(
        profileComplete: true,
        bankComplete: true,
        verificationComplete: true,
        personalComplete: true,
      );

    expect(ColdStartRouter.resolve(), ColdStart.home);
    await pumpFrames(
      tester,
      ColdStartRouter.screenFor(ColdStartRouter.resolve()),
    );
    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets(
      'a splash that is somehow shown to a signed-in seller re-routes instead '
      'of waiting for a tap', (WidgetTester tester) async {
    resetState();
    // The splash flag failed to persist (or was lost), yet the session is
    // still here: the artwork may appear, but the seller must not be parked
    // on it or sent to Welcome.
    await bootStorage();
    SessionStore.instance.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
      uid: '',
    );
    SellerProfileStore.instance
      ..setLocationComplete(true)
      ..setSellerTypeComplete(true)
      ..setCompletion(
        profileComplete: true,
        bankComplete: true,
        verificationComplete: true,
        personalComplete: true,
      );

    await pumpFrames(tester, const SplashScreen());

    expect(find.byType(WelcomeSellerScreen), findsNothing);
    expect(find.byType(SellerHomeScreen), findsOneWidget);
    // …and the flag is repaired on the way through, so it never happens twice.
    expect(SplashScreen.hasSeenSplash, isTrue);
  });
}
