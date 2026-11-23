import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/app_storage.dart';
import 'package:seller_app/data/seller_profile_store.dart';

import 'support/fake_key_value_store.dart';

/// Onboarding progress is what lets a sign-up session resume at the first
/// unfinished page after a relaunch instead of starting over (or being asked
/// to sign up again) — so it has to be persisted, and cleared on logout.
void main() {
  late FakeKeyValueStore storage;

  /// Stands in for killing and reopening the app: a brand-new store reading
  /// the same persistent storage.
  Future<SellerProfileStore> relaunch() async {
    final SellerProfileStore store = SellerProfileStore();
    await store.attachStorage(storage);
    return store;
  }

  setUp(() {
    storage = FakeKeyValueStore();
  });

  test('sections finished during onboarding are restored on the next launch',
      () async {
    final SellerProfileStore store = await relaunch();
    store.setLocationComplete(true);
    store.setCompletion(
      profileComplete: true,
      bankComplete: false,
      verificationComplete: true,
      personalComplete: true,
    );

    final SellerProfileStore restored = await relaunch();
    expect(restored.locationComplete, isTrue);
    expect(restored.profileComplete, isTrue);
    expect(restored.bankComplete, isFalse);
    expect(restored.verificationComplete, isTrue);
    expect(restored.personalComplete, isTrue);
  });

  test('a device with nothing saved starts with every section incomplete',
      () async {
    final SellerProfileStore restored = await relaunch();
    expect(restored.locationComplete, isFalse);
    expect(restored.profileComplete, isFalse);
    expect(restored.bankComplete, isFalse);
    expect(restored.verificationComplete, isFalse);
    expect(restored.personalComplete, isFalse);
  });

  test(
      'resetCompletionFlags clears memory only, so a failed Supabase refetch '
      'cannot wipe what the seller already finished', () async {
    final SellerProfileStore store = await relaunch();
    store.setLocationComplete(true);
    store.setCompletion(
      profileComplete: true,
      bankComplete: true,
      verificationComplete: true,
      personalComplete: true,
    );

    // What Splash does before it re-reads the sections from Supabase.
    store.resetCompletionFlags();
    expect(store.profileComplete, isFalse);

    final SellerProfileStore restored = await relaunch();
    expect(restored.locationComplete, isTrue);
    expect(restored.profileComplete, isTrue);
    expect(restored.bankComplete, isTrue);
    expect(restored.verificationComplete, isTrue);
    expect(restored.personalComplete, isTrue);
  });

  test('reset (logout) clears the saved record so nobody inherits it',
      () async {
    final SellerProfileStore store = await relaunch();
    store.setLocationComplete(true);
    store.setCompletion(
      profileComplete: true,
      bankComplete: true,
      verificationComplete: true,
      personalComplete: true,
    );

    store.reset();

    final SellerProfileStore restored = await relaunch();
    expect(restored.locationComplete, isFalse);
    expect(restored.profileComplete, isFalse);
    expect(restored.bankComplete, isFalse);
    expect(restored.verificationComplete, isFalse);
    expect(restored.personalComplete, isFalse);
    expect(storage.values.containsKey(StorageKeys.onboardingKey), isTrue);
  });

  // ------------------------------------------------------------------
  // BUG_SELLER_021 — "What you grow" crop persistence
  // ------------------------------------------------------------------

  /// The local profile record. The key is private to [SellerProfileStore],
  /// so these tests spell it out to prove a write really reached storage —
  /// never just the in-memory field.
  const String profileKey = 'seller_profile_local';

  test('a saved crop selection survives a relaunch with the business fields',
      () async {
    final SellerProfileStore store = await relaunch();
    store.saveBusinessDetails(
      name: 'Ramesh Kumar',
      business: 'Kumar Organic Farm',
      phone: '+91 12345 67890',
      location: 'Chennai',
      address: 'Chennai, Tamil Nadu',
      farmSize: '5',
      crops: <String>['Tomatoes', 'Carrots', 'Onions'],
    );

    // The write must actually land in storage, not only in memory.
    final String? raw = storage.values[profileKey];
    expect(raw, isNotNull);
    final Map<String, dynamic> saved =
        jsonDecode(raw!) as Map<String, dynamic>;
    expect(saved['crops'], <String>['Tomatoes', 'Carrots', 'Onions']);

    final SellerProfileStore restored = await relaunch();
    expect(restored.crops, <String>['Tomatoes', 'Carrots', 'Onions']);

    // The new field must not disturb the rest of the Business & Farm form.
    expect(restored.name, 'Ramesh Kumar');
    expect(restored.businessName, 'Kumar Organic Farm');
    expect(restored.mobile, '+91 12345 67890');
    expect(restored.businessLocation, 'Chennai');
    expect(restored.businessAddress, 'Chennai, Tamil Nadu');
    expect(restored.farmSize, '5');
  });

  test(
      'a profile saved before the crops field existed keeps the starter '
      'selection', () async {
    storage.values[profileKey] = jsonEncode(<String, Object?>{
      'name': 'Legacy Seller',
      'businessName': 'Legacy Farm',
      'farmSize': '2',
    });

    final SellerProfileStore restored = await relaunch();
    expect(restored.crops, SellerProfileStore.defaultCrops);

    // Existing data still loads next to the new field.
    expect(restored.businessName, 'Legacy Farm');
    expect(restored.farmSize, '2');
  });

  test('an explicitly empty crop selection restores as empty', () async {
    final SellerProfileStore store = await relaunch();
    store.saveBusinessDetails(
      name: store.name,
      business: store.businessName,
      phone: store.mobile,
      location: store.businessLocation,
      address: store.businessAddress,
      farmSize: '1',
      crops: const <String>[],
    );
    expect(store.crops, isEmpty);

    final SellerProfileStore restored = await relaunch();
    expect(restored.crops, isEmpty);
  });

  test('saving business details without crops never wipes the selection',
      () async {
    final SellerProfileStore store = await relaunch();
    store.setSelectedCrops(<String>['Potatoes']);

    // The Splash/OTP server refetch and onboarding Step 03 call this
    // without a crops argument.
    store.saveBusinessDetails(
      name: store.name,
      business: store.businessName,
      phone: store.mobile,
      location: store.businessLocation,
      address: store.businessAddress,
      farmSize: '7',
    );

    expect(store.crops, <String>['Potatoes']);
    final SellerProfileStore restored = await relaunch();
    expect(restored.crops, <String>['Potatoes']);
    expect(restored.farmSize, '7');
  });

  test('crop storage trims, drops blanks and removes case-insensitive '
      'duplicates', () async {
    final SellerProfileStore store = await relaunch();
    store.setSelectedCrops(
      <String>[' Onions ', 'onions', '', 'Carrots', 'ONIONS'],
    );

    expect(store.crops, <String>['Onions', 'Carrots']);
    final SellerProfileStore restored = await relaunch();
    expect(restored.crops, <String>['Onions', 'Carrots']);
  });

  test('reset (logout) restores the starter crop selection', () async {
    final SellerProfileStore store = await relaunch();
    store.setSelectedCrops(<String>['Potatoes']);

    store.reset();

    expect(store.crops, SellerProfileStore.defaultCrops);
    final SellerProfileStore restored = await relaunch();
    expect(restored.crops, SellerProfileStore.defaultCrops);
  });
}
