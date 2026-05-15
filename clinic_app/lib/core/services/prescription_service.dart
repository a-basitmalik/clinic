import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/api_response_model.dart';
import '../../models/prescription_model.dart';

class PrescriptionService {
  PrescriptionService._();

  static PrescriptionModel _parse(dynamic d) {
    final map = d as Map<String, dynamic>;
    return PrescriptionModel.fromJson(
        map['prescription'] as Map<String, dynamic>? ?? map);
  }

  static Future<List<PrescriptionModel>> list(
      {int page = 1, int perPage = 50}) async {
    final res = await ApiService.get<List<PrescriptionModel>>(
      ApiConstants.prescriptions,
      queryParams: {'page': '$page', 'per_page': '$perPage'},
      fromData: (d) => (d as List)
          .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<PrescriptionModel> get(int id) async {
    final res = await ApiService.get<PrescriptionModel>(
      ApiConstants.prescriptionDetail(id),
      fromData: _parse,
    );
    return res.data!;
  }

  static Future<PrescriptionModel?> byAppointment(int appointmentId) async {
    try {
      final res = await ApiService.get<PrescriptionModel>(
        ApiConstants.prescriptionByAppointment(appointmentId),
        fromData: _parse,
      );
      return res.data;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<List<PrescriptionModel>> byPatient(int patientId) async {
    final res = await ApiService.get<List<PrescriptionModel>>(
      ApiConstants.prescriptionByPatient(patientId),
      fromData: (d) {
        final raw = d is List
            ? d
            : (d as Map<String, dynamic>)['prescriptions'] as List? ?? const [];
        return raw
            .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    return res.data ?? [];
  }

  static Future<PrescriptionModel> create(Map<String, dynamic> body) async {
    final res = await ApiService.post<PrescriptionModel>(
      ApiConstants.prescriptions,
      body: body,
      fromData: _parse,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    return res.data!;
  }

  static Future<PrescriptionModel> update(
      int id, Map<String, dynamic> body) async {
    final res = await ApiService.put<PrescriptionModel>(
      ApiConstants.prescriptionDetail(id),
      body: body,
      fromData: _parse,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    return res.data!;
  }

  static Future<void> delete(int id) async {
    final res =
        await ApiService.delete<void>(ApiConstants.prescriptionDetail(id));
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }
}
