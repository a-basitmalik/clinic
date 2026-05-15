import 'package:flutter/material.dart';
import '../../models/dashboard_stat_model.dart';
import '../constants/app_colors.dart';

class DashboardCard extends StatelessWidget {
  final DashboardStat stat;

  const DashboardCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 22),
              ),
              if (stat.trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (stat.trendUp ? AppColors.success : AppColors.danger)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stat.trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color:
                            stat.trendUp ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        stat.trend!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: stat.trendUp
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.title,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (stat.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              stat.subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ],
      ),
    );
  }
}
