import 'package:flutter/material.dart';
import '../../models/medicine_model.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';
import 'expiry_badge.dart';
import 'stock_badge.dart';
import 'premium_surface.dart';

class MedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredGlassCard(
      color: AppColors.primary,
      radius: 20,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: .20),
                      AppColors.primaryLight.withValues(alpha: .08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: .28)),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.medicineName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      '${medicine.category ?? 'General'} • Batch ${medicine.batchNumber ?? '–'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                _ActionBtn(
                    icon: Icons.edit_rounded,
                    color: AppColors.info,
                    onTap: onEdit!),
              if (onDelete != null)
                _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    onTap: onDelete!),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StockBadge(
                quantity: medicine.quantity,
                lowStockLimit: medicine.lowStockLimit,
              ),
              ExpiryBadge(expiryDate: medicine.expiryDate),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: .25)),
                ),
                child: Text(
                  Helpers.formatCurrency(medicine.salePrice),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .20)),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
