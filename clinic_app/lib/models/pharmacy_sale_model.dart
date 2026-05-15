import 'pharmacy_sale_item_model.dart';

class PharmacySaleModel {
  final int id;
  final int? patientId;
  final int? prescriptionId;
  final String? patientName;
  final double totalAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String? soldByName;
  final String? createdAt;
  final List<PharmacySaleItemModel> items;

  const PharmacySaleModel({
    required this.id,
    this.patientId,
    this.prescriptionId,
    this.patientName,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    this.soldByName,
    this.createdAt,
    required this.items,
  });

  factory PharmacySaleModel.fromJson(Map<String, dynamic> j) =>
      PharmacySaleModel(
        id: _int(j['id'] ?? j['sale_id']),
        patientId: _nullableInt(j['patient_id']),
        prescriptionId: _nullableInt(j['prescription_id']),
        patientName: (j['patient_name'] ??
                (j['patient'] is Map ? j['patient']['name'] : null))
            ?.toString(),
        totalAmount: _double(j['total_amount'] ?? j['total']),
        paymentStatus: (j['payment_status'] ?? 'paid').toString(),
        paymentMethod:
            (j['payment_method'] ?? j['method'] ?? 'cash').toString(),
        soldByName: (j['sold_by_name'] ??
                (j['sold_by'] is Map ? j['sold_by']['name'] : j['sold_by']))
            ?.toString(),
        createdAt: j['created_at']?.toString(),
        items: j['items'] is List
            ? (j['items'] as List)
                .map((e) =>
                    PharmacySaleItemModel.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
      );

  static int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
  static int? _nullableInt(dynamic v) => v == null ? null : _int(v);
  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
}
