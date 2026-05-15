import 'pharmacy_sale_model.dart';

class InvoiceModel {
  final Map<String, dynamic> clinic;
  final Map<String, dynamic>? patient;
  final PharmacySaleModel sale;
  final double subtotal;
  final double total;

  const InvoiceModel({
    required this.clinic,
    this.patient,
    required this.sale,
    required this.subtotal,
    required this.total,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> j) {
    final saleRaw = j['sale'] is Map<String, dynamic>
        ? j['sale'] as Map<String, dynamic>
        : j;
    final sale = PharmacySaleModel.fromJson({
      ...saleRaw,
      'items': j['items'] ?? saleRaw['items'] ?? [],
      'patient_name':
          j['patient'] is Map ? j['patient']['name'] : saleRaw['patient_name'],
    });
    return InvoiceModel(
      clinic: j['clinic'] is Map<String, dynamic>
          ? j['clinic'] as Map<String, dynamic>
          : const {},
      patient: j['patient'] is Map<String, dynamic>
          ? j['patient'] as Map<String, dynamic>
          : null,
      sale: sale,
      subtotal: _double(j['subtotal'] ?? sale.totalAmount),
      total: _double(j['total'] ?? sale.totalAmount),
    );
  }

  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
}
