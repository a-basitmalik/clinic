import 'medicine_prescription_model.dart';
import 'medicine_model.dart';

class PrescriptionOrderModel {
  final int prescriptionId;
  final int? patientId;
  final String patientName;
  final String doctorName;
  final String? appointmentDate;
  final String pharmacyStatus;
  final String? createdAt;
  final List<PrescriptionOrderMedicine> medicines;

  const PrescriptionOrderModel({
    required this.prescriptionId,
    this.patientId,
    required this.patientName,
    required this.doctorName,
    this.appointmentDate,
    required this.pharmacyStatus,
    this.createdAt,
    required this.medicines,
  });

  factory PrescriptionOrderModel.fromJson(Map<String, dynamic> j) {
    final prescription = j['prescription'] is Map<String, dynamic>
        ? j['prescription'] as Map<String, dynamic>
        : j;
    final patient = j['patient'] is Map ? j['patient'] as Map : const {};
    final doctor = j['doctor'] is Map ? j['doctor'] as Map : const {};
    final appointment =
        j['appointment'] is Map ? j['appointment'] as Map : const {};
    final rawMeds = j['medicines'] ?? prescription['medicines'] ?? [];
    return PrescriptionOrderModel(
      prescriptionId: _int(prescription['id'] ?? j['prescription_id']),
      patientId: _nullableInt(prescription['patient_id'] ?? patient['id']),
      patientName:
          (j['patient_name'] ?? patient['name'] ?? 'Walk-in').toString(),
      doctorName: (j['doctor_name'] ?? doctor['name'] ?? '').toString(),
      appointmentDate: (appointment['appointment_date'] ??
              j['appointment_date'] ??
              prescription['created_at'])
          ?.toString(),
      pharmacyStatus:
          (prescription['pharmacy_status'] ?? j['pharmacy_status'] ?? 'pending')
              .toString(),
      createdAt: (prescription['created_at'] ?? j['created_at'])?.toString(),
      medicines: rawMeds is List
          ? rawMeds
              .map((e) =>
                  PrescriptionOrderMedicine.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  static int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
  static int? _nullableInt(dynamic v) => v == null ? null : _int(v);
}

class PrescriptionOrderMedicine {
  final MedicinePrescriptionModel prescribed;
  final MedicineModel? inventoryMatch;
  final int availableStock;

  const PrescriptionOrderMedicine({
    required this.prescribed,
    this.inventoryMatch,
    required this.availableStock,
  });

  factory PrescriptionOrderMedicine.fromJson(Map<String, dynamic> j) {
    final match = (j['inventory_match'] ?? j['inventory'] ?? j['medicine'])
            is Map<String, dynamic>
        ? MedicineModel.fromJson((j['inventory_match'] ??
            j['inventory'] ??
            j['medicine']) as Map<String, dynamic>)
        : null;
    return PrescriptionOrderMedicine(
      prescribed: MedicinePrescriptionModel.fromJson(j),
      inventoryMatch: match,
      availableStock: _int(j['available_stock'] ?? match?.quantity),
    );
  }

  static int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
}
