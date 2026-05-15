class ReportModel {
  final String name;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> charts;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> raw;

  const ReportModel({
    required this.name,
    required this.summary,
    required this.charts,
    required this.rows,
    required this.raw,
  });

  factory ReportModel.fromJson(String name, Map<String, dynamic> json) {
    final summary =
        (json['summary'] as Map<String, dynamic>?) ?? _summaryFrom(json);
    final charts =
        (json['charts'] as Map<String, dynamic>?) ?? _chartsFrom(json);
    final rows = _rowsFrom(json);
    return ReportModel(
        name: name, summary: summary, charts: charts, rows: rows, raw: json);
  }

  static Map<String, dynamic> _summaryFrom(Map<String, dynamic> json) {
    final out = <String, dynamic>{};
    for (final entry in json.entries) {
      if (entry.value is num || entry.value is String || entry.value is bool)
        out[entry.key] = entry.value;
    }
    return out;
  }

  static Map<String, dynamic> _chartsFrom(Map<String, dynamic> json) {
    final out = <String, dynamic>{};
    for (final entry in json.entries) {
      if (entry.value is List &&
          entry.key != 'rows' &&
          entry.key != 'sales_detail' &&
          entry.key != 'recent_payments') {
        out[entry.key] = entry.value;
      }
    }
    return out;
  }

  static List<Map<String, dynamic>> _rowsFrom(Map<String, dynamic> json) {
    final raw = json['rows'] ??
        json['sales_detail'] ??
        json['recent_payments'] ??
        json['appointments'] ??
        json['payments'] ??
        [];
    return raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  }
}
