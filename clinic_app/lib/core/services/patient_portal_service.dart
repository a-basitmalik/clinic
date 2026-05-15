import '../constants/api_constants.dart';
import 'api_service.dart';
import 'payment_service.dart';
import 'patient_service.dart';
import 'prescription_service.dart';
import '../../models/bill_model.dart';
import '../../models/patient_history_model.dart';
import '../../models/patient_portal_model.dart';
import '../../models/prescription_model.dart';
import '../../models/user_model.dart';

class PatientPortalService {
  PatientPortalService._();

  static Future<int?> currentPatientId() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.me,
      fromData: (d) => d as Map<String, dynamic>,
    );
    final data = res.data ?? {};
    final user = (data['user'] as Map<String, dynamic>?) ?? data;
    final parsed = UserModel.fromJson(user);
    return parsed.patientId ?? (user['patient_id'] as int?);
  }

  static Future<PatientPortalModel> loadPortal() async {
    final patientId = await currentPatientId();
    if (patientId == null || patientId == 0) {
      return const PatientPortalModel(prescriptions: [], bills: []);
    }
    PatientHistoryModel? history;
    List<PrescriptionModel> prescriptions = [];
    List<BillModel> bills = [];
    try {
      history = await PatientService.getHistory(patientId);
    } catch (_) {}
    try {
      prescriptions = await PrescriptionService.byPatient(patientId);
    } catch (_) {}
    try {
      final payments = await PaymentService.getPatientPayments(patientId);
      bills = payments.map(BillModel.fromPayment).toList();
    } catch (_) {}
    return PatientPortalModel(
        history: history, prescriptions: prescriptions, bills: bills);
  }
}
