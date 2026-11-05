import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/app_storage.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/main.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the app on the 412x917 artboard the design was drawn for.
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SellerApp());
  await tester.pumpAndSettle();
}

/// Hydrates [AppStorage] with the given preference values, as `main()` does
/// at boot, so the one-time splash flag can be exercised in a widget test.
Future<void> hydrateStorage(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  await AppStorage.create();
}

void main() {
  setUp(() {
    // The splash routes on the session; start every test signed out.
    SessionStore.instance.endSession();
    // No storage hydrated unless a test asks for it: the "first install"
    // case, where the splash flag has never been written.
    AppStorage.current = null;
  });

  tearDown(() {
    AppStorage.current = null;
  });

  testWidgets('first launch after install shows the splash, then taps '
      'through to Welcome', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);

    await tester.tapAt(const Offset(40, 120));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);

    await tester.tap(find.byKey(const Key('splashTap')));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeSellerScreen), findsOneWidget);
  });

  testWidgets('the splash is never shown again: a second launch goes '
      'straight to Welcome', (tester) async {
    // First launch: storage is empty, so the splash shows and the seller
    // taps through — which records the "splash seen" flag.
    await hydrateStorage(const <String, Object>{});
    await pumpApp(tester);
    expect(find.byKey(const Key('splashTap')), findsOneWidget);

    await tester.tap(find.byKey(const Key('splashTap')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Seller!', findRichText: true), findsOneWidget);

    // Second launch over the same storage: no splash, straight to Welcome.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpApp(tester);

    expect(find.byKey(const Key('splashTap')), findsNothing);
    expect(find.text('Welcome Seller!', findRichText: true), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('a relaunch with an active session and the splash already '
      'seen boots straight into the home page', (tester) async {
    // A seller who signed up (or logged in) on a previous run comes back to
    // an already-open session: the splash was dismissed back then, so the
    // app opens directly on the home page with no splash in between.
    await hydrateStorage(const <String, Object>{
      StorageKeys.splashSeenKey: 'true',
    });
    SessionStore.instance.startSession(
      phone: '+91 9876543210',
      userName: 'Ramesh Kumar',
      method: 'signup',
    );

    await pumpApp(tester);

    expect(find.byKey(const Key('splashTap')), findsNothing);
    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.text('Welcome Seller!', findRichText: true), findsNothing);
    expect(find.text('Send OTP'), findsNothing);
  });

  testWidgets('a logged-in seller who never dismissed the splash still sees '
      'it once', (tester) async {
    // Session restored but the splash flag is missing (e.g. storage was
    // unavailable when it was first dismissed): the splash shows once more
    // and continues into the home page.
    await hydrateStorage(const <String, Object>{});
    SessionStore.instance.startSession(
      phone: '+91 9876543210',
      userName: 'Ramesh Kumar',
      method: 'signup',
    );

    await pumpApp(tester);
    expect(find.byKey(const Key('splashTap')), findsOneWidget);

    await tester.tap(find.byKey(const Key('splashTap')));
    await tester.pumpAndSettle();

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(WelcomeSellerScreen), findsNothing);
  });

  testWidgets('splash stays put until the arrow button is tapped', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.text('Welcome Seller!', findRichText: true), findsNothing);

    // Time passes well beyond the old two-second auto-advance delay; the
    // splash must not navigate on its own.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('splashTap')), findsOneWidget);
    expect(find.text('Welcome Seller!', findRichText: true), findsNothing);
  });
}
