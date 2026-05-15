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

class ClinicAdminDashboard extends StatefulWidget {
  const ClinicAdminDashboard({super.key});

  @override
  State<ClinicAdminDashboard> createState() => _ClinicAdminDashboardState();
}

class _ClinicAdminDashboardState extends State<ClinicAdminDashboard> {
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
        ApiConstants.clinicAdminDashboard,
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
        title: 'Total Doctors',
        value: Helpers.formatNumber(d['total_doctors'] as num?),
        icon: Icons.medical_services_rounded,
        color: AppColors.primary,
      ),
      DashboardStat(
        title: 'Total Patients',
        value: Helpers.formatNumber(d['total_patients'] as num?),
        icon: Icons.people_alt_rounded,
        color: AppColors.accent,
      ),
      DashboardStat(
        title: "Today's Appointments",
        value: Helpers.formatNumber(d['appointments_today'] as num?),
        icon: Icons.calendar_today_rounded,
        color: AppColors.info,
      ),
      DashboardStat(
        title: 'Monthly Revenue',
        value: Helpers.formatCurrency(d['monthly_revenue'] as num?),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
      ),
      DashboardStat(
        title: 'Pending Payments',
        value: Helpers.formatNumber(d['pending_payments'] as num?),
        icon: Icons.pending_rounded,
        color: AppColors.warning,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.clinicAdminDashboard,
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
    final recentAppts =
        (data['recent_appointments'] as List?)?.cast<Map>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 150,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
        ),
        const SizedBox(height: 24),
        if (recentAppts.isNotEmpty) ...[
          const Text('Recent Appointments',
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
              itemCount: recentAppts.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final a = recentAppts[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(a['patient_name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      'Dr. ${a['doctor_name'] ?? ''} • ${Helpers.formatDate(a['appointment_date'] as String?)}'),
                  trailing: Text(
                    '#${a['token_number'] ?? ''}',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
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
