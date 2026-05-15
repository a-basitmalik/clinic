class MedicinePrescriptionModel {
  final int? id;
  final int? medicineId;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;

  const MedicinePrescriptionModel({
    this.id,
    this.medicineId,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
  });

  factory MedicinePrescriptionModel.fromJson(Map<String, dynamic> j) => MedicinePrescriptionModel(
    id: j['id'] as int?,
    medicineId: j['medicine_id'] as int?,
    medicineName: j['medicine_name'] as String? ?? '',
    dosage: j['dosage'] as String?,
    frequency: j['frequency'] as String?,
    duration: j['duration'] as String?,
    instructions: j['instructions'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (medicineId != null) 'medicine_id': medicineId,
    'medicine_name': medicineName,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'instructions': instructions,
  };
}
