import 'package:flutter/material.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/widgets/medicine_form.dart';
import '../../models/medicine_model.dart';

class AddEditMedicineScreen extends StatelessWidget {
  final MedicineModel? medicine;
  final VoidCallback? onSaved;

  const AddEditMedicineScreen({super.key, this.medicine, this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(medicine == null ? 'Add Medicine' : 'Edit Medicine')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: MedicineForm(
          medicine: medicine,
          onSubmit: (body) async {
            if (medicine == null) {
              await PharmacyService.createItem(body);
            } else {
              await PharmacyService.updateItem(medicine!.id, body);
            }
            onSaved?.call();
            if (context.mounted) Navigator.pop(context, true);
          },
        ),
      ),
    );
  }
}
