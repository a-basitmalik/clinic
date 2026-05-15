import 'medicine_model.dart';

class PharmacySaleItemModel {
  final int id;
  final int medicineId;
  final String medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final MedicineModel? medicine;

  const PharmacySaleItemModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.medicine,
  });

  factory PharmacySaleItemModel.fromJson(Map<String, dynamic> j) {
    final med = j['medicine'] is Map<String, dynamic>
        ? MedicineModel.fromJson(j['medicine'] as Map<String, dynamic>)
        : null;
    return PharmacySaleItemModel(
      id: _int(j['id']),
      medicineId: _int(j['medicine_id'] ?? med?.id),
      medicineName: (j['medicine_name'] ?? med?.medicineName ?? j['name'] ?? '')
          .toString(),
      quantity: _int(j['quantity']),
      unitPrice: _double(j['unit_price'] ?? j['sale_price']),
      totalPrice: _double(j['total_price'] ?? j['total']),
      medicine: med,
    );
  }

  static int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
}
