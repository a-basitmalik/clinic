import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';
import 'premium_surface.dart';

class ReportSummaryCard extends StatelessWidget {
  final String label;
  final dynamic value;
  final IconData icon;
  final Color? color;

  const ReportSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final lbl = label.toLowerCase();
    final display = (value is num &&
                (lbl.contains('revenue') ||
                    lbl.contains('sales') ||
                    lbl.contains('amount') ||
                    lbl.contains('earning') ||
                    lbl.contains('collected')))
        ? Helpers.formatCurrency(value as num?)
        : value is num
            ? Helpers.formatNumber(value as num?)
            : '${value ?? '–'}';

    return ColoredGlassCard(
      color: c,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.withValues(alpha: .22), c.withValues(alpha: .09)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: c.withValues(alpha: .30), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: .20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [c, c.withValues(alpha: .70)],
                  ).createShader(b),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    display,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
