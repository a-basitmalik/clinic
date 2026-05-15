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

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
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
        ApiConstants.superAdminDashboard,
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
    final clinics = d['clinics'] as Map? ?? {};
    final users = d['users'] as Map? ?? {};
    final appts = d['appointments'] as Map? ?? {};
    final revenue = d['revenue'] as Map? ?? {};

    return [
      DashboardStat(
        title: 'Total Clinics',
        value: Helpers.formatNumber(clinics['total'] as num?),
        icon: Icons.local_hospital_rounded,
        color: AppColors.primary,
        subtitle: '${clinics['approved'] ?? 0} approved',
      ),
      DashboardStat(
        title: 'Pending Approvals',
        value: Helpers.formatNumber(clinics['pending'] as num?),
        icon: Icons.pending_actions_rounded,
        color: AppColors.warning,
      ),
      DashboardStat(
        title: 'Total Users',
        value: Helpers.formatNumber(users['total'] as num?),
        icon: Icons.people_alt_rounded,
        color: AppColors.accent,
      ),
      DashboardStat(
        title: 'Appointments Today',
        value: Helpers.formatNumber(appts['today'] as num?),
        icon: Icons.calendar_today_rounded,
        color: AppColors.info,
      ),
      DashboardStat(
        title: 'Revenue (Month)',
        value: Helpers.formatCurrency(revenue['month'] as num?),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.superAdminDashboard,
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
    final recentClinics = (data['recent_clinics'] as List?)?.cast<Map>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats grid
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

        // Recent clinics
        if (recentClinics.isNotEmpty) ...[
          const Text('Recent Clinics',
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
              itemCount: recentClinics.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final c = recentClinics[i];
                final status = c['status'] as String? ?? '';
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(Icons.local_hospital_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(c['clinic_name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(c['city'] as String? ?? ''),
                  trailing: _StatusBadge(status: status),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'approved':
        bg = AppColors.successSurface;
        fg = AppColors.success;
      case 'pending':
        bg = AppColors.warningSurface;
        fg = AppColors.warning;
      case 'suspended':
        bg = AppColors.dangerSurface;
        fg = AppColors.danger;
      default:
        bg = AppColors.background;
        fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
