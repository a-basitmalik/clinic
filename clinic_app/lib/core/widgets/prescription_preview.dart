import 'package:flutter/material.dart';
import '../../models/prescription_model.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';

class PrescriptionPreview extends StatelessWidget {
  final PrescriptionModel prescription;
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? doctor;

  const PrescriptionPreview(
      {super.key, required this.prescription, this.patient, this.doctor});

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_hospital_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('Prescription',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          Text(p.createdAt != null ? Helpers.formatDate(p.createdAt!) : '',
              style: const TextStyle(color: AppColors.textSecondary)),
        ]),
        const Divider(height: 24),
        if (patient != null)
          Text('Patient: ${patient!['name'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        if (doctor != null)
          Text('Doctor: ${doctor!['name'] ?? ''}',
              style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        _line('Symptoms', p.symptoms),
        _line('Diagnosis', p.diagnosis),
        _line('Notes', p.notes),
        if (p.followUpDate != null)
          _line('Follow-up', Helpers.formatDate(p.followUpDate!)),
        const SizedBox(height: 14),
        const Text('Medicines', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...p.medicines.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• ${m.medicineName} ${[
                m.dosage,
                m.frequency,
                m.duration
              ].where((e) => e != null && e.isNotEmpty).join(' • ')}\n  ${m.instructions ?? ''}'),
            )),
        if (p.labTests.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Lab Tests',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...p.labTests.map((t) => Text(
              '• ${t.testName}${t.instructions == null ? '' : ' - ${t.instructions}'}')),
        ],
      ]),
    );
  }

  Widget _line(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }
}
