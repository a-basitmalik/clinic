import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/premium_dashboard.dart';
import '../../core/widgets/premium_surface.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/dashboard_stat_model.dart';
import '../../routes/app_routes.dart';
import 'patient_portal_base.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with PatientPortalLoader {
  @override
  void initState() {
    super.initState();
    loadPortal();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final firstName = user?.name.split(' ').first ?? '';
    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.patientDashboard,
      body: portalState((p) {
        final upcoming = p.appointments.where((a) => a.isActive).toList();
        final stats = [
          DashboardStat(
            title: 'Total Visits',
            value: Helpers.formatNumber(p.totalVisits),
            icon: Icons.history_rounded,
            color: AppColors.primary,
            subtitle: 'All time',
          ),
          DashboardStat(
            title: 'Appointments',
            value: Helpers.formatNumber(p.appointments.length),
            icon: Icons.calendar_month_rounded,
            color: AppColors.glowBlue,
            subtitle: 'Booked',
          ),
          DashboardStat(
            title: 'Prescriptions',
            value: Helpers.formatNumber(p.prescriptions.length),
            icon: Icons.receipt_long_rounded,
            color: AppColors.glowPurple,
            subtitle: 'Issued',
          ),
          DashboardStat(
            title: 'Bills',
            value: Helpers.formatNumber(p.bills.length),
            icon: Icons.payments_rounded,
            color: AppColors.warning,
            subtitle: 'Generated',
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumDashboardOverview(
              eyebrow: firstName.isNotEmpty
                  ? 'Welcome back, $firstName'
                  : 'Welcome back',
              headline: 'Your health journey, beautifully organized.',
              description:
                  'Appointments, prescriptions and records in one place.',
              heroIcon: Icons.favorite_rounded,
              stats: stats,
              actions: [
                DashboardQuickAction(
                  label: 'Appointments',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.myAppointments),
                ),
                DashboardQuickAction(
                  label: 'Prescriptions',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.glowPurple,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.myPrescriptions),
                ),
                DashboardQuickAction(
                  label: 'Medical Records',
                  icon: Icons.folder_shared_rounded,
                  color: AppColors.glowBlue,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.medicalRecords),
                ),
                DashboardQuickAction(
                  label: 'My Bills',
                  icon: Icons.payments_rounded,
                  color: AppColors.warning,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.myBills),
                ),
              ],
            ),
            const SizedBox(height: 28),

            PremiumDashboardSection(
              title: 'Upcoming Appointment',
              child: upcoming.isEmpty
                  ? const _EmptyUpcoming()
                  : _UpcomingAppointmentCard(appt: upcoming.first),
            ),

            if (p.prescriptions.isNotEmpty) ...[
              const SizedBox(height: 24),
              PremiumDashboardSection(
                title: 'Recent Prescriptions',
                trailing: TextButton(
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.myPrescriptions),
                  child: Text('View all',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
                child: Column(
                  children: p.prescriptions
                      .take(3)
                      .map((rx) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: .22)),
                                  ),
                                  child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppColors.primary,
                                      size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Prescription #${rx.id}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        Helpers.formatDate(rx.createdAt),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 18, color: AppColors.textMuted),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  final dynamic appt;
  const _UpcomingAppointmentCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: [AppColors.primary, AppColors.primaryDark],
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .3)),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.doctorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Helpers.formatDate(appt.appointmentDate)}  •  ${Helpers.formatTime(appt.appointmentTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: .80),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .3)),
            ),
            child: const Text(
              'Upcoming',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available_rounded,
                size: 36,
                color: AppColors.textHint.withValues(alpha: .5)),
            const SizedBox(height: 8),
            const Text(
              'No upcoming appointments.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
