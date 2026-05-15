import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/invoice_model.dart';
import '../../models/medicine_model.dart';
import '../../models/pharmacy_sale_model.dart';
import '../../models/prescription_order_model.dart';

class PharmacyService {
  PharmacyService._();

  static Map<String, String> _params(Map<String, dynamic> raw) {
    final params = <String, String>{};
    raw.forEach((key, value) {
      if (value != null && '$value'.isNotEmpty) params[key] = '$value';
    });
    return params;
  }

  static List<dynamic> _listFrom(dynamic d, List<String> keys) {
    if (d is List) return d;
    if (d is Map<String, dynamic>) {
      for (final key in keys) {
        final value = d[key];
        if (value is List) return value;
      }
      final nested = d['data'];
      if (nested is Map<String, dynamic>) return _listFrom(nested, keys);
    }
    return const [];
  }

  static Map<String, dynamic> _mapFrom(dynamic d, String key) {
    final map = d as Map<String, dynamic>;
    return (map[key] as Map<String, dynamic>?) ?? map;
  }

  static Future<Map<String, dynamic>> dashboard() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.pharmacyDashboard,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<List<MedicineModel>> items({
    String? search,
    String? category,
    String? status,
    bool? lowStock,
    bool? expiring,
    bool? expired,
    int page = 1,
    int perPage = 100,
  }) async {
    final res = await ApiService.get<List<MedicineModel>>(
      ApiConstants.pharmacyItems,
      queryParams: _params({
        'search': search,
        'category': category,
        'status': status,
        'low_stock': lowStock == true ? 'true' : null,
        'expiring': expiring == true ? 'true' : null,
        'expired': expired == true ? 'true' : null,
        'page': page,
        'per_page': perPage,
      }),
      fromData: (d) => _listFrom(d, ['items', 'medicines', 'data'])
          .map((e) => MedicineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<MedicineModel> item(int id) async {
    final res = await ApiService.get<MedicineModel>(
      ApiConstants.pharmacyItem(id),
      fromData: (d) => MedicineModel.fromJson(_mapFrom(d, 'item')),
    );
    return res.data!;
  }

  static Future<MedicineModel> createItem(Map<String, dynamic> body) async {
    final res = await ApiService.post<MedicineModel>(
      ApiConstants.pharmacyItems,
      body: body,
      fromData: (d) => MedicineModel.fromJson(_mapFrom(d, 'item')),
    );
    return res.data!;
  }

  static Future<MedicineModel> updateItem(
      int id, Map<String, dynamic> body) async {
    final res = await ApiService.put<MedicineModel>(
      ApiConstants.pharmacyItem(id),
      body: body,
      fromData: (d) => MedicineModel.fromJson(_mapFrom(d, 'item')),
    );
    return res.data!;
  }

  static Future<void> deleteItem(int id) async {
    await ApiService.delete<void>(ApiConstants.pharmacyItem(id));
  }

  static Future<List<MedicineModel>> lowStock() async {
    final res = await ApiService.get<List<MedicineModel>>(
      ApiConstants.pharmacyLowStock,
      fromData: (d) => _listFrom(d, ['items', 'low_stock_items', 'medicines'])
          .map((e) => MedicineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<List<MedicineModel>> expiring({bool expired = false}) async {
    final res = await ApiService.get<List<MedicineModel>>(
      expired ? ApiConstants.pharmacyExpired : ApiConstants.pharmacyExpiring,
      fromData: (d) => _listFrom(
              d, ['items', 'expiring_items', 'expired_items', 'medicines'])
          .map((e) => MedicineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<List<PrescriptionOrderModel>> prescriptionOrders({
    String? status,
    int page = 1,
    int perPage = 100,
  }) async {
    final res = await ApiService.get<List<PrescriptionOrderModel>>(
      ApiConstants.pharmacyOrders,
      queryParams:
          _params({'status': status, 'page': page, 'per_page': perPage}),
      fromData: (d) => _listFrom(d, ['orders', 'prescriptions', 'items'])
          .map(
              (e) => PrescriptionOrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<PrescriptionOrderModel> prescriptionOrder(int id) async {
    final res = await ApiService.get<PrescriptionOrderModel>(
      ApiConstants.pharmacyOrder(id),
      fromData: (d) =>
          PrescriptionOrderModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data!;
  }

  static Future<PrescriptionOrderModel> updateOrderStatus(
      int id, String status) async {
    final res = await ApiService.put<PrescriptionOrderModel>(
      ApiConstants.pharmacyOrderStatus(id),
      body: {'pharmacy_status': status, 'status': status},
      fromData: (d) =>
          PrescriptionOrderModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data!;
  }

  static Future<List<PharmacySaleModel>> sales({
    String? paymentStatus,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 100,
  }) async {
    final res = await ApiService.get<List<PharmacySaleModel>>(
      ApiConstants.pharmacySales,
      queryParams: _params({
        'payment_status': paymentStatus,
        'start_date': startDate,
        'end_date': endDate,
        'page': page,
        'per_page': perPage,
      }),
      fromData: (d) => _listFrom(d, ['sales', 'items', 'data'])
          .map((e) => PharmacySaleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<PharmacySaleModel> sale(int id) async {
    final res = await ApiService.get<PharmacySaleModel>(
      ApiConstants.pharmacySale(id),
      fromData: (d) => PharmacySaleModel.fromJson(_mapFrom(d, 'sale')),
    );
    return res.data!;
  }

  static Future<PharmacySaleModel> createSale(Map<String, dynamic> body) async {
    final res = await ApiService.post<PharmacySaleModel>(
      ApiConstants.pharmacySales,
      body: body,
      fromData: (d) => PharmacySaleModel.fromJson(_mapFrom(d, 'sale')),
    );
    return res.data!;
  }

  static Future<InvoiceModel> invoice(int id) async {
    final res = await ApiService.get<InvoiceModel>(
      ApiConstants.pharmacySaleInvoice(id),
      fromData: (d) => InvoiceModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data!;
  }

  static Future<Map<String, dynamic>> reports(
      {String? startDate, String? endDate}) async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.pharmacyReports,
      queryParams: _params({'start_date': startDate, 'end_date': endDate}),
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }
}
