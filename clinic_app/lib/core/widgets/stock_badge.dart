import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StockBadge extends StatelessWidget {
  final int quantity;
  final int lowStockLimit;

  const StockBadge({
    super.key,
    required this.quantity,
    required this.lowStockLimit,
  });

  @override
  Widget build(BuildContext context) {
    final low = quantity <= lowStockLimit;
    final color = low ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        low ? 'Low: $quantity' : 'Stock: $quantity',
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
