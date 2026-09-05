import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SimpleChartPlaceholder extends StatelessWidget {
  final String title;
  final List rows;

  const SimpleChartPlaceholder(
      {super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final values = rows.take(8).map((raw) {
      final map = raw is Map ? raw : {'label': '$raw', 'value': 0};
      final value = map['value'] ??
          map['total'] ??
          map['count'] ??
          map['amount'] ??
          map['revenue'] ??
          0;
      return (
        '${map['label'] ?? map['date'] ?? map['name'] ?? map['doctor_name'] ?? map['method'] ?? map['status'] ?? 'Item'}',
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0,
      );
    }).toList();
    final maxValue = values.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (values.isEmpty)
          const Text('No chart data.',
              style: TextStyle(color: AppColors.textSecondary))
        else
          ...values.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(entry.$1,
                                overflow: TextOverflow.ellipsis)),
                        Text('${entry.$2}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: maxValue <= 0 ? 0 : entry.$2 / maxValue,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ]),
              )),
      ]),
    );
  }
}
