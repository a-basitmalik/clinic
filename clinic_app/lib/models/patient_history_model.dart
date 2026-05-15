import 'appointment_model.dart';
import 'patient_model.dart';
import 'payment_model.dart';

class PatientHistoryModel {
  final PatientModel patient;
  final int totalVisits;
  final String? lastVisitDate;
  final String? upcomingDate;
  final List<AppointmentModel> appointments;
  final List<Map<String, dynamic>> prescriptions;
  final List<PaymentModel> payments;
  final List<String> visitedDoctors;

  const PatientHistoryModel({
    required this.patient,
    required this.totalVisits,
    this.lastVisitDate,
    this.upcomingDate,
    required this.appointments,
    required this.prescriptions,
    required this.payments,
    required this.visitedDoctors,
  });

  factory PatientHistoryModel.fromJson(Map<String, dynamic> j) {
    final patientJson = j['patient'] as Map<String, dynamic>? ?? {};
    final stats       = j['stats']   as Map<String, dynamic>? ?? {};

    List<AppointmentModel> parseAppts(dynamic d) {
      if (d == null) return [];
      return (d as List).map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    List<PaymentModel> parsePayments(dynamic d) {
      if (d == null) return [];
      return (d as List).map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    List<String> parseDoctors(dynamic d) {
      if (d == null) return [];
      return (d as List).map((e) => e.toString()).toList();
    }

    List<Map<String, dynamic>> parseRx(dynamic d) {
      if (d == null) return [];
      return (d as List).map((e) => e as Map<String, dynamic>).toList();
    }

    return PatientHistoryModel(
      patient:        PatientModel.fromJson(patientJson),
      totalVisits:    stats['total_visits'] as int? ?? 0,
      lastVisitDate:  stats['last_visit']   as String?,
      upcomingDate:   stats['upcoming']     as String?,
      appointments:   parseAppts(j['appointments']),
      prescriptions:  parseRx(j['prescriptions']),
      payments:       parsePayments(j['payments']),
      visitedDoctors: parseDoctors(j['visited_doctors']),
    );
  }
}
