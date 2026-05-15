import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../routes/app_routes.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  Map<String, dynamic>? _data;
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
      final res = await ApiService.get<Map<String, dynamic>>(
        ApiConstants.receptionistDashboard,
        fromData: (d) => d as Map<String, dynamic>,
      );
      if (mounted)
        setState(() {
          _data = res.data;
          _loading = false;
        });
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

  List<DashboardStat> _buildStats() {
    final d = _data ?? {};
    return [
      DashboardStat(
        title: "Today's Appointments",
        value: Helpers.formatNumber(d['appointments_today'] as num?),
        icon: Icons.calendar_today_rounded,
        color: AppColors.primary,
      ),
      DashboardStat(
        title: 'Waiting Patients',
        value: Helpers.formatNumber(d['waiting'] as num?),
        icon: Icons.hourglass_bottom_rounded,
        color: AppColors.warning,
      ),
      DashboardStat(
        title: 'New Patients',
        value: Helpers.formatNumber(d['new_patients_today'] as num?),
        icon: Icons.person_add_rounded,
        color: AppColors.accent,
      ),
      DashboardStat(
        title: 'Collected Today',
        value: Helpers.formatCurrency(d['collected_today'] as num?),
        icon: Icons.payments_rounded,
        color: AppColors.success,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.receptionistDashboard,
      body: _loading
          ? const LoadingWidget(message: AppStrings.loading)
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _DashboardBody(stats: _buildStats(), data: _data ?? {}),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final List<DashboardStat> stats;
  final Map<String, dynamic> data;

  const _DashboardBody({required this.stats, required this.data});

  @override
  Widget build(BuildContext context) {
    final appointments = (data['appointments'] as List?)?.cast<Map>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 150,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
        ),
        const SizedBox(height: 24),
        if (appointments.isNotEmpty) ...[
          const Text("Today's Appointments",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final a = appointments[i];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      '${a['token_number'] ?? ''}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                  title: Text(a['patient_name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      'Dr. ${a['doctor_name'] ?? ''} • ${Helpers.formatTime(a['appointment_time'] as String?)}'),
                  trailing: Text(
                    a['payment_status'] == 'paid' ? 'Paid' : 'Unpaid',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: a['payment_status'] == 'paid'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
