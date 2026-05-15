import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';

class ExpiryBadge extends StatelessWidget {
  final String? expiryDate;

  const ExpiryBadge({super.key, required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final date = expiryDate == null ? null : DateTime.tryParse(expiryDate!);
    final now = DateTime.now();
    final expired =
        date != null && date.isBefore(DateTime(now.year, now.month, now.day));
    final expiring =
        date != null && !expired && date.difference(now).inDays <= 30;
    final color = expired
        ? AppColors.danger
        : expiring
            ? AppColors.warning
            : AppColors.info;
    final label = expired
        ? 'Expired'
        : expiring
            ? 'Expiring'
            : Helpers.formatDate(expiryDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
