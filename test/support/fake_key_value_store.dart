import 'package:seller_app/data/app_storage.dart';

/// In-memory [KeyValueStore] so persistence can be exercised in a test
/// without a platform channel (SharedPreferences needs a mock otherwise).
///
/// Writes land in [values] before the returned future completes, so a store
/// that fires-and-forgets its writes still leaves the record behind by the
/// time the next assertion (or the next "relaunch") reads it.
class FakeKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  String? readString(String key) => values[key];

  @override
  Future<bool> writeString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}
