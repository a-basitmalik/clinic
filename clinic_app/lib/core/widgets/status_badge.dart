import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge(this.status, {super.key, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status.toLowerCase());
    final label = _label(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: .25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: .2),
      ),
    );
  }

  (Color, Color) _colors(String s) {
    switch (s) {
      case 'approved':
      case 'active':
      case 'completed':
      case 'paid':
        return (AppColors.successSurface, AppColors.success);

      case 'pending':
      case 'unpaid':
      case 'waiting':
      case 'partial':
      case 'sent_to_assistant':
        return (AppColors.warningSurface, AppColors.warning);

      case 'suspended':
      case 'inactive':
      case 'cancelled':
        return (AppColors.dangerSurface, AppColors.danger);

      case 'in_consultation':
        return (AppColors.primarySurface, AppColors.primary);

      default:
        return (AppColors.surfaceMuted, AppColors.textSecondary);
    }
  }

  String _label(String s) {
    return s
        .split('_')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
