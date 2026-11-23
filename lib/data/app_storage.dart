
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

  /// JSON `location/profile/bank/verification/personal` booleans recording
  /// which onboarding sections this device has already finished.
  ///
  /// Kept apart from [sessionKey] because it is business data, not session
  /// state — but it is what lets a sign-up session resume at the first
  /// incomplete step after a relaunch, when there is no Firebase UID to read
  /// the same answer back from Supabase.
  static const String onboardingKey = 'onboarding_progress';

  /// Selected UI language code (en, ta, hi, ...). Not session data, so it
  /// survives logout and splash re-display.
  static const String languageKey = 'language';

  /// Set once the one-time splash screen has been dismissed. Uninstalling
  /// the app clears the preferences, so a fresh install shows the splash
  /// exactly once again.
  static const String splashSeenKey = 'splash_seen';

  /// Cached country code from GeoIP/GPS cascade (ISO 3166-1 alpha-2).
  /// Used to determine currency for price formatting.
  static const String geoCountryKey = 'geo_country';

  /// JSON `{label, address}` marker for a location confirmed on the map
  /// page whose Supabase write failed (offline). Splash retries it on the
  /// next login and clears it once the write succeeds.
  static const String pendingLocationKey = 'pending_location';

  /// Locally saved seller avatar. While the remote (Cloudinary + Supabase)
  /// upload is temporarily disabled the picked photo is encoded as a base64
  /// data URI and kept here so it survives app restarts.
  static const String avatarKey = 'seller_avatar';
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
