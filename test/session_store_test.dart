import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/app_storage.dart';
import 'package:seller_app/data/session_store.dart';

import 'support/fake_key_value_store.dart';

/// The session is what decides, on every cold start, whether the app opens on
/// the Welcome screen or continues into the app — so it has to survive the
/// relaunch, and it has to disappear on logout.
void main() {
  late FakeKeyValueStore storage;

  /// Stands in for killing and reopening the app: a brand-new store reading
  /// the same persistent storage.
  Future<SessionStore> relaunch() async {
    final SessionStore store = SessionStore();
    await store.attachStorage(storage);
    return store;
  }

  setUp(() {
    storage = FakeKeyValueStore();
  });

  test('a login session is restored on the next launch, uid included',
      () async {
    final SessionStore store = await relaunch();
    store.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
      uid: 'firebase-uid-1',
    );

    final SessionStore restored = await relaunch();
    expect(restored.isAuthenticated, isTrue);
    expect(restored.phone, '+91 98765 43210');
    expect(restored.userName, 'Ravi Kumar');
    expect(restored.method, SessionStore.loginMethod);
    expect(restored.uid, 'firebase-uid-1');
  });

  test('a sign-up session is restored without a Firebase uid', () async {
    final SessionStore store = await relaunch();
    store.startSession(
      phone: '',
      userName: 'Meena',
      method: SessionStore.signupMethod,
    );

    final SessionStore restored = await relaunch();
    expect(restored.isAuthenticated, isTrue);
    expect(restored.method, SessionStore.signupMethod);
    expect(restored.uid, '');
  });

  test('refreshing a session keeps the uid that is already recorded', () async {
    final SessionStore store = await relaunch();
    store.startSession(
      phone: '+91 98765 43210',
      userName: '',
      method: SessionStore.loginMethod,
      uid: 'firebase-uid-1',
    );
    // The OTP flow re-opens the session once the Supabase row is known, and
    // the sign-up form never passes a uid — neither may drop the id.
    store.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
    );

    expect((await relaunch()).uid, 'firebase-uid-1');
  });

  test('endSession removes the record so the next launch is signed out',
      () async {
    final SessionStore store = await relaunch();
    store.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
      uid: 'firebase-uid-1',
    );
    store.endSession();

    final SessionStore restored = await relaunch();
    expect(restored.isAuthenticated, isFalse);
    expect(restored.uid, '');
    expect(restored.phone, '');
    expect(storage.values.containsKey(StorageKeys.sessionKey), isFalse);
  });

  test('a corrupt session record is treated as signed out', () async {
    storage.values[StorageKeys.sessionKey] = 'not-json';

    final SessionStore restored = await relaunch();
    expect(restored.isAuthenticated, isFalse);
  });
}
