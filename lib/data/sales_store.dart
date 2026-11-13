import 'package:flutter/foundation.dart';

/// Time period the Sales Overview card shows data for.
enum SalesPeriod { week, month, year }

extension SalesPeriodLabel on SalesPeriod {
  String get chipLabel {
    switch (this) {
      case SalesPeriod.week:
        return 'This Week';
      case SalesPeriod.month:
        return 'This Month';
      case SalesPeriod.year:
        return 'This Year';
    }
  }

  String get totalSalesLabel {
    switch (this) {
      case SalesPeriod.week:
        return 'Total sales this week';
      case SalesPeriod.month:
        return 'Total sales this month';
      case SalesPeriod.year:
        return 'Total sales this year';
    }
  }
}

/// One completed (or in-progress) sale, recorded when a buyer finishes
/// buying a product (order pickup success).
class SaleRecord {
  const SaleRecord({
    required this.amount,
    required this.itemsCount,
    required this.orderId,
    required this.dateTime,
    this.completed = true,
  });

  final double amount;
  final int itemsCount;
  final String orderId;
  final DateTime dateTime;
  final bool completed;
}

class SalesStore extends ChangeNotifier {
  SalesStore();

  static final SalesStore instance = SalesStore();

  SalesPeriod _period = SalesPeriod.month;
  final List<SaleRecord> _sales = <SaleRecord>[];

  SalesPeriod get period => _period;

  set period(SalesPeriod value) {
    if (_period == value) return;
    _period = value;
    notifyListeners();
  }

  /// Records a sale. Deduplicates by [orderId] so replaying the same
  /// order-completion screen never double counts.
  void recordSale({
    required double amount,
    required int itemsCount,
    required String orderId,
    required DateTime dateTime,
    bool completed = true,
  }) {
    if (_sales.any((SaleRecord s) => s.orderId == orderId)) return;
    _sales.add(
      SaleRecord(
        amount: amount,
        itemsCount: itemsCount,
        orderId: orderId,
        dateTime: dateTime,
        completed: completed,
      ),
    );
    notifyListeners();
  }

  /// Sales that fall inside the currently selected period.
  List<SaleRecord> get _filtered {
    final DateTime now = DateTime.now();
    switch (_period) {
      case SalesPeriod.week:
        final DateTime weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        return _sales
            .where((SaleRecord s) => !s.dateTime.isBefore(weekStart))
            .toList();
      case SalesPeriod.month:
        return _sales
            .where((SaleRecord s) =>
                s.dateTime.year == now.year && s.dateTime.month == now.month)
            .toList();
      case SalesPeriod.year:
        return _sales
            .where((SaleRecord s) => s.dateTime.year == now.year)
            .toList();
    }
  }

  double get totalSales =>
      _filtered.fold<double>(0, (double sum, SaleRecord s) => sum + s.amount);

  String get totalSalesLabel => _period.totalSalesLabel;

  int get orders => _filtered.length;

  int get complete => _filtered.where((SaleRecord s) => s.completed).length;

  int get progressCount => orders - complete;

  /// Completion percentage (0-100); 0 when there are no orders yet.
  int get progress =>
      orders == 0 ? 0 : ((complete / orders) * 100).round();
}
