import 'package:flutter/widgets.dart';

import '../data/app_storage.dart';
import 'translations.dart';

/// The languages the Language screen offers. [code] matches the ISO code the
/// translation tables are keyed by, [nativeName] is what the row shows as its
/// title and [englishName] is the English label shown under it.
enum AppLanguage {
  english('en', 'English', 'English'),
  tamil('ta', 'தமிழ்', 'Tamil'),
  hindi('hi', 'हिंदी', 'Hindi'),
  sinhala('si', 'සිංහල', 'Sinhala'),
  arabic('ar', 'العربية', 'Arabic'),
  chinese('zh', '简体中文', 'Chinese'),
  urdu('ur', 'اردو', 'Urdu'),
  malayalam('ml', 'മലയാളം', 'Malayalam');

  const AppLanguage(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;

  static AppLanguage fromCode(String? code) => values.firstWhere(
    (AppLanguage language) => language.code == code,
    orElse: () => AppLanguage.english,
  );
}

/// Holds the active language for the whole app and persists the seller's
/// choice so it survives an app restart. Screens never talk to storage
/// directly: they call [setLanguage] and every [LocalizedText]/[LabelText]
/// rebuilds itself through [AppLanguageScope].
class LanguageController extends ChangeNotifier {
  LanguageController();

  static final LanguageController instance = LanguageController();

  AppLanguage _current = AppLanguage.english;
  AppLanguage get current => _current;

  KeyValueStore? _storage;
  bool _loadedFromStorage = false;

  /// Restores the saved language once at boot. Safe to call more than once:
  /// only the first call reads storage, later calls just keep the instance
  /// attached for writes.
  Future<void> attachStorage(KeyValueStore storage) async {
    _storage = storage;
    if (_loadedFromStorage) return;
    _loadedFromStorage = true;
    final String? raw = storage.readString(StorageKeys.languageKey);
    if (raw == null || raw.isEmpty) return;
    final AppLanguage restored = AppLanguage.fromCode(raw);
    if (restored != _current) {
      _current = restored;
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _current) return;
    _current = language;
    notifyListeners();
    await _storage?.writeString(StorageKeys.languageKey, language.code);
  }

  /// Looks [text] up in the active language's table, falling back to the
  /// original English string when no translation exists yet.
  String translate(String text) {
    if (text.isEmpty || _current == AppLanguage.english) return text;
    return translations[_current.code]?[text] ?? text;
  }
}

/// Makes the active [LanguageController] available to the widget tree. As an
/// [InheritedNotifier], every widget that calls [of] rebuilds automatically
/// when the language changes — including `const` widgets, which is why the
/// translated text widgets can stay const.
class AppLanguageScope extends InheritedNotifier<LanguageController> {
  const AppLanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Subscribes [context] to language changes and returns the controller.
  static LanguageController of(BuildContext context) {
    final AppLanguageScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    return scope?.notifier ?? LanguageController.instance;
  }

  /// Reads the controller without subscribing (for event handlers).
  static LanguageController read(BuildContext context) {
    final AppLanguageScope? scope = context
        .getElementForInheritedWidgetOfExactType<AppLanguageScope>()
        ?.widget as AppLanguageScope?;
    return scope?.notifier ?? LanguageController.instance;
  }
}

/// Translates [text] into the active language for [context].
String translateText(BuildContext context, String text) =>
    AppLanguageScope.of(context).translate(text);
