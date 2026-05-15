import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/clinic_model.dart';
import '../../models/revenue_model.dart';
import '../../models/api_response_model.dart';

class SuperAdminService {
  SuperAdminService._();

  static Future<List<ClinicModel>> getAllClinics({
    Map<String, String>? queryParams,
  }) async {
    final res = await ApiService.get<List<ClinicModel>>(
      ApiConstants.clinics,
      queryParams: {'per_page': '100', ...?queryParams},
      fromData: (d) =>
          (d as List).map((e) => ClinicModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return res.data ?? [];
  }

  static Future<ClinicModel> getClinicDetail(int id) async {
    final res = await ApiService.get<ClinicModel>(
      '${ApiConstants.clinics}/$id',
      fromData: (d) => ClinicModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data!;
  }

  static Future<List<ClinicModel>> getPendingClinics() async {
    final res = await ApiService.get<List<ClinicModel>>(
      ApiConstants.superAdminPending,
      fromData: (d) =>
          (d as List).map((e) => ClinicModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return res.data ?? [];
  }

  static Future<void> approveClinic(int id) async {
    final res = await ApiService.put<void>('${ApiConstants.clinics}/$id/approve');
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  static Future<void> suspendClinic(int id, {String? reason}) async {
    final res = await ApiService.put<void>(
      '${ApiConstants.clinics}/$id/suspend',
      body: reason != null ? {'reason': reason} : null,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  static Future<void> unsuspendClinic(int id) async {
    final res = await ApiService.put<void>('${ApiConstants.clinics}/$id/unsuspend');
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.superAdminDashboard,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<Map<String, dynamic>> getStats() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.superAdminStats,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<RevenueModel> getRevenue() async {
    final res = await ApiService.get<RevenueModel>(
      ApiConstants.superAdminRevenue,
      fromData: (d) => RevenueModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data ?? RevenueModel.fromJson({});
  }
}
