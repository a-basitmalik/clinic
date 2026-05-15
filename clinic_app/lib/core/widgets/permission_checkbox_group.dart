import 'package:flutter/material.dart';

class PermissionCheckboxGroup extends StatelessWidget {
  final Map<String, bool> permissions;
  final void Function(String key, bool value) onChanged;

  const PermissionCheckboxGroup({super.key, required this.permissions, required this.onChanged});

  static const labels = {
    'can_view_appointments': 'View appointments',
    'can_add_vitals': 'Add vitals',
    'can_upload_reports': 'Upload reports',
    'can_prepare_prescription_draft': 'Prepare prescription draft',
    'can_print_prescription': 'Print prescription',
    'can_view_patient_history': 'View patient history',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: labels.entries.map((entry) => SizedBox(
        width: 260,
        child: CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(entry.value, style: const TextStyle(fontSize: 13)),
          value: permissions[entry.key] ?? false,
          onChanged: (v) => onChanged(entry.key, v ?? false),
        ),
      )).toList(),
    );
  }
}
