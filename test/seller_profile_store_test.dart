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
}
