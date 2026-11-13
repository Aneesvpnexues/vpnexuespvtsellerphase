import 'package:flutter/foundation.dart';

import 'supabase_product_api.dart';

/// Time period the Profile balance card / stats show data for.
enum WalletPeriod { week, month, year }

extension WalletPeriodLabel on WalletPeriod {
  /// Pill / stat-card label.
  String get chipLabel {
    switch (this) {
      case WalletPeriod.week:
        return 'This week';
      case WalletPeriod.month:
        return 'This month';
      case WalletPeriod.year:
        return 'This year';
    }
  }
}

/// In-memory wallet ledger backed by Supabase `seller_transactions`.
///
/// All-time getters (withdrawal balance, total earned) never depend on
/// [period]; period-scoped getters (periodEarned, periodOrders) follow the
/// selected [WalletPeriod] — same filter idea as [SalesStore].
class WalletStore extends ChangeNotifier {
  WalletStore();

  static final WalletStore instance = WalletStore();

  List<Map<String, dynamic>> _txns = const <Map<String, dynamic>>[];
  WalletPeriod _period = WalletPeriod.month;
  bool _loaded = false;
  bool _loading = false;

  List<Map<String, dynamic>> get txns => _txns;
  bool get loaded => _loaded;
  bool get loading => _loading;
  WalletPeriod get period => _period;

  set period(WalletPeriod value) {
    if (_period == value) return;
    _period = value;
    notifyListeners();
  }

  /// Fetches this seller's transactions from Supabase.
  ///
  /// Never throws — on failure keeps whatever was already loaded so the
  /// Profile screen stays usable offline.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final List<Map<String, dynamic>> rows =
          await SupabaseProductApi().fetchTransactions();
      _txns = rows;
      _loaded = true;
    } catch (_) {
      // Keep previous data; Profile shows zeros until a later refresh works.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clears the ledger on logout so the next seller never sees stale rows.
  void reset() {
    if (_txns.isEmpty && !_loaded) return;
    _txns = const <Map<String, dynamic>>[];
    _loaded = false;
    _loading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // All-time (never period-scoped)
  // ---------------------------------------------------------------------------

  /// Money currently withdrawable: lifetime credits − lifetime withdrawals.
  double get withdrawalBalance {
    double balance = 0;
    for (final Map<String, dynamic> txn in _txns) {
      final double amount = _amount(txn);
      balance += _isCredit(txn) ? amount : -amount;
    }
    return balance < 0 ? 0 : balance;
  }

  /// Lifetime earnings from credited orders.
  double get totalEarned {
    double sum = 0;
    for (final Map<String, dynamic> txn in _txns) {
      if (_isCredit(txn)) sum += _amount(txn);
    }
    return sum;
  }

  // ---------------------------------------------------------------------------
  // Period-scoped (follows [period])
  // ---------------------------------------------------------------------------

  double get periodEarned {
    double sum = 0;
    for (final Map<String, dynamic> txn in _periodTxns) {
      if (_isCredit(txn)) sum += _amount(txn);
    }
    return sum;
  }

  /// Number of credited orders inside the selected period.
  int get periodOrders => _periodTxns.where(_isCredit).length;

  // ---------------------------------------------------------------------------
  // Transactions list (WalletPage filters)
  // ---------------------------------------------------------------------------

  /// [filter]: 0 = all, 1 = credits, 2 = withdrawals. Newest first
  /// (server already orders by created_at desc).
  List<Map<String, dynamic>> transactionsFor(int filter) {
    switch (filter) {
      case 1:
        return _txns.where(_isCredit).toList(growable: false);
      case 2:
        return _txns.where((Map<String, dynamic> t) => !_isCredit(t)).toList(
          growable: false,
        );
      default:
        return _txns;
    }
  }

  /// Amount still expected from orders not yet credited to the ledger.
  /// The ledger only receives settled credits, so nothing is pending until
  /// an in-progress-order source exists. Callers hide the line at 0.
  double get pendingFromOrders => 0;

  List<Map<String, dynamic>> get _periodTxns {
    final DateTime now = DateTime.now();
    switch (_period) {
      case WalletPeriod.week:
        final DateTime weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        return _txns
            .where((Map<String, dynamic> t) => !_createdAt(t).isBefore(weekStart))
            .toList(growable: false);
      case WalletPeriod.month:
        return _txns
            .where(
              (Map<String, dynamic> t) =>
                  _createdAt(t).year == now.year &&
                  _createdAt(t).month == now.month,
            )
            .toList(growable: false);
      case WalletPeriod.year:
        return _txns
            .where((Map<String, dynamic> t) => _createdAt(t).year == now.year)
            .toList(growable: false);
    }
  }

  static bool _isCredit(Map<String, dynamic> txn) =>
      (txn['type'] ?? '').toString().trim() == 'credit';

  static double _amount(Map<String, dynamic> txn) {
    final Object? raw = txn['amount'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static DateTime _createdAt(Map<String, dynamic> txn) {
    final String raw = (txn['created_at'] ?? '').toString();
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
