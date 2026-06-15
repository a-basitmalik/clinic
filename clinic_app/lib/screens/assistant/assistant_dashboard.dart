import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/assistant_service.dart';
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
import 'assistant_queue_screen.dart';

class AssistantDashboard extends StatefulWidget {
  const AssistantDashboard({super.key});

  @override
  State<AssistantDashboard> createState() => _AssistantDashboardState();
}

class _AssistantDashboardState extends State<AssistantDashboard> {
  Map<String, dynamic> _data = {};
  List<AppointmentModel> _queue = [];
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
      _data = await AssistantService.dashboard();
      _queue = await AssistantService.queue();
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
    final stats = [
      DashboardStat(
        title: 'Queue Size',
        value: Helpers.formatNumber(
            (_data['queue_size'] ?? _queue.length) as num?),
        icon: Icons.queue_rounded,
        color: AppColors.primary,
        subtitle: 'Active patients',
      ),
      DashboardStat(
        title: 'Waiting',
        value: Helpers.formatNumber(_data['waiting'] as num?),
        icon: Icons.hourglass_bottom_rounded,
        color: AppColors.warning,
        subtitle: 'In queue now',
      ),
      DashboardStat(
        title: 'Vitals Today',
        value: Helpers.formatNumber(_data['vitals_today'] as num?),
        icon: Icons.monitor_heart_rounded,
        color: AppColors.glowBlue,
        subtitle: 'Recorded',
      ),
      DashboardStat(
        title: 'Reports Today',
        value: Helpers.formatNumber(_data['reports_today'] as num?),
        icon: Icons.upload_file_rounded,
        color: AppColors.glowPurple,
        subtitle: 'Uploaded',
      ),
    ];

    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.assistantDashboard,
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumDashboardOverview(
                      eyebrow: 'Care coordination',
                      headline:
                          'Keep every patient moving smoothly.',
                      description:
                          'Queue, vitals and reports ready for action.',
                      heroIcon: Icons.monitor_heart_rounded,
                      stats: stats,
                      actions: [
                        DashboardQuickAction(
                          label: 'Open Queue',
                          icon: Icons.queue_rounded,
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.assistantQueue),
                        ),
                        DashboardQuickAction(
                          label: 'Take Vitals',
                          icon: Icons.monitor_heart_rounded,
                          color: AppColors.glowBlue,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.assistantQueue),
                        ),
                        DashboardQuickAction(
                          label: 'Upload Report',
                          icon: Icons.upload_file_rounded,
                          color: AppColors.glowPurple,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.assistantQueue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    PremiumDashboardSection(
                      title: "Doctor's Queue",
                      trailing: TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.assistantQueue),
                        child: Text('Open queue',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                      child: _queue.isEmpty
                          ? const _EmptyQueue()
                          : Column(
                              children: _queue
                                  .take(5)
                                  .map((a) => QueueCard(
                                        appointment: a,
                                        primaryLabel: 'Actions',
                                        primaryIcon: Icons.tune_rounded,
                                        onPrimary: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AssistantQueueScreen(
                                                    initialAppointment:
                                                        a),
                                          ),
                                        ).then((_) => _load()),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.queue_rounded,
                size: 36,
                color: AppColors.textHint.withValues(alpha: .5)),
            const SizedBox(height: 8),
            const Text('No patients in queue.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
