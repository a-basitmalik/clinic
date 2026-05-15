import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../models/assistant_model.dart';
import '../../models/vitals_model.dart';

class AssistantService {
  AssistantService._();

  static Future<List<AssistantModel>> listMine() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.myAssistants,
      fromData: (d) => d as Map<String, dynamic>,
    );
    final raw = res.data?['assistants'] ?? res.data?['my_assistants'] ?? [];
    final rows = raw is List ? raw : [];
    return rows.map((e) => AssistantModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<AssistantModel>> listAll() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.assistants,
      fromData: (d) => d as Map<String, dynamic>,
    );
    final raw = res.data?['assistants'] ?? [];
    final rows = raw is List ? raw : [];
    return rows.map((e) => AssistantModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<AssistantModel> create(Map<String, dynamic> body) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.assistants,
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final assistantJson = (data['assistant'] is Map<String, dynamic>)
        ? data['assistant'] as Map<String, dynamic>
        : (data['user'] is Map<String, dynamic>)
            ? data['user'] as Map<String, dynamic>
            : data;
    return AssistantModel.fromJson(assistantJson).copyWithTemp(data['temp_password'] as String?);
  }

  static Future<AssistantModel> update(int id, Map<String, dynamic> body) async {
    final res = await ApiService.put<Map<String, dynamic>>(
      '${ApiConstants.assistants}/$id',
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final assistantJson = data['assistant'] is Map<String, dynamic>
        ? data['assistant'] as Map<String, dynamic>
        : data;
    return AssistantModel.fromJson(assistantJson);
  }

  static Future<void> delete(int id) async {
    final res = await ApiService.delete<void>('${ApiConstants.assistants}/$id');
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  static Future<Map<String, dynamic>> dashboard() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.assistantDashboard,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<List<AppointmentModel>> queue() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.assistantQueue,
      fromData: (d) => d as Map<String, dynamic>,
    );
    final raw = res.data?['appointments'] ?? res.data?['queue'] ?? [];
    final rows = raw is List ? raw : [];
    return rows.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<VitalsModel> addVitals(Map<String, dynamic> body) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.assistantVitals,
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    final data = res.data ?? {};
    final vitalsJson = data['vitals'] is Map<String, dynamic>
        ? data['vitals'] as Map<String, dynamic>
        : data;
    return VitalsModel.fromJson(vitalsJson);
  }

  static Future<void> uploadReport(Map<String, dynamic> body) async {
    final res = await ApiService.post<void>(ApiConstants.assistantReports, body: body);
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  static Future<void> saveSymptomsDraft(Map<String, dynamic> body) async {
    final res = await ApiService.post<void>(ApiConstants.assistantSymptomsDraft, body: body);
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  static Future<void> callNext(int appointmentId) async {
    final res = await ApiService.put<void>(ApiConstants.assistantCallNext(appointmentId));
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  static Future<Map<String, dynamic>> patientHistory(int patientId) async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.assistantPatientHistory(patientId),
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<Map<String, dynamic>> printData(int prescriptionId) async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.assistantPrescriptionPrint(prescriptionId),
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }
}

extension _AssistantTemp on AssistantModel {
  AssistantModel copyWithTemp(String? temp) => AssistantModel(
    id: id,
    userId: userId,
    doctorId: doctorId,
    name: name,
    email: email,
    phone: phone,
    status: status,
    permissions: permissions,
    tempPassword: temp ?? tempPassword,
  );
}
