import 'package:flutter/widgets.dart';

/// The languages the seller app ships with.
///
/// [codes] are the two-letter locale codes used as translation-table keys;
/// [nativeNames] are the display names shown on the Language screen (each
/// language names itself, so the list never changes when the UI language
/// changes); [supportedLocales] feeds `MaterialApp.supportedLocales`.
abstract final class AppLanguages {
  static const String english = 'en';

  static const List<String> codes = <String>[
    'en',
    'ta',
    'hi',
    'si',
    'ar',
    'zh',
    'ur',
    'ml',
  ];

  static const Map<String, String> nativeNames = <String, String>{
    'en': 'English',
    'ta': 'தமிழ்',
    'hi': 'हिंदी',
    'si': 'සිංහල',
    'ar': 'العربية',
    'zh': '简体中文',
    'ur': 'اردو',
    'ml': 'മലയാളം',
  };

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
    Locale('hi'),
    Locale('si'),
    Locale('ar'),
    Locale('zh'),
    Locale('ur'),
    Locale('ml'),
  ];
}
