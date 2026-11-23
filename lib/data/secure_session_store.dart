import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_storage.dart';

/// The four keystore operations [SecureSessionStore] needs, behind an
/// interface so tests can exercise the store and the legacy migration
/// without a platform channel.
abstract class SecureKeyValueBackend {
  Future<Map<String, String>> readAll();

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// [SecureKeyValueBackend] backed by `flutter_secure_storage`: Windows DPAPI,
/// Android Keystore, iOS/macOS Keychain, Linux libsecret.
class PlatformSecureBackend implements SecureKeyValueBackend {
  PlatformSecureBackend([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// [KeyValueStore] backed by the platform keystore.
///
/// Only the authentication session ([StorageKeys.sessionKey]) lives here —
/// the record that decides whether the app opens on Home or on Welcome, so
/// it must not sit in a plain preferences file. Everything else (profile,
/// products, onboarding flags, the splash flag) stays on [AppStorage]: it is
/// business data, not a credential, and the splash flag has to be readable
/// before anything else exists to read.
///
/// [KeyValueStore] reads are synchronous, so [hydrate] runs once at boot —
/// before `runApp` — to fill the in-memory [_cache] that [readString]
/// serves. Every write updates the cache first and the keystore second, so a
/// slow or failing platform channel can never make a just-opened session
/// invisible to the very first build.
class SecureSessionStore implements KeyValueStore {
  SecureSessionStore({SecureKeyValueBackend? backend})
      : _backend = backend ?? PlatformSecureBackend();

  final SecureKeyValueBackend _backend;

  /// Synchronous view of the stored values, filled by [hydrate].
  final Map<String, String> _cache = <String, String>{};

  /// Reads the whole keystore into [_cache]. Throws when the platform
  /// channel is unavailable; callers fall back to [AppStorage] so a keystore
  /// failure can never lock the seller out of their own app.
  Future<void> hydrate() async {
    final Map<String, String> values = await _backend.readAll();
    _cache
      ..clear()
      ..addAll(values);
  }

  @override
  String? readString(String key) => _cache[key];

  @override
  Future<bool> writeString(String key, String value) async {
    _cache[key] = value;
    try {
      await _backend.write(key, value);
      // Read back: a write the platform silently dropped must be visible to
      // the caller, because the caller (the legacy-session migration) uses
      // this result to decide whether the plaintext copy may be deleted.
      final String? stored = await _backend.read(key);
      if (stored != value) {
        debugPrint('[SecureSessionStore] write of "$key" did not stick.');
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('[SecureSessionStore] write of "$key" failed: $error');
      return false;
    }
  }

  @override
  Future<bool> remove(String key) async {
    _cache.remove(key);
    try {
      await _backend.delete(key);
      return true;
    } catch (error) {
      debugPrint('[SecureSessionStore] remove of "$key" failed: $error');
      return false;
    }
  }
}

/// Opens the storage the session record should live in, moving the legacy
/// plaintext record out of [prefs] on the first boot after this build.
///
/// Returns [prefs] itself when the keystore is unavailable — the session then
/// keeps working exactly as before, just without the extra protection, and a
/// message is logged so the reason is never invisible.
///
/// The plaintext record is only deleted once a copy is confirmed inside the
/// keystore (or was already there): losing a live session on upgrade would
/// log the seller out of an app they never logged out of, which is the exact
/// bug this storage exists to prevent.
Future<KeyValueStore> openSessionStorage(
  AppStorage prefs, {
  SecureSessionStore? sessionStore,
}) async {
  final SecureSessionStore secure = sessionStore ?? SecureSessionStore();
  try {
    await secure.hydrate();
  } catch (error) {
    debugPrint(
      '[SecureSessionStore] keystore unavailable, session stays in '
      'SharedPreferences: $error',
    );
    return prefs;
  }

  const String key = StorageKeys.sessionKey;
  final String? legacy = prefs.readString(key);
  final String? alreadySecure = secure.readString(key);

  if (alreadySecure != null && alreadySecure.isNotEmpty) {
    // Migration already happened on an earlier boot. A plaintext copy that
    // survived is stale by definition — the keystore wins.
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.remove(key);
    }
    return secure;
  }

  if (legacy == null || legacy.isEmpty) {
    return secure;
  }

  final bool moved = await secure.writeString(key, legacy);
  if (moved) {
    await prefs.remove(key);
    debugPrint('[SecureSessionStore] migrated the session into the keystore.');
  } else {
    // Keep the plaintext copy: two copies beat a signed-out seller.
    debugPrint(
      '[SecureSessionStore] could not migrate the session; keeping the '
      'SharedPreferences copy as a fallback.',
    );
    return prefs;
  }
  return secure;
}
