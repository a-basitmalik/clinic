import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class VitalsDraft {
  final temperature = TextEditingController();
  final bloodPressure = TextEditingController();
  final pulse = TextEditingController();
  final weight = TextEditingController();
  final height = TextEditingController();
  final oxygen = TextEditingController();
  final notes = TextEditingController();

  Map<String, dynamic> toJson({required int patientId, int? appointmentId}) => {
    'patient_id': patientId,
    if (appointmentId != null) 'appointment_id': appointmentId,
    'temperature': temperature.text.trim(),
    'blood_pressure': bloodPressure.text.trim(),
    'pulse': pulse.text.trim(),
    'weight': weight.text.trim(),
    'height': height.text.trim(),
    'oxygen_level': oxygen.text.trim(),
    'notes': notes.text.trim(),
  };

  void dispose() {
    temperature.dispose();
    bloodPressure.dispose();
    pulse.dispose();
    weight.dispose();
    height.dispose();
    oxygen.dispose();
    notes.dispose();
  }
}

class VitalsForm extends StatelessWidget {
  final VitalsDraft draft;

  const VitalsForm({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      SizedBox(width: 160, child: CustomTextField(label: 'Temperature', controller: draft.temperature)),
      SizedBox(width: 160, child: CustomTextField(label: 'Blood pressure', controller: draft.bloodPressure)),
      SizedBox(width: 160, child: CustomTextField(label: 'Pulse', controller: draft.pulse)),
      SizedBox(width: 160, child: CustomTextField(label: 'Weight', controller: draft.weight)),
      SizedBox(width: 160, child: CustomTextField(label: 'Height', controller: draft.height)),
      SizedBox(width: 160, child: CustomTextField(label: 'Oxygen %', controller: draft.oxygen)),
      SizedBox(width: 520, child: CustomTextField(label: 'Notes', controller: draft.notes, maxLines: 2)),
    ]);
  }
}
