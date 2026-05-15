import 'package:flutter/material.dart';
import '../../models/medicine_model.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';
import 'expiry_badge.dart';
import 'stock_badge.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(medicine.medicineName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          if (onEdit != null)
            IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18)),
          if (onDelete != null)
            IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18)),
        ]),
        Text(
            '${medicine.category ?? 'General'} • Batch ${medicine.batchNumber ?? '-'}',
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          StockBadge(
              quantity: medicine.quantity,
              lowStockLimit: medicine.lowStockLimit),
          ExpiryBadge(expiryDate: medicine.expiryDate),
          Chip(
              label: Text(Helpers.formatCurrency(medicine.salePrice)),
              visualDensity: VisualDensity.compact),
        ]),
      ]),
    );
  }
}
