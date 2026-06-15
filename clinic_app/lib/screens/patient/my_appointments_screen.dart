import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/status_badge.dart';
import '../../routes/app_routes.dart';
import 'patient_portal_base.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with PatientPortalLoader {
  @override
  void initState() {
    super.initState();
    loadPortal();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        title: 'My Appointments',
        currentRoute: AppRoutes.myAppointments,
        body: portalState((p) {
          final appts = p.appointments;
          if (appts.isEmpty)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: .16),
                          AppColors.primaryLight.withValues(alpha: .07),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: .22)),
                    ),
                    child: const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('No appointments found.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                ]),
              ),
            );
          return Column(
            children: appts.map((a) => _ApptCard(appt: a)).toList(),
          );
        }),
      );
}

class _ApptCard extends StatelessWidget {
  final dynamic appt;
  const _ApptCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .88),
            Colors.white.withValues(alpha: .65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: .06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .18),
                  AppColors.primaryLight.withValues(alpha: .08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: .25)),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dr. ${appt.doctorName ?? '—'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text(
                '${Helpers.formatDate(appt.appointmentDate)}  •  ${Helpers.formatTime(appt.appointmentTime)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text('Token #${appt.tokenNumber}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
          StatusBadge(appt.status),
        ]),
      ),
    );
  }
}
