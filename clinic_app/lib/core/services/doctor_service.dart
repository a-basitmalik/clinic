import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/doctor_model.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_earnings_model.dart';

class DoctorService {
  DoctorService._();

  static Future<List<DoctorModel>> getDoctors({String? search}) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get<List<DoctorModel>>(
      ApiConstants.doctors,
      queryParams: params,
      fromData: (d) =>
          (d as List).map((e) => DoctorModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return res.data ?? [];
  }

  static Future<DoctorModel> getDoctor(int id) async {
    final res = await ApiService.get<DoctorModel>(
      '${ApiConstants.doctors}/$id',
      fromData: (d) => DoctorModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data!;
  }

  static Future<DoctorModel> createDoctor(Map<String, dynamic> body) async {
    final res = await ApiService.post<DoctorModel>(
      ApiConstants.doctors,
      body: body,
      fromData: (d) {
        final map = d as Map<String, dynamic>;
        return DoctorModel.fromJson(map['doctor'] is Map<String, dynamic> ? map['doctor'] as Map<String, dynamic> : map);
      },
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    return res.data!;
  }

  static Future<DoctorModel> updateDoctor(int id, Map<String, dynamic> body) async {
    final res = await ApiService.put<DoctorModel>(
      '${ApiConstants.doctors}/$id',
      body: body,
      fromData: (d) {
        final map = d as Map<String, dynamic>;
        return DoctorModel.fromJson(map['doctor'] is Map<String, dynamic> ? map['doctor'] as Map<String, dynamic> : map);
      },
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    return res.data!;
  }

  static Future<void> deactivateDoctor(int id) async {
    final res = await ApiService.put<void>('${ApiConstants.doctors}/$id/deactivate');
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  static Future<Map<String, dynamic>> dashboard() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.doctorDashboard,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<List<AppointmentModel>> todayAppointments() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.doctorToday,
      fromData: (d) => d as Map<String, dynamic>,
    );
    final raw = res.data?['appointments'] ?? [];
    final rows = raw is List ? raw : [];
    return rows.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<AppointmentModel>> queue({String? date}) async {
    final params = <String, String>{};
    if (date != null && date.isNotEmpty) params['date'] = date;
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.doctorQueue,
      queryParams: params,
      fromData: (d) => d as Map<String, dynamic>,
    );
    final raw = res.data?['appointments'] ?? [];
    final rows = raw is List ? raw : [];
    return rows.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> patientProfile(int patientId) async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.doctorPatientProfile(patientId),
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<AppointmentModel> startConsultation(int appointmentId) async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.doctorStartAppointment(appointmentId),
      fromData: (d) => d as Map<String, dynamic>,
    );
    final data = res.data ?? {};
    return AppointmentModel.fromJson(data['appointment'] is Map<String, dynamic> ? data['appointment'] as Map<String, dynamic> : data);
  }

  static Future<AppointmentModel> completeAppointment(int appointmentId, {bool allowNoPrescription = false}) async {
    final res = await ApiService.put<Map<String, dynamic>>(
      ApiConstants.doctorCompleteAppointment(appointmentId),
      body: {'allow_no_prescription': allowNoPrescription},
      fromData: (d) => d as Map<String, dynamic>,
    );
    final data = res.data ?? {};
    return AppointmentModel.fromJson(data['appointment'] is Map<String, dynamic> ? data['appointment'] as Map<String, dynamic> : data);
  }

  static Future<DoctorEarningsModel> earnings({String? startDate, String? endDate}) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    final res = await ApiService.get<DoctorEarningsModel>(
      ApiConstants.doctorEarnings,
      queryParams: params,
      fromData: (d) => DoctorEarningsModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data!;
  }

  static Future<Map<String, dynamic>> reports({String? startDate, String? endDate}) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.doctorReports,
      queryParams: params,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }
}
