import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/product_store.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/location_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/splash_screen.dart';

void main() {
  setUp(() {
    SplashScreen.debugSignedInSeller = (
      uid: 'fake-firebase-uid',
      phone: '+919876543210',
    );
    SellerProfileStore.instance.reset();
    ProductStore.instance.clear();
  });

  tearDown(() {
    SplashScreen.debugSignedInSeller = null;
    SellerProfileStore.instance.reset();
    ProductStore.instance.clear();
  });

  testWidgets(
    'signed-in seller with no saved rows resumes at Step 01, not Home',
    (tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Step01LocationScreen), findsOneWidget);
      expect(find.byType(SellerHomeScreen), findsNothing);
    },
  );
}
