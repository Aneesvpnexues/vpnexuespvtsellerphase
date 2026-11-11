import 'translations/ar.dart';
import 'translations/hi.dart';
import 'translations/ml.dart';
import 'translations/si.dart';
import 'translations/ta.dart';
import 'translations/ur.dart';
import 'translations/zh.dart';

/// Every supported language's string table, keyed by ISO code.
///
/// Keys are the exact English strings used in the UI, so screens can simply
/// wrap their text in `LocalizedText` without inventing key names. Missing
/// entries fall back to the English key.
const Map<String, Map<String, String>> translations = <String, Map<String, String>>{
  'ta': taTranslations,
  'hi': hiTranslations,
  'si': siTranslations,
  'ar': arTranslations,
  'zh': zhTranslations,
  'ur': urTranslations,
  'ml': mlTranslations,
};
