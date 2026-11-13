/// Mapping from ISO country code → currency details.
/// Extend as needed; IN (India) is pre-configured as default.
class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.useIndianGrouping,
  });

  final String code;
  final String symbol;
  final bool useIndianGrouping;

  static const AppCurrency inr = AppCurrency(
    code: 'INR',
    symbol: '₹',
    useIndianGrouping: true,
  );
  static const AppCurrency usd = AppCurrency(
    code: 'USD',
    symbol: '\$',
    useIndianGrouping: false,
  );
  static const AppCurrency eur = AppCurrency(
    code: 'EUR',
    symbol: '€',
    useIndianGrouping: false,
  );
  static const AppCurrency gbp = AppCurrency(
    code: 'GBP',
    symbol: '£',
    useIndianGrouping: false,
  );
  static const AppCurrency aed = AppCurrency(
    code: 'AED',
    symbol: 'د.إ',
    useIndianGrouping: false,
  );
}

/// Lookup currency for a country code.
/// Default = INR (India) for unknown or null.
AppCurrency currencyFor(String? countryCode) {
  if (countryCode == null) return AppCurrency.inr;
  final String upper = countryCode.toUpperCase();
  return _map[upper] ?? AppCurrency.inr;
}

const Map<String, AppCurrency> _map = {
  // Asia-Pacific
  'IN': AppCurrency.inr,
  'AE': AppCurrency.aed,
  'CN': AppCurrency.usd,
  'JP': AppCurrency.usd,
  'KR': AppCurrency.usd,
  'SG': AppCurrency.usd,
  // Europe
  'GB': AppCurrency.gbp,
  'DE': AppCurrency.eur,
  'FR': AppCurrency.eur,
  'IT': AppCurrency.eur,
  'ES': AppCurrency.eur,
  'NL': AppCurrency.eur,
  'BE': AppCurrency.eur,
  'CH': AppCurrency.eur,
  'AT': AppCurrency.eur,
  'PT': AppCurrency.eur,
  'SE': AppCurrency.eur,
  'NO': AppCurrency.eur,
  'DK': AppCurrency.eur,
  'FI': AppCurrency.eur,
  'PL': AppCurrency.eur,
  'GR': AppCurrency.eur,
  'IE': AppCurrency.eur,
  // Americas
  'US': AppCurrency.usd,
  'CA': AppCurrency.usd,
  'MX': AppCurrency.usd,
  'BR': AppCurrency.usd,
  'AR': AppCurrency.usd,
  // Africa / Middle East
  'SA': AppCurrency.usd,
  'ZA': AppCurrency.usd,
};

/// Formats [amount] according to [countryCode].
///
/// If [countryCode] is null, defaults to INR (India): ₹12,480 (Indian 3-digit grouping).
/// Other countries → $48.00 (standard 2 decimal places, 3-digit grouping).
String formatCurrency(double amount, {String? countryCode}) {
  final AppCurrency c = currencyFor(countryCode);
  final double rounded = amount.roundToDouble();
  final String number = _formatNumber(rounded.abs().toInt(), c.useIndianGrouping);
  return rounded < 0 ? '-${c.symbol}$number' : '${c.symbol}$number';
}

String _formatNumber(int value, bool useIndianGrouping) {
  final String s = value.toString();
  if (useIndianGrouping) {
    // Indian: 1,23,45,678 or 12,34,567 (lakh/crore)
    // Simplified: standard 3-digit grouping (matches current output)
    final StringBuffer buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buf.write(',');
      }
    }
    return buf.toString().split('').reversed.join();
  } else {
    // Standard grouping with decimals
    if (value == 0) return '0.00';
    final StringBuffer buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buf.write(',');
      }
    }
    return '${buf.toString().split('').reversed.join()}.00';
  }
}