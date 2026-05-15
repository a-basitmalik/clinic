import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'custom_text_field.dart';

class LabTestDraft {
  final name = TextEditingController();
  final instructions = TextEditingController();

  Map<String, dynamic> toJson() => {
    'test_name': name.text.trim(),
    'instructions': instructions.text.trim(),
  };

  void dispose() {
    name.dispose();
    instructions.dispose();
  }
}

class LabTestForm extends StatelessWidget {
  final LabTestDraft draft;
  final VoidCallback onRemove;
  final int index;

  const LabTestForm({super.key, required this.draft, required this.onRemove, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text('Lab test ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded, color: AppColors.danger)),
        ]),
        CustomTextField(label: 'Test name', controller: draft.name, prefixIcon: Icons.science_rounded),
        const SizedBox(height: 10),
        CustomTextField(label: 'Instructions', controller: draft.instructions, maxLines: 2),
      ]),
    );
  }
}
