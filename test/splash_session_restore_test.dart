import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/app_storage.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/business_details_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/seller_type_screen.dart';
import 'package:seller_app/screens/splash_screen.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';
import 'package:seller_app/services/auth_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cold-start routing.
///
/// These tests are the regression guard for the session bug where a restart
/// sent a signed-in seller back to the Welcome screen: Splash must route from
/// the locally persisted session (and the onboarding flags saved on the
/// device), never from Firebase Auth alone — a sign-up session has no Firebase
/// user at all, and a lost Firebase session is not a logout.
void main() {
  /// Puts every singleton back to the state a fresh install would have.
  void resetState() {
    SplashScreen.debugSignedInSeller = null;
    AuthFlow.instance
      ..firebaseUid = null
      ..verified = false;
    SessionStore.instance.endSession();
    SellerProfileStore.instance.reset();
  }

  /// Hydrates the stores from a fresh (optionally splash-seen) preference set,
  /// exactly like `main()` does before the first frame.
  Future<AppStorage> bootStorage({bool splashSeen = false}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (splashSeen) StorageKeys.splashSeenKey: 'true',
    });
    final AppStorage storage = await AppStorage.create();
    await SessionStore.instance.attachStorage(storage);
    await SellerProfileStore.instance.attachStorage(storage);
    return storage;
  }

  /// Renders the splash and lets the session check finish. Bounded instead of
  /// `pumpAndSettle` so a screen with a looping spinner cannot time the test.
  Future<void> pumpSplash(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  setUp(() {
    resetState();
  });

  testWidgets('a logged-in seller restarts on Home, not the Welcome screen',
      (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    SessionStore.instance.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
      // No Firebase UID: this is exactly the cold start that used to fall
      // back to "nobody is signed in" and asked for the OTP again.
      uid: '',
    );

    await pumpSplash(tester);

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets(
      'a login session with a UID still opens Home when the backend '
      'cannot be reached', (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    SessionStore.instance.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
      uid: 'firebase-uid-1',
    );

    await pumpSplash(tester);

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets(
      'a half-finished sign-up resumes on the first unfinished page '
      'instead of the Welcome screen', (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    SessionStore.instance.startSession(
      phone: '',
      userName: 'Meena',
      method: SessionStore.signupMethod,
    );
    // STEP 01 (location) is done; STEP 02 (seller type) is not — the walk
    // continues there, not on STEP 03 and never on the Welcome screen.
    SellerProfileStore.instance.setLocationComplete(true);

    await pumpSplash(tester);

    expect(find.byType(Step02SellerTypeScreen), findsOneWidget);
    expect(find.byType(Step03BusinessDetailsScreen), findsNothing);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets(
      'a sign-up that finished STEP 01 and STEP 02 resumes on Business '
      'Details', (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    SessionStore.instance.startSession(
      phone: '',
      userName: 'Meena',
      method: SessionStore.signupMethod,
    );
    SellerProfileStore.instance
      ..setLocationComplete(true)
      ..setSellerTypeComplete(true);

    await pumpSplash(tester);

    expect(find.byType(Step03BusinessDetailsScreen), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets('a finished sign-up restarts on Home', (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    SessionStore.instance.startSession(
      phone: '',
      userName: 'Meena',
      method: SessionStore.signupMethod,
    );
    SellerProfileStore.instance
      ..setLocationComplete(true)
      ..setCompletion(
        profileComplete: true,
        bankComplete: true,
        verificationComplete: true,
        personalComplete: true,
      );

    await pumpSplash(tester);

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets('without a session the Welcome screen still opens',
      (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    // No `startSession` — the record Logout leaves behind.

    await pumpSplash(tester);

    expect(find.byType(WelcomeSellerScreen), findsOneWidget);
    expect(find.byType(SellerHomeScreen), findsNothing);
  });
}
