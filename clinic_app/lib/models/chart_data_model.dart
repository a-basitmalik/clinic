class ChartDataModel {
  final List<String> labels;
  final List<num> values;

  const ChartDataModel({required this.labels, required this.values});

  factory ChartDataModel.fromRows(List rows,
      {String labelKey = 'label', String valueKey = 'value'}) {
    return ChartDataModel(
      labels: rows
          .map((e) => e is Map
              ? '${e[labelKey] ?? e['date'] ?? e['name'] ?? e['type'] ?? ''}'
              : '$e')
          .toList(),
      values: rows
          .map((e) => e is Map && e[valueKey] is num ? e[valueKey] as num : 0)
          .toList(),
    );
  }
}
