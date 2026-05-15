import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/report_model.dart';

class ReportService {
  ReportService._();

  static Map<String, String> _params({
    String? startDate,
    String? endDate,
    String? doctorId,
    String? paymentType,
    String? status,
    String? groupBy,
    bool export = false,
  }) {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (doctorId != null && doctorId.isNotEmpty) params['doctor_id'] = doctorId;
    if (paymentType != null && paymentType.isNotEmpty)
      params['payment_type'] = paymentType;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (groupBy != null && groupBy.isNotEmpty) params['group_by'] = groupBy;
    if (export) params['export'] = 'true';
    return params;
  }

  static Future<ReportModel> getReport({
    required String name,
    required String endpoint,
    String? startDate,
    String? endDate,
    String? doctorId,
    String? paymentType,
    String? status,
    String? groupBy,
    bool export = false,
  }) async {
    final res = await ApiService.get<ReportModel>(
      endpoint,
      queryParams: _params(
        startDate: startDate,
        endDate: endDate,
        doctorId: doctorId,
        paymentType: paymentType,
        status: status,
        groupBy: groupBy,
        export: export,
      ),
      fromData: (d) => ReportModel.fromJson(name, d as Map<String, dynamic>),
    );
    return res.data!;
  }

  static Future<Map<String, dynamic>> getSuperAdminStats() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.superAdminStats,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<Map<String, dynamic>> getClinicRevenue({
    String? from,
    String? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['start_date'] = from;
    if (to != null) params['end_date'] = to;
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.reportClinicRevenue,
      queryParams: params.isEmpty ? null : params,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<Map<String, dynamic>> getAppointmentsReport({
    String? from,
    String? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['start_date'] = from;
    if (to != null) params['end_date'] = to;
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.reportAppointments,
      queryParams: params.isEmpty ? null : params,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<Map<String, dynamic>> getPharmacySales({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.reportPharmacySales,
      queryParams: params.isEmpty ? null : params,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }
}
