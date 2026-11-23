import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/app_storage.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/business_details_screen.dart';
import 'package:seller_app/screens/location_confirm_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/seller_type_screen.dart';
import 'package:seller_app/screens/splash_screen.dart';
import 'package:seller_app/screens/verify_detaile.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';
import 'package:seller_app/services/cold_start_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cold-start routing.
///
/// These tests are the regression guard for the bug where the app opened on
/// the home page on a fresh install (the splash was never built) and for the
/// session bug where a restart sent a signed-in seller back to the Welcome
/// screen. [ColdStartRouter.resolve] must answer from what this device has
/// persisted — the one-time splash flag, the session, and the onboarding
/// flags — never from Firebase Auth and never from the network.
void main() {
  /// Puts every singleton back to the state a fresh install would have.
  void resetState() {
    SessionStore.instance.endSession();
    SellerProfileStore.instance.reset();
  }

  /// Hydrates the stores from a fresh (optionally splash-seen) preference
  /// set, exactly like `main()` does before the first frame.
  Future<AppStorage> bootStorage({bool splashSeen = false}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (splashSeen) StorageKeys.splashSeenKey: 'true',
    });
    final AppStorage storage = await AppStorage.create();
    await SessionStore.instance.attachStorage(storage);
    await SellerProfileStore.instance.attachStorage(storage);
    return storage;
  }

  /// Marks every onboarding section as finished on this device.
  SellerProfileStore markOnboardingComplete() {
    return SellerProfileStore.instance
      ..setLocationComplete(true)
      ..setSellerTypeComplete(true)
      ..setCompletion(
        profileComplete: true,
        bankComplete: true,
        verificationComplete: true,
        personalComplete: true,
      );
  }

  setUp(resetState);

  testWidgets(
      'a first launch after installing opens on the splash, never the home page',
      (WidgetTester tester) async {
    resetState();
    await bootStorage();

    final ColdStart start = ColdStartRouter.resolve();
    expect(start, ColdStart.firstRunSplash);

    await tester.pumpWidget(
      MaterialApp(home: ColdStartRouter.screenFor(start)),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(SellerHomeScreen), findsNothing);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets('a later launch without a session opens on Welcome, not Splash',
      (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    // No `startSession` — the record Logout leaves behind.

    final ColdStart start = ColdStartRouter.resolve();
    expect(start, ColdStart.welcome);

    await tester.pumpWidget(
      MaterialApp(home: ColdStartRouter.screenFor(start)),
    );
    await tester.pump();

    expect(find.byType(WelcomeSellerScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(SellerHomeScreen), findsNothing);
  });

  testWidgets(
      'a logged-in relaunch opens directly on Home with no splash and no '
      'Welcome in between', (WidgetTester tester) async {
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
    markOnboardingComplete();

    final ColdStart start = ColdStartRouter.resolve();
    expect(start, ColdStart.home);

    await tester.pumpWidget(
      MaterialApp(home: ColdStartRouter.screenFor(start)),
    );
    await tester.pump();

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets(
      'a half-finished registration resumes on the first unfinished page '
      'instead of Welcome', (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    SessionStore.instance.startSession(
      phone: '',
      userName: 'Meena',
      method: SessionStore.signupMethod,
    );

    // Nothing done yet — STEP 01 (Location) is where the walk starts.
    expect(
      ColdStartRouter.screenFor(ColdStartRouter.resolve()),
      isA<LocationConfirmScreen>(),
    );

    // STEP 01 is done; STEP 02 (seller type) is not — the walk continues
    // there, not on STEP 03 and never on the Welcome screen.
    SellerProfileStore.instance.setLocationComplete(true);

    final ColdStart start = ColdStartRouter.resolve();
    expect(start, ColdStart.onboardingStep);

    await tester.pumpWidget(
      MaterialApp(home: ColdStartRouter.screenFor(start)),
    );
    await tester.pump();

    expect(find.byType(Step02SellerTypeScreen), findsOneWidget);
    expect(find.byType(Step03BusinessDetailsScreen), findsNothing);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets(
      'STEP 01 and STEP 02 done resumes on Business Details, STEP 04 pending '
      'resumes on Verify', (WidgetTester tester) async {
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

    expect(
      ColdStartRouter.screenFor(ColdStartRouter.resolve()),
      isA<Step03BusinessDetailsScreen>(),
    );

    // Walk one step further: business details done, verification not.
    SellerProfileStore.instance.setCompletion(
      profileComplete: true,
      bankComplete: false,
      verificationComplete: false,
      personalComplete: false,
    );
    expect(
      ColdStartRouter.screenFor(ColdStartRouter.resolve()),
      isA<VerifyDetaileScreen>(),
    );

    // …and the last pending step.
    SellerProfileStore.instance.setCompletion(
      profileComplete: true,
      bankComplete: false,
      verificationComplete: true,
      personalComplete: false,
    );
    expect(
      ColdStartRouter.screenFor(ColdStartRouter.resolve()),
      isA<BankDetaileScreen>(),
    );
  });

  testWidgets('a finished sign-up relaunches on Home', (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    SessionStore.instance.startSession(
      phone: '',
      userName: 'Meena',
      method: SessionStore.signupMethod,
    );
    markOnboardingComplete();

    final ColdStart start = ColdStartRouter.resolve();
    expect(start, ColdStart.home);

    await tester.pumpWidget(
      MaterialApp(home: ColdStartRouter.screenFor(start)),
    );
    await tester.pump();

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets(
      'the splash flag alone never brings the artwork back once it has been '
      'served', (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);

    // With and without a session — neither may resolve to the artwork.
    for (final bool signedIn in <bool>[false, true]) {
      if (signedIn) {
        SessionStore.instance.startSession(
          phone: '+91 98765 43210',
          userName: 'Ravi Kumar',
          method: SessionStore.loginMethod,
          uid: '',
        );
        markOnboardingComplete();
      }
      for (int i = 0; i < 3; i++) {
        expect(ColdStartRouter.resolve(), isNot(ColdStart.firstRunSplash));
        expect(
          ColdStartRouter.screenFor(ColdStartRouter.resolve()),
          isNot(isA<SplashScreen>()),
        );
      }
      if (signedIn) SessionStore.instance.endSession();
    }
  });

  testWidgets('logging out sends the next launch to Welcome', (WidgetTester tester) async {
    resetState();
    await bootStorage(splashSeen: true);
    SessionStore.instance.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
      uid: 'firebase-uid-1',
    );
    markOnboardingComplete();
    expect(ColdStartRouter.resolve(), ColdStart.home);

    SessionStore.instance.endSession();

    final ColdStart start = ColdStartRouter.resolve();
    expect(start, ColdStart.welcome);
    await tester.pumpWidget(
      MaterialApp(home: ColdStartRouter.screenFor(start)),
    );
    await tester.pump();
    expect(find.byType(WelcomeSellerScreen), findsOneWidget);
  });
}
