class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://clinic.nalexustechnologies.com/api';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // ── Health ────────────────────────────────────────────────────────────────
  static const String health = '/health';

  // ── Super Admin ───────────────────────────────────────────────────────────
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String superAdminStats = '/super-admin/stats';
  static const String superAdminRevenue = '/super-admin/revenue';
  static const String superAdminPending = '/super-admin/clinics/pending';

  // ── Clinics ───────────────────────────────────────────────────────────────
  static const String clinics = '/clinics';
  static const String registerClinic = '/clinics/register';

  // ── Clinic Admin ──────────────────────────────────────────────────────────
  static const String clinicAdminDashboard = '/clinic-admin/dashboard';
  static const String clinicAdminRevenue = '/clinic-admin/revenue';
  static const String clinicAdminReports = '/clinic-admin/reports';
  static const String clinicAdminPatients = '/clinic-admin/patients';
  static const String clinicAdminAppointments = '/clinic-admin/appointments';
  static const String clinicAdminPharmacyUsers = '/clinic-admin/pharmacy-users';

  // ── Departments ───────────────────────────────────────────────────────────
  static const String departments = '/departments';

  // ── Doctors ───────────────────────────────────────────────────────────────
  static const String doctors = '/doctors';
  static const String doctorDashboard = '/doctors/dashboard';
  static const String doctorToday = '/doctors/today-appointments';
  static const String doctorQueue = '/doctors/queue';
  static const String doctorEarnings = '/doctors/earnings';
  static const String doctorReports = '/doctors/reports';
  static String doctorPatientProfile(int id) => '/doctors/patients/$id/profile';
  static String doctorStartAppointment(int id) =>
      '/doctors/appointments/$id/start';
  static String doctorCompleteAppointment(int id) =>
      '/doctors/appointments/$id/complete';

  // ── Assistants ────────────────────────────────────────────────────────────
  static const String assistants = '/assistants';
  static const String myAssistants = '/assistants/my-assistants';
  static const String assistantDashboard = '/assistant/dashboard';
  static const String assistantQueue = '/assistant/queue';
  static const String assistantVitals = '/assistant/vitals';
  static const String assistantReports = '/assistant/reports';
  static const String assistantSymptomsDraft = '/assistant/symptoms-draft';
  static String assistantCallNext(int id) =>
      '/assistant/appointments/$id/call-next';
  static String assistantPatientHistory(int id) =>
      '/assistant/patients/$id/history';
  static String assistantPrescriptionPrint(int id) =>
      '/assistant/prescriptions/$id/print-data';

  // ── Receptionists ─────────────────────────────────────────────────────────
  static const String receptionists = '/receptionists';
  static const String receptionistDashboard = '/receptionists/dashboard';
  static const String receptionistReports = '/receptionists/reports';

  // ── Patients ──────────────────────────────────────────────────────────────
  static const String patients = '/patients';
  static String patientDetail(int id) => '/patients/$id';
  static String patientHistory(int id) => '/patients/$id/history';

  // ── Appointments ──────────────────────────────────────────────────────────
  static const String appointments = '/appointments';
  static const String todayAppointments = '/appointments/today';
  static String appointmentDetail(int id) => '/appointments/$id';
  static String appointmentStatus(int id) => '/appointments/$id/status';
  static String appointmentCancel(int id) => '/appointments/$id/cancel';
  static String appointmentReschedule(int id) => '/appointments/$id/reschedule';

  // ── Payments ──────────────────────────────────────────────────────────────
  static const String payments = '/payments';
  static const String revenueSummary = '/payments/revenue-summary';
  static String paymentDetail(int id) => '/payments/$id';
  static String patientPayments(int id) => '/payments/patient/$id';

  // ── Pharmacy ──────────────────────────────────────────────────────────────
  static const String pharmacyDashboard = '/pharmacy/dashboard';
  static const String pharmacyItems = '/pharmacy/items';
  static const String pharmacySales = '/pharmacy/sales';
  static const String pharmacyOrders = '/pharmacy/prescription-orders';
  static const String pharmacyLowStock = '/pharmacy/low-stock';
  static const String pharmacyExpiring = '/pharmacy/expiring';
  static const String pharmacyExpired = '/pharmacy/expired';
  static const String pharmacyReports = '/pharmacy/reports';
  static String pharmacyItem(int id) => '/pharmacy/items/$id';
  static String pharmacyOrder(int id) => '/pharmacy/prescription-orders/$id';
  static String pharmacyOrderStatus(int id) =>
      '/pharmacy/prescription-orders/$id/status';
  static String pharmacySale(int id) => '/pharmacy/sales/$id';
  static String pharmacySaleInvoice(int id) => '/pharmacy/sales/$id/invoice';

  // ── Prescriptions ─────────────────────────────────────────────────────────
  static const String prescriptions = '/prescriptions';
  static String prescriptionDetail(int id) => '/prescriptions/$id';
  static String prescriptionByPatient(int id) => '/prescriptions/patient/$id';
  static String prescriptionByAppointment(int id) =>
      '/prescriptions/appointment/$id';

  // ── Reports ───────────────────────────────────────────────────────────────
  static const String reportClinicRevenue = '/reports/clinic-revenue';
  static const String reportDoctorRevenue = '/reports/doctor-revenue';
  static const String reportPharmacySales = '/reports/pharmacy-sales';
  static const String reportPatientVisits = '/reports/patient-visits';
  static const String reportAppointments = '/reports/appointments';
  static const String reportPayments = '/reports/payments';
}
