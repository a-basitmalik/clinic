import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';

class AppointmentService {
  AppointmentService._();

  static Future<List<AppointmentModel>> getAppointments({
    String? date,
    String? status,
    String? doctorId,
    String? search,
    int perPage = 100,
  }) async {
    final params = <String, String>{'per_page': '$perPage'};
    if (date != null && date.isNotEmpty) params['date'] = date;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (doctorId != null && doctorId.isNotEmpty) params['doctor_id'] = doctorId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get<List<AppointmentModel>>(
      ApiConstants.appointments,
      queryParams: params,
      fromData: (d) => (d as List)
          .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<List<AppointmentModel>> getTodayAppointments({
    String? doctorId,
    String? status,
    String? search,
  }) async {
    final params = <String, String>{'per_page': '200'};
    if (doctorId != null && doctorId.isNotEmpty) params['doctor_id'] = doctorId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get<List<AppointmentModel>>(
      ApiConstants.todayAppointments,
      queryParams: params,
      fromData: (d) => (d as List)
          .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<AppointmentModel> getAppointment(int id) async {
    final res = await ApiService.get<AppointmentModel>(
      ApiConstants.appointmentDetail(id),
      fromData: (d) {
        final data = d as Map<String, dynamic>;
        return AppointmentModel.fromJson(
          (data['appointment'] as Map<String, dynamic>?) ?? data,
        );
      },
    );
    return res.data!;
  }

  static Future<AppointmentModel> createAppointment(
      Map<String, dynamic> body) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.appointments,
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final apptJson = data['appointment'] as Map<String, dynamic>? ?? data;
    return AppointmentModel.fromJson(apptJson);
  }

  static Future<AppointmentModel> updateStatus(int id, String status) async {
    final res = await ApiService.put<Map<String, dynamic>>(
      ApiConstants.appointmentStatus(id),
      body: {'status': status},
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final apptJson = data['appointment'] as Map<String, dynamic>? ?? data;
    return AppointmentModel.fromJson(apptJson);
  }

  static Future<AppointmentModel> cancelAppointment(int id,
      {String? reason}) async {
    final res = await ApiService.put<Map<String, dynamic>>(
      ApiConstants.appointmentCancel(id),
      body: reason != null ? {'reason': reason} : {},
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final apptJson = data['appointment'] as Map<String, dynamic>? ?? data;
    return AppointmentModel.fromJson(apptJson);
  }

  static Future<AppointmentModel> rescheduleAppointment(
    int id, {
    required String date,
    required String time,
  }) async {
    final res = await ApiService.put<Map<String, dynamic>>(
      ApiConstants.appointmentReschedule(id),
      body: {'appointment_date': date, 'appointment_time': time},
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final apptJson = data['appointment'] as Map<String, dynamic>? ?? data;
    return AppointmentModel.fromJson(apptJson);
  }
}
