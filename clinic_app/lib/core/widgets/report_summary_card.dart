import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';

class ReportSummaryCard extends StatelessWidget {
  final String label;
  final dynamic value;
  final IconData icon;

  const ReportSummaryCard(
      {super.key,
      required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final display = value is num && label.toLowerCase().contains('revenue') ||
            label.toLowerCase().contains('sales') ||
            label.toLowerCase().contains('amount')
        ? Helpers.formatCurrency(value as num?)
        : value is num
            ? Helpers.formatNumber(value as num?)
            : '${value ?? '-'}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: AppColors.primarySurface,
            child: Icon(icon, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Text(display,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ])),
      ]),
    );
  }
}
