import '../constants/api_constants.dart';
import 'api_service.dart';

class ClinicalAiService {
  ClinicalAiService._();

  static Future<Map<String, dynamic>> status() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.clinicalAiStatus,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<Map<String, dynamic>> patientSummary(int patientId) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.clinicalAiPatientSummary,
      body: {'patient_id': patientId},
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<Map<String, dynamic>> consultationAssist({
    required int appointmentId,
    required int patientId,
    String? symptoms,
    String? diagnosis,
    String? notes,
    String? vitalsSummary,
  }) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.clinicalAiConsultationAssist,
      body: {
        'appointment_id': appointmentId,
        'patient_id': patientId,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'notes': notes,
        'vitals_summary': vitalsSummary,
      },
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<Map<String, dynamic>> extractMedicalText(String text) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.clinicalAiExtractMedicalText,
      body: {'text': text},
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }

  static Future<List<Map<String, dynamic>>> riskModels() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.clinicalAiRiskModels,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return ((res.data ?? {})['models'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> predictDiseaseRisk(
    String modelKey,
    Map<String, dynamic> inputs,
  ) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.clinicalAiRiskPredict(modelKey),
      body: inputs,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }
}
