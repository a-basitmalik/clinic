import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/assistant_service.dart';
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
    setState(() { _loading = true; _error = null; });
    try {
      _data = await AssistantService.dashboard();
      _queue = await AssistantService.queue();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      DashboardStat(title: 'Queue Size', value: Helpers.formatNumber((_data['queue_size'] ?? _queue.length) as num?), icon: Icons.queue_rounded, color: AppColors.primary),
      DashboardStat(title: 'Waiting', value: Helpers.formatNumber(_data['waiting'] as num?), icon: Icons.hourglass_bottom_rounded, color: AppColors.warning),
      DashboardStat(title: 'Vitals Today', value: Helpers.formatNumber(_data['vitals_today'] as num?), icon: Icons.monitor_heart_rounded, color: AppColors.accent),
      DashboardStat(title: 'Reports Today', value: Helpers.formatNumber(_data['reports_today'] as num?), icon: Icons.upload_file_rounded, color: AppColors.info),
    ];
    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.assistantDashboard,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisExtent: 150, crossAxisSpacing: 16, mainAxisSpacing: 16),
                    itemCount: stats.length,
                    itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Expanded(child: Text("Doctor's Queue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                        TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.assistantQueue), child: const Text('Open queue')),
                      ]),
                      const SizedBox(height: 10),
                      if (_queue.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No patients in queue.', style: TextStyle(color: AppColors.textSecondary))))
                      else ..._queue.take(5).map((a) => QueueCard(
                        appointment: a,
                        primaryLabel: 'Actions',
                        primaryIcon: Icons.tune_rounded,
                        onPrimary: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssistantQueueScreen(initialAppointment: a))).then((_) => _load()),
                      )),
                    ]),
                  ),
                ]),
    );
  }
}
