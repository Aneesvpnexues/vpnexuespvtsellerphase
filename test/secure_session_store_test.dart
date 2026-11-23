import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/app_storage.dart';
import 'package:seller_app/data/secure_session_store.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An in-memory stand-in for the platform keystore, so the migration and the
/// fallbacks can be exercised without a plugin channel.
class _FakeBackend implements SecureKeyValueBackend {
  _FakeBackend({Map<String, String>? seed}) : values = <String, String>{...?seed};

  final Map<String, String> values;

  /// When set, [readAll] throws — a platform channel that is simply not
  /// there (tests, or an OS where the keystore is unavailable).
  bool broken = false;

  /// When set, every write throws after the fact — the OS accepted nothing.
  bool refuseWrites = false;

  @override
  Future<Map<String, String>> readAll() async {
    if (broken) throw StateError('keystore unavailable');
    return Map<String, String>.from(values);
  }

  @override
  Future<String?> read(String key) async {
    if (broken) throw StateError('keystore unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (refuseWrites) throw StateError('keystore refused the write');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (broken) throw StateError('keystore unavailable');
    values.remove(key);
  }
}

/// Secure persistence of the session — the record that decides, on every cold
/// start, whether the app opens on Home or on Welcome.
///
/// Two properties are guarded here:
///  * the session ends up in the keystore, not in the plaintext preferences
///    file it used to live in;
///  * moving it there can never cost a signed-in seller their session — if
///    the keystore is missing or refuses the write, the old copy stays put.
void main() {
  const String json = '{"authenticated":true,"phone":"+91 98765 43210",'
      '"userName":"Ravi Kumar","method":"login","uid":"firebase-uid-1"}';

  /// A preferences file exactly as an older build left it: plaintext session.
  Future<AppStorage> legacyPrefs() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      StorageKeys.sessionKey: json,
    });
    return AppStorage.create();
  }

  /// Stands in for killing and reopening the app against the same keystore.
  Future<SessionStore> relaunch(KeyValueStore storage) async {
    final SessionStore store = SessionStore();
    await store.attachStorage(storage);
    return store;
  }

  test('the legacy plaintext session is moved into the keystore', () async {
    final AppStorage prefs = await legacyPrefs();
    final _FakeBackend backend = _FakeBackend();
    final SecureSessionStore secure = SecureSessionStore(backend: backend);

    final KeyValueStore chosen = await openSessionStorage(
      prefs,
      sessionStore: secure,
    );

    expect(chosen, same(secure));
    // Confirmed in the keystore…
    expect(backend.values[StorageKeys.sessionKey], json);
    expect(secure.readString(StorageKeys.sessionKey), json);
    // …so the plaintext copy may go.
    expect(prefs.readString(StorageKeys.sessionKey), isNull);

    // And the session itself is still the seller's session.
    final SessionStore restored = await relaunch(chosen);
    expect(restored.isAuthenticated, isTrue);
    expect(restored.uid, 'firebase-uid-1');
    expect(restored.method, SessionStore.loginMethod);
  });

  test(
      'a keystore that cannot be opened falls back to preferences instead of '
      'signing the seller out', () async {
    final AppStorage prefs = await legacyPrefs();
    final _FakeBackend backend = _FakeBackend()..broken = true;

    final KeyValueStore chosen = await openSessionStorage(
      prefs,
      sessionStore: SecureSessionStore(backend: backend),
    );

    expect(chosen, same(prefs));
    expect(prefs.readString(StorageKeys.sessionKey), json);

    final SessionStore restored = await relaunch(chosen);
    expect(restored.isAuthenticated, isTrue);
    expect(restored.uid, 'firebase-uid-1');
  });

  test(
      'a write the keystore refuses keeps the plaintext copy — two copies beat '
      'a signed-out seller', () async {
    final AppStorage prefs = await legacyPrefs();
    final _FakeBackend backend = _FakeBackend()..refuseWrites = true;

    final KeyValueStore chosen = await openSessionStorage(
      prefs,
      sessionStore: SecureSessionStore(backend: backend),
    );

    expect(chosen, same(prefs));
    expect(prefs.readString(StorageKeys.sessionKey), json);

    final SessionStore restored = await relaunch(chosen);
    expect(restored.isAuthenticated, isTrue);
  });

  test('a stale plaintext copy is dropped once the keystore has the session',
      () async {
    final AppStorage prefs = await legacyPrefs();
    final _FakeBackend backend = _FakeBackend();
    await backend.write(StorageKeys.sessionKey, json);

    final KeyValueStore chosen = await openSessionStorage(
      prefs,
      sessionStore: SecureSessionStore(backend: backend),
    );

    expect(chosen, isA<SecureSessionStore>());
    expect(prefs.readString(StorageKeys.sessionKey), isNull);
    expect(chosen.readString(StorageKeys.sessionKey), json);
  });

  test('a session opened while secure storage is live survives a relaunch',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppStorage prefs = await AppStorage.create();
    final _FakeBackend backend = _FakeBackend();
    final SecureSessionStore secureStore = SecureSessionStore(backend: backend);
    await secureStore.hydrate();

    final SessionStore store = await relaunch(secureStore);
    store.startSession(
      phone: '+91 98765 43210',
      userName: 'Ravi Kumar',
      method: SessionStore.loginMethod,
      uid: 'firebase-uid-1',
    );
    // The record lands in the keystore (and the cache) before its future even
    // completes, so the very first build after this one can read it.
    expect(secureStore.readString(StorageKeys.sessionKey), contains('firebase-uid-1'));
    await Future<void>.delayed(Duration.zero);
    expect(backend.values[StorageKeys.sessionKey], contains('firebase-uid-1'));
    // Nothing may be left in plaintext.
    expect(prefs.readString(StorageKeys.sessionKey), isNull);

    final SessionStore restored = await relaunch(secureStore);
    expect(restored.isAuthenticated, isTrue);
    expect(restored.uid, 'firebase-uid-1');

    // Logout clears the keystore record, so the next launch is Welcome.
    restored.endSession();
    expect(secureStore.readString(StorageKeys.sessionKey), isNull);
    await Future<void>.delayed(Duration.zero);
    expect(backend.values.containsKey(StorageKeys.sessionKey), isFalse);
    expect((await relaunch(secureStore)).isAuthenticated, isFalse);
  });
}
