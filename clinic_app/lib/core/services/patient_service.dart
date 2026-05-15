import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/api_response_model.dart';
import '../../models/patient_model.dart';
import '../../models/patient_history_model.dart';

class PatientService {
  PatientService._();

  static Future<List<PatientModel>> getPatients({
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get<List<PatientModel>>(
      ApiConstants.patients,
      queryParams: params,
      fromData: (d) => (d as List)
          .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<PatientModel> getPatient(int id) async {
    final res = await ApiService.get<PatientModel>(
      ApiConstants.patientDetail(id),
      fromData: (d) {
        final data = d as Map<String, dynamic>;
        return PatientModel.fromJson(
          (data['patient'] as Map<String, dynamic>?) ?? data,
        );
      },
    );
    return res.data!;
  }

  static Future<PatientModel> createPatient(Map<String, dynamic> body) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.patients,
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final patientJson = data['patient'] as Map<String, dynamic>? ?? data;
    return PatientModel.fromJson(patientJson);
  }

  static Future<PatientModel> updatePatient(
      int id, Map<String, dynamic> body) async {
    final res = await ApiService.put<Map<String, dynamic>>(
      ApiConstants.patientDetail(id),
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final patientJson = data['patient'] as Map<String, dynamic>? ?? data;
    return PatientModel.fromJson(patientJson);
  }

  static Future<PatientHistoryModel> getHistory(int id) async {
    final res = await ApiService.get<PatientHistoryModel>(
      ApiConstants.patientHistory(id),
      fromData: (d) => PatientHistoryModel.fromJson(d as Map<String, dynamic>),
    );
    return res.data!;
  }
}
