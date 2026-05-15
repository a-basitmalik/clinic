import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'custom_text_field.dart';

class PrescriptionMedicineDraft {
  final name = TextEditingController();
  final dosage = TextEditingController();
  final frequency = TextEditingController();
  final duration = TextEditingController();
  final instructions = TextEditingController();

  Map<String, dynamic> toJson() => {
    'medicine_name': name.text.trim(),
    'dosage': dosage.text.trim(),
    'frequency': frequency.text.trim(),
    'duration': duration.text.trim(),
    'instructions': instructions.text.trim(),
  };

  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    instructions.dispose();
  }
}

class PrescriptionMedicineForm extends StatelessWidget {
  final PrescriptionMedicineDraft draft;
  final VoidCallback onRemove;
  final int index;

  const PrescriptionMedicineForm({
    super.key,
    required this.draft,
    required this.onRemove,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text('Medicine ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded, color: AppColors.danger)),
        ]),
        CustomTextField(label: 'Medicine name', controller: draft.name, prefixIcon: Icons.medication_rounded),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(width: 180, child: CustomTextField(label: 'Dosage', controller: draft.dosage)),
          SizedBox(width: 180, child: CustomTextField(label: 'Frequency', controller: draft.frequency)),
          SizedBox(width: 180, child: CustomTextField(label: 'Duration', controller: draft.duration)),
        ]),
        const SizedBox(height: 10),
        CustomTextField(label: 'Instructions', controller: draft.instructions, maxLines: 2),
      ]),
    );
  }
}
