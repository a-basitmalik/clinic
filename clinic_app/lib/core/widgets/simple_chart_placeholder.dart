import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SimpleChartPlaceholder extends StatelessWidget {
  final String title;
  final List rows;

  const SimpleChartPlaceholder(
      {super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const Text('No chart data.',
              style: TextStyle(color: AppColors.textSecondary))
        else
          ...rows.take(8).map((r) {
            final map = r is Map ? r : {'label': '$r', 'value': 0};
            final label =
                '${map['label'] ?? map['date'] ?? map['name'] ?? map['doctor_name'] ?? map['payment_method'] ?? map['status'] ?? 'Item'}';
            final value = map['value'] ??
                map['total'] ??
                map['count'] ??
                map['amount'] ??
                '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 12),
                Text('$value',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            );
          }),
      ]),
    );
  }
}
