import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/patient_model.dart';
import '../../models/appointment_model.dart';
import '../../models/revenue_model.dart';

class ClinicAdminService {
  ClinicAdminService._();

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.clinicAdminDashboard,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<List<PatientModel>> getPatients({String? search}) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get<List<PatientModel>>(
      ApiConstants.clinicAdminPatients,
      queryParams: params,
      fromData: (d) =>
          (d as List).map((e) => PatientModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return res.data ?? [];
  }

  static Future<List<AppointmentModel>> getAppointments({
    String? date,
    String? status,
    String? search,
  }) async {
    final params = <String, String>{'per_page': '100'};
    if (date   != null && date.isNotEmpty)   params['date']   = date;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get<List<AppointmentModel>>(
      ApiConstants.clinicAdminAppointments,
      queryParams: params,
      fromData: (d) =>
          (d as List).map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return res.data ?? [];
  }

  static Future<RevenueModel> getRevenue({String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to   != null) params['to']   = to;
    final res = await ApiService.get<RevenueModel>(
      ApiConstants.clinicAdminRevenue,
      queryParams: params.isEmpty ? null : params,
      fromData: (d) => RevenueModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data ?? RevenueModel.fromJson({});
  }

  static Future<Map<String, dynamic>> getReports({String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to   != null) params['to']   = to;
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.clinicAdminReports,
      queryParams: params.isEmpty ? null : params,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }
}
