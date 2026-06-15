import 'dart:ui';
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
          _SidebarItem('Token Queue', Icons.queue_rounded, AppRoutes.tokenQueue),
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
    final roleColors = AppColors.roleGradient(role);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D2137),
                const Color(0xFF0A1E30),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: .08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D2137).withValues(alpha: .40),
                blurRadius: 48,
                spreadRadius: -8,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: .06),
                      Colors.transparent,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: .07),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .40),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
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
                            'MedCare',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -.3,
                            ),
                          ),
                          Text(
                            'Clinic Management',
                            style: TextStyle(
                              color: Color(0xFF6A9BAA),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // User card
              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: .06),
                        Colors.white.withValues(alpha: .03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: roleColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .25),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user != null && user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
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
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              AppStrings.roleLabel(role),
                              style: const TextStyle(
                                color: Color(0xFF5A9DAA),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: .5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nav label
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NAVIGATION',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .28),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // Nav items
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: items
                      .map((item) => _NavItem(
                            item: item,
                            active: currentRoute == item.route,
                          ))
                      .toList(),
                ),
              ),

              // Bottom section
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: .07)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  children: [
                    _NavItem(
                      item: _SidebarItem(AppStrings.myProfile,
                          Icons.person_outline_rounded, AppRoutes.profile),
                      active: currentRoute == AppRoutes.profile,
                    ),
                    _LogoutTile(),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: active
              ? null
              : () => Navigator.pushReplacementNamed(context, item.route),
          hoverColor: Colors.white.withValues(alpha: .06),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: .45),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: .55),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .6),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final auth = context.read<AuthService>();
          await auth.logout();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.login, (_) => false);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.logout_rounded,
                  size: 18, color: AppColors.danger.withValues(alpha: .80)),
              const SizedBox(width: 12),
              Text(
                AppStrings.logout,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.danger.withValues(alpha: .80),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
