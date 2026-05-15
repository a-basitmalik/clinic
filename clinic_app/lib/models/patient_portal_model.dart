import 'appointment_model.dart';
import 'bill_model.dart';
import 'patient_history_model.dart';
import 'prescription_model.dart';

class PatientPortalModel {
  final PatientHistoryModel? history;
  final List<PrescriptionModel> prescriptions;
  final List<BillModel> bills;

  const PatientPortalModel({
    this.history,
    required this.prescriptions,
    required this.bills,
  });

  List<AppointmentModel> get appointments => history?.appointments ?? [];
  int get totalVisits => history?.totalVisits ?? appointments.length;
}
