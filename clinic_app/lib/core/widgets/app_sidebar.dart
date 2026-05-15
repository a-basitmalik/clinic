import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../services/auth_service.dart';
import '../../routes/app_routes.dart';

class _SidebarItem {
  final String label;
  final IconData icon;
  final String route;
  const _SidebarItem(this.label, this.icon, this.route);
}

class AppSidebar extends StatelessWidget {
  final String currentRoute;

  const AppSidebar({super.key, required this.currentRoute});

  static List<_SidebarItem> _itemsForRole(String role) {
    switch (role) {
      case 'super_admin':
        return [
          _SidebarItem(AppStrings.dashboard, Icons.dashboard_rounded,
              AppRoutes.superAdminDashboard),
          _SidebarItem(AppStrings.clinics, Icons.local_hospital_rounded,
              AppRoutes.clinics),
          _SidebarItem(AppStrings.pendingApprovals,
              Icons.pending_actions_rounded, AppRoutes.pendingApprovals),
          _SidebarItem(
              'System Stats', Icons.analytics_rounded, AppRoutes.systemStats),
          _SidebarItem('Revenue', Icons.account_balance_wallet_rounded,
              AppRoutes.superAdminRevenue),
          _SidebarItem('Payments Report', Icons.payments_rounded,
              AppRoutes.reportPayments),
          _SidebarItem('Subscriptions', Icons.card_membership_rounded,
              AppRoutes.subscriptions),
        ];
      case 'clinic_admin':
        return [
          _SidebarItem(AppStrings.dashboard, Icons.dashboard_rounded,
              AppRoutes.clinicAdminDashboard),
          _SidebarItem(AppStrings.doctors, Icons.medical_services_rounded,
              AppRoutes.doctors),
          _SidebarItem(AppStrings.departments, Icons.category_rounded,
              AppRoutes.departments),
          _SidebarItem(AppStrings.receptionists, Icons.support_agent_rounded,
              AppRoutes.receptionists),
          _SidebarItem('Pharmacy Users', Icons.local_pharmacy_rounded,
              AppRoutes.pharmacyUsers),
          _SidebarItem(AppStrings.patients, Icons.people_alt_rounded,
              AppRoutes.patients),
          _SidebarItem(AppStrings.appointments, Icons.calendar_month_rounded,
              AppRoutes.appointments),
          _SidebarItem('Revenue', Icons.account_balance_wallet_rounded,
              AppRoutes.clinicAdminRevenue),
          _SidebarItem(
              AppStrings.reports, Icons.bar_chart_rounded, AppRoutes.reports),
          _SidebarItem('Clinic Revenue', Icons.query_stats_rounded,
              AppRoutes.reportClinicRevenue),
          _SidebarItem('Appointments Report', Icons.event_note_rounded,
              AppRoutes.reportAppointments),
          _SidebarItem('Patient Visits', Icons.groups_rounded,
              AppRoutes.reportPatientVisits),
          _SidebarItem('Payments Report', Icons.payments_rounded,
              AppRoutes.reportPayments),
          _SidebarItem('Settings', Icons.settings_rounded, AppRoutes.settings),
        ];
      case 'doctor':
        return [
          _SidebarItem(AppStrings.dashboard, Icons.dashboard_rounded,
              AppRoutes.doctorDashboard),
          _SidebarItem(AppStrings.queue, Icons.queue_rounded, AppRoutes.queue),
          _SidebarItem(
              'Schedule', Icons.schedule_rounded, AppRoutes.doctorSchedule),
          _SidebarItem(AppStrings.prescriptions, Icons.receipt_long_rounded,
              AppRoutes.prescriptions),
          _SidebarItem(AppStrings.earnings,
              Icons.account_balance_wallet_rounded, AppRoutes.earnings),
          _SidebarItem('Reports', Icons.bar_chart_rounded,
              AppRoutes.reportDoctorRevenue),
          _SidebarItem(
              AppStrings.assistants, Icons.group_rounded, AppRoutes.assistants),
        ];
      case 'assistant':
        return [
          _SidebarItem(AppStrings.dashboard, Icons.dashboard_rounded,
              AppRoutes.assistantDashboard),
          _SidebarItem(
              AppStrings.queue, Icons.queue_rounded, AppRoutes.assistantQueue),
        ];
      case 'receptionist':
        return [
          _SidebarItem(AppStrings.dashboard, Icons.dashboard_rounded,
              AppRoutes.receptionistDashboard),
          _SidebarItem(
              'Patients', Icons.people_alt_rounded, AppRoutes.recPatients),
          _SidebarItem(
              'Token Queue', Icons.queue_rounded, AppRoutes.tokenQueue),
          _SidebarItem('Book Appointment', Icons.calendar_month_rounded,
              AppRoutes.bookAppointment),
          _SidebarItem('Billing', Icons.payments_rounded, AppRoutes.billing),
          _SidebarItem(
              'Receipts', Icons.receipt_long_rounded, AppRoutes.receipts),
          _SidebarItem(
              'Reports', Icons.bar_chart_rounded, AppRoutes.reportAppointments),
        ];
      case 'pharmacy':
        return [
          _SidebarItem(AppStrings.dashboard, Icons.dashboard_rounded,
              AppRoutes.pharmacyDashboard),
          _SidebarItem(AppStrings.inventory, Icons.inventory_2_rounded,
              AppRoutes.inventory),
          _SidebarItem('Prescription Orders', Icons.assignment_rounded,
              AppRoutes.pharmacyOrders),
          _SidebarItem(
              AppStrings.sales, Icons.point_of_sale_rounded, AppRoutes.sales),
          _SidebarItem(
              'Low Stock', Icons.warning_amber_rounded, AppRoutes.lowStock),
          _SidebarItem('Expiry Alerts', Icons.event_busy_rounded,
              AppRoutes.expiryAlerts),
          _SidebarItem(AppStrings.reports, Icons.bar_chart_rounded,
              AppRoutes.pharmacyReports),
          _SidebarItem('Sales Report', Icons.query_stats_rounded,
              AppRoutes.reportPharmacySales),
        ];
      case 'patient':
        return [
          _SidebarItem(AppStrings.dashboard, Icons.dashboard_rounded,
              AppRoutes.patientDashboard),
          _SidebarItem('My Doctors', Icons.medical_services_rounded,
              AppRoutes.myDoctors),
          _SidebarItem(AppStrings.appointments, Icons.calendar_month_rounded,
              AppRoutes.myAppointments),
          _SidebarItem(AppStrings.prescriptions, Icons.receipt_long_rounded,
              AppRoutes.myPrescriptions),
          _SidebarItem('Medical Records', Icons.folder_shared_rounded,
              AppRoutes.medicalRecords),
          _SidebarItem('My Bills', Icons.payments_rounded, AppRoutes.myBills),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final role = user?.role ?? '';
    final items = _itemsForRole(role);

    return Container(
      width: 260,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Header
          Container(
            color: AppColors.sidebarHeader,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CMS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                      Text(
                        'Clinic Management',
                        style: TextStyle(
                            color: AppColors.sidebarText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User info
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.sidebarActive,
                  child: Text(
                    user != null && user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppStrings.roleLabel(role),
                        style: const TextStyle(
                            color: AppColors.sidebarText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.sidebarHover, height: 1),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: items
                  .map((item) => _NavItem(
                        item: item,
                        active: currentRoute == item.route,
                      ))
                  .toList(),
            ),
          ),

          // Bottom: profile + logout
          const Divider(color: AppColors.sidebarHover, height: 1),
          _NavItem(
            item: _SidebarItem(AppStrings.myProfile,
                Icons.person_outline_rounded, AppRoutes.profile),
            active: currentRoute == AppRoutes.profile,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _LogoutTile(),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _SidebarItem item;
  final bool active;

  const _NavItem({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: active
          ? BoxDecoration(
              color: AppColors.sidebarActive,
              borderRadius: BorderRadius.circular(8))
          : null,
      child: ListTile(
        dense: true,
        leading: Icon(
          item.icon,
          size: 20,
          color: active ? AppColors.sidebarIconActive : AppColors.sidebarIcon,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.sidebarTextActive : AppColors.sidebarText,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        hoverColor: AppColors.sidebarHover,
        onTap: active
            ? null
            : () => Navigator.pushReplacementNamed(context, item.route),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.logout_rounded,
          size: 20, color: AppColors.sidebarIcon),
      title: const Text(
        AppStrings.logout,
        style: TextStyle(fontSize: 13, color: AppColors.sidebarText),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: AppColors.sidebarHover,
      onTap: () async {
        final auth = context.read<AuthService>();
        await auth.logout();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (_) => false);
        }
      },
    );
  }
}
