import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_dashboard.dart';
import '../../core/widgets/queue_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../routes/app_routes.dart';
import 'consultation_screen.dart';
import 'doctor_patient_profile_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await DoctorService.dashboard();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.doctorDashboard,
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          color: AppColors.primaryDark,
        )
      ],
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _DoctorDashboardBody(data: _data, onRefresh: _load),
    );
  }
}

class _DoctorDashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  const _DoctorDashboardBody(
      {required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final queue = (data['today_queue'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final recentPatients = (data['recent_patients'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final followups = (data['upcoming_followups'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final stats = [
      DashboardStat(
        title: "Today's Appointments",
        value: Helpers.formatNumber(data['today_appointments'] as num?),
        icon: Icons.calendar_today_rounded,
        color: AppColors.primary,
        subtitle: 'Scheduled',
      ),
      DashboardStat(
        title: 'Waiting',
        value: Helpers.formatNumber(data['waiting_patients'] as num?),
        icon: Icons.hourglass_bottom_rounded,
        color: AppColors.warning,
        subtitle: 'In queue',
      ),
      DashboardStat(
        title: 'Completed',
        value: Helpers.formatNumber(data['completed_today'] as num?),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        subtitle: 'Consultations',
      ),
      DashboardStat(
        title: 'Monthly Earning',
        value: Helpers.formatCurrency(data['monthly_earning'] as num?),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.glowEmerald,
        subtitle: 'This month',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumDashboardOverview(
          eyebrow: 'Clinical overview',
          headline: "Everything you need for today's care.",
          description:
              'Appointments, queue, follow-ups and earnings.',
          heroIcon: Icons.medical_services_rounded,
          stats: stats,
          actions: [
            DashboardQuickAction(
              label: 'Open Queue',
              icon: Icons.queue_rounded,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, AppRoutes.queue),
            ),
            DashboardQuickAction(
              label: 'Schedule',
              icon: Icons.schedule_rounded,
              color: AppColors.glowBlue,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.doctorSchedule),
            ),
            DashboardQuickAction(
              label: 'Prescriptions',
              icon: Icons.receipt_long_rounded,
              color: AppColors.glowPurple,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.prescriptions),
            ),
            DashboardQuickAction(
              label: 'Earnings',
              icon: Icons.payments_rounded,
              color: AppColors.glowEmerald,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.earnings),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Two column layout for tablets/desktop
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _QueueSection(
                      queue: queue,
                      onRefresh: onRefresh,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _RecentPatientsSection(patients: recentPatients),
                        const SizedBox(height: 16),
                        _FollowupsSection(followups: followups),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _QueueSection(queue: queue, onRefresh: onRefresh),
                const SizedBox(height: 16),
                _RecentPatientsSection(patients: recentPatients),
                const SizedBox(height: 16),
                _FollowupsSection(followups: followups),
              ],
            );
          },
        ),
      ],
    );
  }

}

class _QueueSection extends StatelessWidget {
  final List<Map<String, dynamic>> queue;
  final Future<void> Function() onRefresh;

  const _QueueSection({required this.queue, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PremiumDashboardSection(
          title: "Today's Queue",
          trailing: TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.queue),
            child: Text('Open',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
          child: queue.isEmpty
              ? const _EmptyState(text: 'No patients waiting.')
              : Column(
                  children: queue.take(8).map((raw) {
                    final appt = _apptFrom(raw);
                    return QueueCard(
                      appointment: appt,
                      primaryLabel: 'Start',
                      primaryIcon: Icons.play_arrow_rounded,
                      onPrimary: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ConsultationScreen(appointment: appt),
                            ),
                          ).then((_) => onRefresh()),
                      onTap: () {
                        if (appt.patientId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorPatientProfileScreen(
                                  patientId: appt.patientId!),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  AppointmentModel _apptFrom(Map<String, dynamic> raw) {
    final n = raw.containsKey('patient_name')
        ? raw
        : <String, dynamic>{
            ...raw,
            'patient_name': raw['patient'] is Map
                ? (raw['patient'] as Map)['name']
                : '',
            'doctor_name': raw['doctor'] is Map
                ? (raw['doctor'] as Map)['name']
                : '',
          };
    return AppointmentModel.fromJson(n);
  }
}

class _RecentPatientsSection extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  const _RecentPatientsSection({required this.patients});

  @override
  Widget build(BuildContext context) {
    return PremiumDashboardSection(
      title: 'Recent Patients',
      child: patients.isEmpty
          ? const _EmptyState(text: 'No recent patients.')
          : Column(
              children: patients
                  .take(5)
                  .map((p) => _PatientRow(patient: p))
                  .toList(),
            ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _PatientRow({required this.patient});

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? 'Patient';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .22),
                  AppColors.primaryLight.withValues(alpha: .10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: .28)),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.textPrimary)),
                if ((patient['phone'] as String? ?? '').isNotEmpty)
                  Text(patient['phone'] as String,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _FollowupsSection extends StatelessWidget {
  final List<Map<String, dynamic>> followups;
  const _FollowupsSection({required this.followups});

  @override
  Widget build(BuildContext context) {
    return PremiumDashboardSection(
      title: 'Upcoming Follow-ups',
      child: followups.isEmpty
          ? const _EmptyState(text: 'No follow-ups scheduled.')
          : Column(
              children: followups
                  .take(5)
                  .map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accentSurface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                    color: AppColors.accent
                                        .withValues(alpha: .3)),
                              ),
                              child: const Icon(
                                  Icons.event_repeat_rounded,
                                  color: AppColors.accent,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prescription #${f['id'] ?? '—'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    Helpers.formatDate(
                                        f['follow_up_date'] as String? ??
                                            ''),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded,
                size: 36, color: AppColors.textHint.withValues(alpha: .5)),
            const SizedBox(height: 8),
            Text(text,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
