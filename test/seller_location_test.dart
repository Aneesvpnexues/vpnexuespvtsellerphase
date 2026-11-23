import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/business_farm_screen.dart';

/// Regression tests for BUG_SELLER_023 — "Incorrect Location Display".
///
/// The seller picks a place during login (Coimbatore), yet Profile →
/// Business & Farm → Address & Location showed "Salem, Tamil Nadu" while the
/// map sat on Bengaluru. These tests pin down the three parts of the fix:
/// one shared location value, a map that opens on the seller's coordinates,
/// and a store that keeps the pick instead of dropping it at login.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SellerProfileStore store;
  late String previousLocation;
  late String previousAddress;

  setUp(() {
    store = SellerProfileStore.instance;
    previousLocation = store.businessLocation;
    previousAddress = store.businessAddress;
    // Clears the login pick, its address and its coordinates.
    store.setPickedLocation(label: '', address: '');
  });

  tearDown(() {
    store.setPickedLocation(label: '', address: '');
    store.saveBusinessDetails(
      name: store.name,
      business: store.businessName,
      phone: store.mobile,
      location: previousLocation,
      address: previousAddress,
      farmSize: store.farmSize,
    );
  });

  group('SellerProfileStore location', () {
    test('displayLocation prefers the login map pick over Business & Farm', () {
      store.saveBusinessDetails(
        name: 'Ramesh Kumar',
        business: 'Kumar Organic Farm',
        phone: '+91 12345 67890',
        location: 'Salem, Tamil Nadu',
        address: '',
        farmSize: '5',
      );
      store.setPickedLocation(label: 'Coimbatore, Tamil Nadu');

      expect(store.displayLocation, 'Coimbatore, Tamil Nadu');
    });

    test('displayLocation falls back to the saved Business & Farm address', () {
      store.saveBusinessDetails(
        name: 'Ramesh Kumar',
        business: 'Kumar Organic Farm',
        phone: '+91 12345 67890',
        location: 'Erode, Tamil Nadu',
        address: '',
        farmSize: '5',
      );

      expect(store.displayLocation, 'Erode, Tamil Nadu');
    });

    test('displayLocation only uses the placeholder when nothing was chosen', () {
      expect(store.displayLocation, 'Salem, Tamil Nadu');
      expect(store.shortLocation, 'Salem, TN');
      expect(store.sellerSummary, 'Farmer, Salem, Tamil Nadu');
    });

    test('shortLocation abbreviates the state like the home badge', () {
      store.setPickedLocation(label: 'Coimbatore, Tamil Nadu');

      expect(store.shortLocation, 'Coimbatore, TN');
      expect(store.sellerSummary, 'Farmer, Coimbatore, Tamil Nadu');
    });

    test('shortLocation keeps a single-word location as typed', () {
      store.setPickedLocation(label: 'Coimbatore');

      expect(store.shortLocation, 'Coimbatore');
    });
  });

  testWidgets(
    'Address & Location shows the selected place and opens the map on it',
    (WidgetTester tester) async {
      // The seller chose Coimbatore during login, with the pin to match.
      store.setPickedLocation(
        label: 'Coimbatore, Tamil Nadu',
        address: 'Gandhipuram, Coimbatore · 641012',
        latitude: 11.0168,
        longitude: 76.9558,
      );

      await tester.pumpWidget(
        const MaterialApp(home: BusinessFarmScreen()),
      );
      await tester.pump();

      // The hero pill, the address field and the caption under the map all
      // read the seller's own place — and the placeholder city is gone.
      expect(find.text('Coimbatore, Tamil Nadu'), findsNWidgets(3));
      expect(find.text('Salem, Tamil Nadu'), findsNothing);

      // The map starts on the selected coordinates, not the placeholder
      // city it used to open on.
      final FlutterMap map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCenter, const LatLng(11.0168, 76.9558));

      // Let tiles/frames settle and surface anything the screen threw.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('editing the address and saving publishes it to the store',
      (WidgetTester tester) async {
    // Tall viewport so the whole screen — including Save — is on screen.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    store.setPickedLocation(label: 'Salem, Tamil Nadu');

    await tester.pumpWidget(
      const MaterialApp(home: BusinessFarmScreen()),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Salem, Tamil Nadu'),
      'Coimbatore, Tamil Nadu',
    );
    // Drain the address geocode debounce and the geocoder's rate-limit waits
    // so no timer outlives the test.
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    // The edited place reaches both halves of the store, so Address &
    // Location, Home and Profile all agree afterwards.
    expect(store.businessLocation, 'Coimbatore, Tamil Nadu');
    expect(store.displayLocation, 'Coimbatore, Tamil Nadu');
  });
}
