import 'lab_test_model.dart';
import 'medicine_prescription_model.dart';

class PrescriptionModel {
  final int id;
  final int? clinicId;
  final int? doctorId;
  final int? patientId;
  final int? appointmentId;
  final String? symptoms;
  final String? diagnosis;
  final String? notes;
  final String? followUpDate;
  final String pharmacyStatus;
  final String? createdAt;
  final List<MedicinePrescriptionModel> medicines;
  final List<LabTestModel> labTests;

  const PrescriptionModel({
    required this.id,
    this.clinicId,
    this.doctorId,
    this.patientId,
    this.appointmentId,
    this.symptoms,
    this.diagnosis,
    this.notes,
    this.followUpDate,
    required this.pharmacyStatus,
    this.createdAt,
    required this.medicines,
    required this.labTests,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> j) {
    List<MedicinePrescriptionModel> meds(dynamic raw) => raw is List
        ? raw.map((e) => MedicinePrescriptionModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];
    List<LabTestModel> tests(dynamic raw) => raw is List
        ? raw.map((e) => LabTestModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];
    return PrescriptionModel(
      id: j['id'] as int? ?? 0,
      clinicId: j['clinic_id'] as int?,
      doctorId: j['doctor_id'] as int?,
      patientId: j['patient_id'] as int?,
      appointmentId: j['appointment_id'] as int?,
      symptoms: j['symptoms'] as String?,
      diagnosis: j['diagnosis'] as String?,
      notes: j['notes'] as String?,
      followUpDate: j['follow_up_date'] as String?,
      pharmacyStatus: j['pharmacy_status'] as String? ?? 'pending',
      createdAt: j['created_at'] as String?,
      medicines: meds(j['medicines']),
      labTests: tests(j['lab_tests']),
    );
  }
}
