import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
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
    setState(() { _loading = true; _error = null; });
    try {
      _data = await DoctorService.dashboard();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.doctorDashboard,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
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

  const _DoctorDashboardBody({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final queue = (data['today_queue'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final recentPatients = (data['recent_patients'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final followups = (data['upcoming_followups'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final stats = [
      DashboardStat(title: "Today's Appointments", value: Helpers.formatNumber(data['today_appointments'] as num?), icon: Icons.calendar_today_rounded, color: AppColors.primary),
      DashboardStat(title: 'Waiting', value: Helpers.formatNumber(data['waiting_patients'] as num?), icon: Icons.hourglass_bottom_rounded, color: AppColors.warning),
      DashboardStat(title: 'Completed', value: Helpers.formatNumber(data['completed_today'] as num?), icon: Icons.check_circle_rounded, color: AppColors.success),
      DashboardStat(title: 'Monthly Earning', value: Helpers.formatCurrency(data['monthly_earning'] as num?), icon: Icons.account_balance_wallet_rounded, color: AppColors.accent),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisExtent: 150, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: stats.length,
        itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
      ),
      const SizedBox(height: 24),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 2, child: _Section(
          title: "Today's Queue",
          child: queue.isEmpty
              ? const _Empty(text: 'No patients waiting.')
              : Column(children: queue.take(8).map((raw) {
                  final appointment = _appointmentFromRaw(raw);
                  return QueueCard(
                    appointment: appointment,
                    primaryLabel: 'Start',
                    primaryIcon: Icons.play_arrow_rounded,
                    onPrimary: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConsultationScreen(appointment: appointment))).then((_) => onRefresh()),
                    onTap: () {
                      if (appointment.patientId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientProfileScreen(patientId: appointment.patientId!)));
                      }
                    },
                  );
                }).toList()),
        )),
        const SizedBox(width: 16),
        Expanded(child: Column(children: [
          _Section(
            title: 'Recent Patients',
            child: recentPatients.isEmpty
                ? const _Empty(text: 'No recent patients.')
                : Column(children: recentPatients.take(5).map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: AppColors.primarySurface, child: Icon(Icons.person_rounded, color: AppColors.primary)),
                    title: Text(p['name'] as String? ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p['phone'] as String? ?? ''),
                  )).toList()),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Upcoming Follow-ups',
            child: followups.isEmpty
                ? const _Empty(text: 'No follow-ups.')
                : Column(children: followups.take(5).map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_repeat_rounded, color: AppColors.accent),
                    title: Text('Prescription #${p['id'] ?? ''}'),
                    subtitle: Text(Helpers.formatDate(p['follow_up_date'] as String? ?? '')),
                  )).toList()),
          ),
        ])),
      ]),
    ]);
  }

  AppointmentModel _appointmentFromRaw(Map<String, dynamic> raw) {
    final normalized = raw.containsKey('patient_name')
        ? raw
        : <String, dynamic>{
            ...raw,
            'patient_name': raw['patient'] is Map ? (raw['patient'] as Map)['name'] : '',
            'doctor_name': raw['doctor'] is Map ? (raw['doctor'] as Map)['name'] : '',
          };
    return AppointmentModel.fromJson(normalized);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(child: Text(text, style: const TextStyle(color: AppColors.textSecondary))),
  );
}
