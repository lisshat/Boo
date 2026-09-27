class EarningsPeriodComparison {
  const EarningsPeriodComparison({
    required this.currentPeriod,
    required this.currentTotal,
    required this.previousPeriod,
    required this.previousTotal,
  });

  final String currentPeriod;
  final double currentTotal;
  final String previousPeriod;
  final double previousTotal;

  double get change => currentTotal - previousTotal;
}

class AdvancedEarningsInsights {
  const AdvancedEarningsInsights({
    required this.recordedEarnings,
    required this.completedPaidServices,
    required this.averageRecordedEarning,
    required this.byCategory,
    required this.byMonth,
    required this.currency,
    required this.comparison,
  });

  final double? recordedEarnings;
  final int completedPaidServices;
  final double? averageRecordedEarning;
  final List<MapEntry<String, double>> byCategory;
  final List<MapEntry<String, double>> byMonth;
  final String? currency;
  final EarningsPeriodComparison? comparison;

  bool get hasData =>
      completedPaidServices > 0 || byCategory.isNotEmpty || byMonth.isNotEmpty;
}

/// Converts the existing provider earnings response into displayable insights.
/// The endpoint already limits the source rows to completed/accepted/pending
/// bookings and calculates recorded totals only from provider-recorded payments.
class AdvancedEarningsCalculator {
  const AdvancedEarningsCalculator();

  AdvancedEarningsInsights calculate(Map<String, dynamic> data) {
    final summary = _map(data['summary']);
    final completed = _number(summary['completedCount']).toInt();
    final unrecorded = _number(summary['completedUnrecordedCount']).toInt();
    final paidCount = (completed - unrecorded).clamp(0, completed).toInt();
    final categories = _entries(data['byCategory'], 'category');
    final months = _entries(data['byMonth'], 'month');
    final currencies = _recordedCurrencies(data['recentBookings']);
    final currency = currencies.length == 1 ? currencies.first : null;
    final compatible = currencies.length <= 1 && currency != null;
    final parsedTotal = _nullableNumber(summary['totalEarnings']);
    final total = compatible ? parsedTotal : null;
    final average = total != null && paidCount > 0 ? total / paidCount : null;

    return AdvancedEarningsInsights(
      recordedEarnings: total,
      completedPaidServices: paidCount,
      averageRecordedEarning: average,
      byCategory: compatible ? categories : const [],
      byMonth: compatible ? months : const [],
      currency: currency,
      comparison: compatible ? _comparison(months) : null,
    );
  }

  Set<String> _recordedCurrencies(dynamic raw) {
    final currencies = <String>{};
    if (raw is! List) return currencies;
    for (final item in raw) {
      if (item is! Map) continue;
      if (item['status']?.toString().toLowerCase() != 'completed') continue;
      final payment = item['paymentStatus']?.toString().toLowerCase() ?? '';
      if (!payment.contains('recorded') || !payment.contains('received')) {
        continue;
      }
      final code = item['currency']?.toString().trim().toUpperCase();
      if (code != null && code.isNotEmpty) currencies.add(code);
    }
    return currencies;
  }

  List<MapEntry<String, double>> _entries(dynamic raw, String key) {
    if (raw is! List) return const [];
    final values = <MapEntry<String, double>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final label = item[key]?.toString().trim();
      if (label == null || label.isEmpty) continue;
      final value = _number(item['total']);
      if (value.isFinite && value >= 0) values.add(MapEntry(label, value));
    }
    return values;
  }

  EarningsPeriodComparison? _comparison(List<MapEntry<String, double>> months) {
    if (months.length < 2) return null;
    final sorted = [...months]..sort((a, b) => a.key.compareTo(b.key));
    final current = sorted[sorted.length - 1];
    final previous = sorted[sorted.length - 2];
    return EarningsPeriodComparison(
      currentPeriod: current.key,
      currentTotal: current.value,
      previousPeriod: previous.key,
      previousTotal: previous.value,
    );
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : const {};

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  double? _nullableNumber(dynamic value) => value is num
      ? value.toDouble()
      : value == null
          ? null
          : double.tryParse('$value');
}

/// Keeps premium analytics display state separate from the backend data.
/// Results are accepted only for the current entitlement/account epoch.
class AdvancedEarningsSession {
  bool _allowed = false;
  int _epoch = 0;
  AdvancedEarningsInsights? _data;

  bool get allowed => _allowed;
  int get requestEpoch => _epoch;
  bool get canDisplay => _allowed && _data != null;

  void setAccess(bool allowed) {
    if (_allowed == allowed) return;
    _allowed = allowed;
    _epoch++;
    if (!allowed) _data = null;
  }

  bool accept(AdvancedEarningsInsights data, int requestEpoch) {
    if (!_allowed || requestEpoch != _epoch) return false;
    _data = data;
    return true;
  }

  void clear() {
    _allowed = false;
    _epoch++;
    _data = null;
  }
}
