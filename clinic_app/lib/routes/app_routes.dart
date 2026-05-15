import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/clinic_register_screen.dart';
import '../screens/super_admin/super_admin_dashboard.dart';
import '../screens/super_admin/all_clinics_screen.dart';
import '../screens/super_admin/pending_clinics_screen.dart';
import '../screens/super_admin/system_stats_screen.dart';
import '../screens/super_admin/super_admin_revenue_screen.dart';
import '../screens/super_admin/subscription_plans_screen.dart';
import '../screens/clinic_admin/clinic_admin_dashboard.dart';
import '../screens/clinic_admin/doctors_screen.dart';
import '../screens/clinic_admin/departments_screen.dart';
import '../screens/clinic_admin/receptionists_screen.dart';
import '../screens/clinic_admin/pharmacy_users_screen.dart';
import '../screens/clinic_admin/patients_screen.dart';
import '../screens/clinic_admin/appointments_screen.dart';
import '../screens/clinic_admin/clinic_admin_revenue_screen.dart';
import '../screens/clinic_admin/reports_screen.dart';
import '../screens/clinic_admin/settings_screen.dart';
import '../screens/receptionist/receptionist_dashboard.dart';
import '../screens/receptionist/patients_screen.dart';
import '../screens/receptionist/token_queue_screen.dart';
import '../screens/receptionist/book_appointment_screen.dart';
import '../screens/receptionist/billing_screen.dart';
import '../screens/receptionist/receipts_screen.dart';
import '../screens/doctor/doctor_dashboard.dart';
import '../screens/doctor/doctor_queue_screen.dart';
import '../screens/doctor/prescriptions_screen.dart';
import '../screens/doctor/assistants_screen.dart';
import '../screens/doctor/doctor_earnings_screen.dart';
import '../screens/doctor/doctor_schedule_screen.dart';
import '../screens/assistant/assistant_dashboard.dart';
import '../screens/assistant/assistant_queue_screen.dart';
import '../screens/pharmacy/pharmacy_dashboard.dart';
import '../screens/pharmacy/medicine_inventory_screen.dart';
import '../screens/pharmacy/prescription_orders_screen.dart';
import '../screens/pharmacy/pharmacy_sales_screen.dart';
import '../screens/pharmacy/low_stock_screen.dart';
import '../screens/pharmacy/expiry_alerts_screen.dart';
import '../screens/pharmacy/pharmacy_reports_screen.dart';
import '../screens/patient/patient_dashboard.dart';
import '../screens/patient/my_doctors_screen.dart';
import '../screens/patient/my_appointments_screen.dart';
import '../screens/patient/my_prescriptions_screen.dart';
import '../screens/patient/medical_records_screen.dart';
import '../screens/patient/my_bills_screen.dart';
import '../screens/reports/clinic_revenue_report_screen.dart';
import '../screens/reports/doctor_revenue_report_screen.dart';
import '../screens/reports/pharmacy_sales_report_screen.dart';
import '../screens/reports/patient_visits_report_screen.dart';
import '../screens/reports/appointments_report_screen.dart';
import '../screens/reports/payments_report_screen.dart';

class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String clinicRegister = '/register-clinic';
  static const String profile = '/profile';

  // ── Super Admin ───────────────────────────────────────────────────────────
  static const String superAdminDashboard = '/super-admin';
  static const String clinics = '/super-admin/clinics';
  static const String pendingApprovals = '/super-admin/pending';
  static const String systemStats = '/super-admin/stats';
  static const String superAdminRevenue = '/super-admin/revenue';
  static const String subscriptions = '/super-admin/subscriptions';

  // ── Clinic Admin ──────────────────────────────────────────────────────────
  static const String clinicAdminDashboard = '/clinic-admin';
  static const String doctors = '/clinic-admin/doctors';
  static const String departments = '/clinic-admin/departments';
  static const String receptionists = '/clinic-admin/receptionists';
  static const String pharmacyUsers = '/clinic-admin/pharmacy-users';
  static const String patients = '/clinic-admin/patients';
  static const String appointments = '/clinic-admin/appointments';
  static const String clinicAdminRevenue = '/clinic-admin/revenue';
  static const String reports = '/clinic-admin/reports';
  static const String settings = '/clinic-admin/settings';

  // ── Receptionist ──────────────────────────────────────────────────────────
  static const String receptionistDashboard = '/receptionist';
  static const String recPatients = '/receptionist/patients';
  static const String tokenQueue = '/receptionist/queue';
  static const String bookAppointment = '/receptionist/book-appointment';
  static const String billing = '/receptionist/billing';
  static const String receipts = '/receptionist/receipts';

  // ── Doctor ────────────────────────────────────────────────────────────────
  static const String doctorDashboard = '/doctor';
  static const String queue = '/doctor/queue';
  static const String prescriptions = '/prescriptions';
  static const String earnings = '/doctor/earnings';
  static const String assistants = '/doctor/assistants';
  static const String doctorSchedule = '/doctor/schedule';

  // ── Other roles ───────────────────────────────────────────────────────────
  static const String assistantDashboard = '/assistant';
  static const String assistantQueue = '/assistant/queue';
  static const String pharmacyDashboard = '/pharmacy';
  static const String inventory = '/pharmacy/inventory';
  static const String sales = '/pharmacy/sales';
  static const String pharmacyOrders = '/pharmacy/orders';
  static const String lowStock = '/pharmacy/low-stock';
  static const String expiryAlerts = '/pharmacy/expiry-alerts';
  static const String pharmacyReports = '/pharmacy/reports';
  static const String patientDashboard = '/patient';
  static const String myDoctors = '/patient/doctors';
  static const String myAppointments = '/patient/appointments';
  static const String myPrescriptions = '/patient/prescriptions';
  static const String medicalRecords = '/patient/medical-records';
  static const String myBills = '/patient/bills';
  static const String payments = '/payments';
  static const String revenue = '/revenue';

  // ── Reports ────────────────────────────────────────────────────────────────
  static const String reportClinicRevenue = '/reports/clinic-revenue';
  static const String reportDoctorRevenue = '/reports/doctor-revenue';
  static const String reportPharmacySales = '/reports/pharmacy-sales';
  static const String reportPatientVisits = '/reports/patient-visits';
  static const String reportAppointments = '/reports/appointments';
  static const String reportPayments = '/reports/payments';

  // ── Route map ─────────────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        clinicRegister: (_) => const ClinicRegisterScreen(),

        // Super Admin
        superAdminDashboard: (_) => const SuperAdminDashboard(),
        clinics: (_) => const AllClinicsScreen(),
        pendingApprovals: (_) => const PendingClinicsScreen(),
        systemStats: (_) => const SystemStatsScreen(),
        superAdminRevenue: (_) => const SuperAdminRevenueScreen(),
        subscriptions: (_) => const SubscriptionPlansScreen(),

        // Clinic Admin
        clinicAdminDashboard: (_) => const ClinicAdminDashboard(),
        doctors: (_) => const DoctorsScreen(),
        departments: (_) => const DepartmentsScreen(),
        receptionists: (_) => const ReceptionistsScreen(),
        pharmacyUsers: (_) => const PharmacyUsersScreen(),
        patients: (_) => const PatientsScreen(),
        appointments: (_) => const AppointmentsScreen(),
        clinicAdminRevenue: (_) => const ClinicAdminRevenueScreen(),
        reports: (_) => const ReportsScreen(),
        settings: (_) => const SettingsScreen(),

        // Receptionist
        receptionistDashboard: (_) => const ReceptionistDashboard(),
        recPatients: (_) => const ReceptionistPatientsScreen(),
        tokenQueue: (_) => const TokenQueueScreen(),
        bookAppointment: (_) => const BookAppointmentScreen(),
        billing: (_) => const BillingScreen(),
        receipts: (_) => const ReceiptsScreen(),

        // Doctor
        doctorDashboard: (_) => const DoctorDashboard(),
        queue: (_) => const DoctorQueueScreen(),
        prescriptions: (_) => const PrescriptionsScreen(),
        earnings: (_) => const DoctorEarningsScreen(),
        assistants: (_) => const DoctorAssistantsScreen(),
        doctorSchedule: (_) => const DoctorScheduleScreen(),

        // Other roles
        assistantDashboard: (_) => const AssistantDashboard(),
        assistantQueue: (_) => const AssistantQueueScreen(),
        pharmacyDashboard: (_) => const PharmacyDashboard(),
        inventory: (_) => const MedicineInventoryScreen(),
        pharmacyOrders: (_) => const PrescriptionOrdersScreen(),
        sales: (_) => const PharmacySalesScreen(),
        lowStock: (_) => const LowStockScreen(),
        expiryAlerts: (_) => const ExpiryAlertsScreen(),
        pharmacyReports: (_) => const PharmacyReportsScreen(),
        patientDashboard: (_) => const PatientDashboard(),
        myDoctors: (_) => const MyDoctorsScreen(),
        myAppointments: (_) => const MyAppointmentsScreen(),
        myPrescriptions: (_) => const MyPrescriptionsScreen(),
        medicalRecords: (_) => const MedicalRecordsScreen(),
        myBills: (_) => const MyBillsScreen(),
        reportClinicRevenue: (_) => const ClinicRevenueReportScreen(),
        reportDoctorRevenue: (_) => const DoctorRevenueReportScreen(),
        reportPharmacySales: (_) => const PharmacySalesReportScreen(),
        reportPatientVisits: (_) => const PatientVisitsReportScreen(),
        reportAppointments: (_) => const AppointmentsReportScreen(),
        reportPayments: (_) => const PaymentsReportScreen(),
      };

  // ── Redirect by role ──────────────────────────────────────────────────────
  static String dashboardForRole(String role) {
    switch (role) {
      case 'super_admin':
        return superAdminDashboard;
      case 'clinic_admin':
        return clinicAdminDashboard;
      case 'doctor':
        return doctorDashboard;
      case 'assistant':
        return assistantDashboard;
      case 'receptionist':
        return receptionistDashboard;
      case 'pharmacy':
        return pharmacyDashboard;
      case 'patient':
        return patientDashboard;
      default:
        return login;
    }
  }
}
