class RevenueModel {
  final double total;
  final double today;
  final double thisMonth;
  final double thisYear;
  final List<Map<String, dynamic>> breakdown;
  final List<Map<String, dynamic>> recentTransactions;

  const RevenueModel({
    required this.total,
    required this.today,
    required this.thisMonth,
    required this.thisYear,
    required this.breakdown,
    required this.recentTransactions,
  });

  factory RevenueModel.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> parseList(dynamic d) {
      if (d == null) return [];
      if (d is List) return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return [];
    }

    return RevenueModel(
      total:               (j['total']       as num?)?.toDouble() ?? 0,
      today:               (j['today']       as num?)?.toDouble() ?? 0,
      thisMonth:           (j['this_month']  as num?)?.toDouble() ?? 0,
      thisYear:            (j['this_year']   as num?)?.toDouble() ?? 0,
      breakdown:           parseList(j['breakdown']),
      recentTransactions:  parseList(j['recent_transactions'] ?? j['recent_payments']),
    );
  }
}
