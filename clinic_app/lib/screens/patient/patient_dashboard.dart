import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
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
              color: AppColors.primary),
          DashboardStat(
              title: 'Appointments',
              value: Helpers.formatNumber(p.appointments.length),
              icon: Icons.calendar_month_rounded,
              color: AppColors.accent),
          DashboardStat(
              title: 'Prescriptions',
              value: Helpers.formatNumber(p.prescriptions.length),
              icon: Icons.receipt_long_rounded,
              color: AppColors.info),
          DashboardStat(
              title: 'Bills',
              value: Helpers.formatNumber(p.bills.length),
              icon: Icons.payments_rounded,
              color: AppColors.warning),
        ];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Welcome back,',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(user?.name ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Text(user?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisExtent: 150,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16),
            itemCount: stats.length,
            itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
          ),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _action('Appointments', Icons.calendar_month_rounded,
                AppRoutes.myAppointments),
            _action('Prescriptions', Icons.receipt_long_rounded,
                AppRoutes.myPrescriptions),
            _action('Medical Records', Icons.folder_shared_rounded,
                AppRoutes.medicalRecords),
            _action('Bills', Icons.payments_rounded, AppRoutes.myBills),
          ]),
          const SizedBox(height: 24),
          const Text('Upcoming Appointment',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            const Text('No upcoming appointments.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            Card(
                child: ListTile(
              leading: const Icon(Icons.event_available_rounded,
                  color: AppColors.primary),
              title: Text(upcoming.first.doctorName),
              subtitle: Text(
                  '${Helpers.formatDate(upcoming.first.appointmentDate)} ${Helpers.formatTime(upcoming.first.appointmentTime)}'),
            )),
        ]);
      }),
    );
  }

  Widget _action(String label, IconData icon, String route) =>
      ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon),
        label: Text(label),
      );
}
