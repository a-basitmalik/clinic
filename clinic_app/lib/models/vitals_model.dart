class VitalsModel {
  final int? id;
  final int patientId;
  final int? appointmentId;
  final String? temperature;
  final String? bloodPressure;
  final String? pulse;
  final String? weight;
  final String? height;
  final String? oxygenLevel;
  final String? notes;
  final String? createdAt;

  const VitalsModel({
    this.id,
    required this.patientId,
    this.appointmentId,
    this.temperature,
    this.bloodPressure,
    this.pulse,
    this.weight,
    this.height,
    this.oxygenLevel,
    this.notes,
    this.createdAt,
  });

  factory VitalsModel.fromJson(Map<String, dynamic> j) => VitalsModel(
    id: j['id'] as int?,
    patientId: j['patient_id'] as int? ?? 0,
    appointmentId: j['appointment_id'] as int?,
    temperature: j['temperature']?.toString(),
    bloodPressure: j['blood_pressure'] as String?,
    pulse: j['pulse']?.toString(),
    weight: j['weight']?.toString(),
    height: j['height']?.toString(),
    oxygenLevel: j['oxygen_level']?.toString(),
    notes: j['notes'] as String?,
    createdAt: j['created_at'] as String?,
  );
}
