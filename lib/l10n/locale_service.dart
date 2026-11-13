import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_languages.dart';

/// Holds the app's active locale and persists the seller's choice.
///
/// A single `ValueNotifier` so `main.dart` can rebuild `MaterialApp` on a
/// change while `SettingsScreen` rebuilds just its Language subtitle.
/// Persistence is best-effort: the UI switches first, the preference write
/// follows, and a missing plugin (widget tests) never surfaces as an error.
class LocaleService {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const String storageKey = 'app_language';

  final ValueNotifier<Locale> locale = ValueNotifier<Locale>(
    const Locale(AppLanguages.english),
  );

  /// Restores the saved language before the first frame. Call from `main()`.
  Future<void> hydrate() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? code = prefs.getString(storageKey);
      if (code != null && AppLanguages.codes.contains(code)) {
        locale.value = Locale(code);
      }
    } catch (_) {
      // No platform channel (tests) — keep the English default.
    }
  }

  /// Switches the whole app to [code] and persists it. Unknown codes are
  /// ignored. Safe to call from a synchronous tap handler.
  Future<void> apply(String code) async {
    if (!AppLanguages.codes.contains(code)) return;
    locale.value = Locale(code);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, code);
    } catch (_) {
      // Preference write is best-effort; the switch already happened.
    }
  }
}
