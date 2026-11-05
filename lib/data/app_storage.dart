import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage key constants.
///
/// Session state ([StorageKeys.sessionKey]) is kept strictly separate from the
/// saved business data (profile, products, registered accounts), so logging
/// out — which only removes the session key — never touches seller data.
abstract final class StorageKeys {
  static const String sessionKey = 'session';
  static const String registeredUsersKey = 'registered_users';
  static const String sellerProfileKey = 'seller_profile';
  static const String productsKey = 'products';

  /// Set once the one-time splash screen has been dismissed. Uninstalling
  /// the app clears the preferences, so a fresh install shows the splash
  /// exactly once again.
  static const String splashSeenKey = 'splash_seen';
}

/// Minimal synchronous-read / async-write key-value surface the stores
/// persist through.
///
/// Reads are synchronous (the SharedPreferences cache is in memory after
/// [AppStorage.create]), so screens never need to await hydration. Writes
/// return a future the stores fire-and-forget with an error guard.
///
/// Tests can implement this with an in-memory fake, so no platform channels
/// are needed to exercise persistence.
abstract class KeyValueStore {
  String? readString(String key);

  Future<bool> writeString(String key, String value);

  Future<bool> remove(String key);
}

/// [KeyValueStore] backed by `shared_preferences`.
class AppStorage implements KeyValueStore {
  AppStorage._(this._prefs);

  final SharedPreferences _prefs;

  /// The storage instance created at boot, so screens and the initial-route
  /// logic can reach the hydrated preferences synchronously. `null` before
  /// [create] succeeds (e.g. in tests without a platform channel).
  static AppStorage? _current;

  static AppStorage? get current => _current;

  /// Overridable for tests that need to clear the boot-time instance.
  @visibleForTesting
  static set current(AppStorage? storage) => _current = storage;

  /// Loads the platform preferences once at boot. Throws if the platform
  /// channel is unavailable (e.g. a test without a mock); callers treat that
  /// as "run in-memory".
  static Future<AppStorage> create() async {
    final AppStorage storage =
        AppStorage._(await SharedPreferences.getInstance());
    _current = storage;
    return storage;
  }

  @override
  String? readString(String key) => _prefs.getString(key);

  @override
  Future<bool> writeString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<bool> remove(String key) => _prefs.remove(key);
}
