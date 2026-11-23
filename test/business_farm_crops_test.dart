import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/business_farm_screen.dart';

import 'support/fake_key_value_store.dart';

/// BUG_SELLER_021 — "What you grow" on Business & Farm.
///
/// The seller has to be able to tap a crop to select/deselect it, leave edit
/// mode with Done, reopen the screen (or the app) and still find the exact
/// selection — and every assertion about a save reads the bytes that actually
/// landed in storage, never just the in-memory field.
void main() {
  late FakeKeyValueStore storage;

  /// The private key [SellerProfileStore] persists its profile under; spelled
  /// out so the tests can prove a write really reached storage.
  const String profileKey = 'seller_profile_local';

  setUp(() {
    storage = FakeKeyValueStore();
    // Wipe whatever the previous test left in the singleton before the new
    // storage is attached, otherwise its fields would leak across tests.
    SellerProfileStore.instance.reset();
  });

  /// The crop list as stored on disk, or null when nothing was written yet.
  List<String>? savedCrops() {
    final String? raw = storage.values[profileKey];
    if (raw == null) return null;
    final Map<String, dynamic> data =
        jsonDecode(raw) as Map<String, dynamic>;
    final Object? value = data['crops'];
    if (value is! List) return null;
    return value.map((Object? item) => item.toString()).toList();
  }

  /// Reads the persisted profile as a map (null when nothing was written).
  Map<String, Object?>? savedProfile() {
    final String? raw = storage.values[profileKey];
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> attachStorage() =>
      SellerProfileStore.instance.attachStorage(storage);

  Future<void> pumpFarm(WidgetTester tester) async {
    // The design width (412dp) and a tall viewport so the whole "What you
    // grow" card is on screen without scrolling; the Save button still sits
    // below the fold and is brought in with ensureVisible.
    tester.view.physicalSize = const Size(412 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: BusinessFarmScreen()));
    // initState schedules a 400ms geocode debounce — let it fire (it exits
    // immediately on a short/empty location) before interacting.
    await tester.pump(const Duration(seconds: 1));
  }

  /// The chip for [crop].
  Finder chip(String crop) => find.byKey(ValueKey('crop-chip-$crop'));

  /// Let snackbars run out their timers so the test ends without a pending
  /// Timer failure.
  Future<void> settleSnackbars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
  }

  testWidgets(
      'tapping a crop selects and deselects it, and every change is written '
      'to storage', (tester) async {
    await attachStorage();
    await pumpFarm(tester);

    // Starter selection for a profile with no crop data yet.
    expect(SellerProfileStore.instance.crops,
        SellerProfileStore.defaultCrops);

    // Untapped: nothing written yet beyond what the store restored.
    expect(savedCrops(), isNull);

    // Select an unselected crop → the chip flips and the write is real.
    await tester.tap(chip('Onions'));
    await tester.pump();

    expect(SellerProfileStore.instance.crops, contains('Onions'));
    expect(savedCrops(), contains('Onions'));
    expect(find.text('Onions'), findsOneWidget); // no duplicate chip

    // Deselect a starter crop the same way.
    await tester.tap(chip('Tomatoes'));
    await tester.pump();

    expect(SellerProfileStore.instance.crops, isNot(contains('Tomatoes')));
    expect(savedCrops(), isNot(contains('Tomatoes')));

    // Tapping the same chip again re-selects it — the control toggles.
    await tester.tap(chip('Tomatoes'));
    await tester.pump();

    expect(SellerProfileStore.instance.crops, contains('Tomatoes'));
    expect(savedCrops(), contains('Tomatoes'));
    expect(savedCrops(), isNot(contains('Tomatoes ')));
    // One chip per crop, still.
    expect(find.text('Tomatoes'), findsOneWidget);
  });

  testWidgets(
      'Done saves the edited selection and a reopened screen restores it '
      '(Tomatoes, Spinach, Carrots → remove Spinach → add Onions)',
      (tester) async {
    await attachStorage();

    // --- Round 1: keep the starter trio, confirm with Done. ---
    await pumpFarm(tester);

    await tester.tap(find.text('Edit Crops'));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Crop selection saved.'), findsOneWidget);
    await settleSnackbars(tester);

    expect(savedCrops(), <String>['Tomatoes', 'Spinach', 'Carrots']);

    // --- Reopen the screen: the selection is still there. ---
    // Re-read the record so the screen can only pass by restoring from
    // disk, not from whatever the previous frame left in memory.
    await attachStorage();
    await pumpFarm(tester);
    expect(find.byKey(const ValueKey('crop-chip-Tomatoes')), findsOneWidget);
    expect(find.byKey(const ValueKey('crop-chip-Spinach')), findsOneWidget);
    expect(find.byKey(const ValueKey('crop-chip-Carrots')), findsOneWidget);
    expect(SellerProfileStore.instance.crops,
        <String>['Tomatoes', 'Spinach', 'Carrots']);

    // --- Round 2: remove Spinach, add Onions, save with Done. ---
    await tester.tap(find.text('Edit Crops'));
    await tester.pump();

    // The delete icon only exists in edit mode on a selected chip.
    await tester.tap(find.descendant(
      of: chip('Spinach'),
      matching: find.byType(Icon),
    ));
    await tester.pump();

    expect(SellerProfileStore.instance.crops, isNot(contains('Spinach')));
    expect(savedCrops(), isNot(contains('Spinach')));

    // Manual entry for a crop that is not in the starter list.
    await tester.enterText(
      find.byKey(const Key('manual-crop-field')),
      'Onions',
    );
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(SellerProfileStore.instance.crops, contains('Onions'));
    expect(savedCrops(), contains('Onions'));

    // Adding the same crop again must not duplicate it.
    await tester.enterText(
      find.byKey(const Key('manual-crop-field')),
      'onions',
    );
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(
      SellerProfileStore.instance.crops
          .where((String crop) => crop.toLowerCase() == 'onions'),
      hasLength(1),
    );

    await tester.tap(find.text('Done'));
    await tester.pump();
    await settleSnackbars(tester);

    // Verified against the stored bytes, not the in-memory field.
    expect(savedCrops(), <String>['Tomatoes', 'Carrots', 'Onions']);

    // --- Reopen: exactly the edited selection survives. ---
    await attachStorage();
    await pumpFarm(tester);
    expect(SellerProfileStore.instance.crops,
        <String>['Tomatoes', 'Carrots', 'Onions']);
    expect(savedCrops(), <String>['Tomatoes', 'Carrots', 'Onions']);
    expect(find.text('Spinach'), findsOneWidget); // still offered, unselected
    expect(find.byKey(const ValueKey('crop-chip-Spinach')), findsOneWidget);
  });

  testWidgets(
      'a legacy profile with no crop data keeps the starter selection and '
      'Save changes preserves the existing business details', (tester) async {
    // A record written before the crops field existed.
    storage.values[profileKey] = jsonEncode(<String, Object?>{
      'name': 'Legacy Seller',
      'mobile': '+91 98765 43210',
      'businessName': 'Legacy Organic Farm',
      // Kept under three characters on purpose: a longer address would kick
      // off the screen's Nominatim lookup, which is not what this test is
      // about.
      'businessLocation': 'AB',
      'businessAddress': 'AB',
      'farmSize': '3',
    });
    await attachStorage();
    await pumpFarm(tester);

    // Backward compatible: no `crops` key → the starter selection, not empty.
    expect(SellerProfileStore.instance.crops,
        SellerProfileStore.defaultCrops);

    await tester.ensureVisible(find.text('Save changes'));
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    // The success message follows a save that really ran.
    expect(
      find.text('Business & Farm details saved successfully!'),
      findsOneWidget,
    );
    await settleSnackbars(tester);

    final Map<String, Object?>? saved = savedProfile();
    expect(saved, isNotNull);
    expect(saved!['businessName'], 'Legacy Organic Farm');
    expect(saved['farmSize'], '3');
    expect(saved['name'], 'Legacy Seller');
    expect(saved['mobile'], '+91 98765 43210');
    expect(saved['businessLocation'], 'AB');
    expect(saved['businessAddress'], 'AB');
    // The selection is now persisted alongside them, without duplicates.
    expect(savedCrops(), SellerProfileStore.defaultCrops);
    expect(
      savedCrops()!.toSet(),
      hasLength(savedCrops()!.length),
    );

    // And it survives a relaunch of the store.
    final SellerProfileStore relaunched = SellerProfileStore();
    await relaunched.attachStorage(storage);
    expect(relaunched.crops, SellerProfileStore.defaultCrops);
    expect(relaunched.businessName, 'Legacy Organic Farm');
    expect(relaunched.farmSize, '3');
  });
}
