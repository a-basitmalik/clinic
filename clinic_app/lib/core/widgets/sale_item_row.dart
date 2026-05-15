import 'package:flutter/material.dart';
import '../../models/medicine_model.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';

class SaleItemDraft {
  MedicineModel? medicine;
  int quantity;

  SaleItemDraft({this.medicine, this.quantity = 1});
  double get total => (medicine?.salePrice ?? 0) * quantity;
}

class SaleItemRow extends StatelessWidget {
  final SaleItemDraft item;
  final List<MedicineModel> medicines;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const SaleItemRow({
    super.key,
    required this.item,
    required this.medicines,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<MedicineModel>(
                initialValue: item.medicine,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Medicine'),
                items: medicines
                    .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.medicineName} (${m.quantity})')))
                    .toList(),
                onChanged: (m) {
                  item.medicine = m;
                  onChanged();
                },
              ),
            ),
            SizedBox(
              width: 120,
              child: TextFormField(
                initialValue: '${item.quantity}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty'),
                onChanged: (v) {
                  item.quantity = int.tryParse(v) ?? 1;
                  onChanged();
                },
              ),
            ),
            SizedBox(
                width: 120,
                child: Text(Helpers.formatCurrency(item.medicine?.salePrice))),
            SizedBox(
                width: 140,
                child: Text(Helpers.formatCurrency(item.total),
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded)),
          ]),
    );
  }
}
