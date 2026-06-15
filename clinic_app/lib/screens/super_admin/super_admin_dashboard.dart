import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_dashboard.dart';
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
        subtitle: 'Needs your review',
      ),
      DashboardStat(
        title: 'Total Users',
        value: Helpers.formatNumber(users['total'] as num?),
        icon: Icons.people_alt_rounded,
        color: AppColors.glowBlue,
        subtitle: 'Registered users',
      ),
      DashboardStat(
        title: 'Appointments Today',
        value: Helpers.formatNumber(appts['today'] as num?),
        icon: Icons.calendar_today_rounded,
        color: AppColors.info,
        subtitle: 'Scheduled today',
      ),
      DashboardStat(
        title: 'Revenue (Month)',
        value: Helpers.formatCurrency(revenue['month'] as num?),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
        subtitle: 'Total revenue this month',
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
        PremiumDashboardOverview(
          eyebrow: 'Welcome back',
          headline: "Here's what's happening today.",
          description:
              'Monitor clinics, users, approvals and platform growth.',
          heroIcon: Icons.monitor_heart_rounded,
          stats: stats,
          actions: [
            DashboardQuickAction(
              label: 'View Clinics',
              icon: Icons.local_hospital_rounded,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, AppRoutes.clinics),
            ),
            DashboardQuickAction(
              label: 'Pending Approvals',
              icon: Icons.pending_actions_rounded,
              color: AppColors.warning,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.pendingApprovals),
            ),
            DashboardQuickAction(
              label: 'System Stats',
              icon: Icons.analytics_rounded,
              color: AppColors.info,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.systemStats),
            ),
            DashboardQuickAction(
              label: 'Revenue Report',
              icon: Icons.payments_rounded,
              color: AppColors.success,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.superAdminRevenue),
            ),
          ],
        ),
        const SizedBox(height: 28),

        if (recentClinics.isNotEmpty) ...[
          PremiumDashboardSection(
            title: 'Recent Clinics',
            trailing: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.clinics),
              child: Text('View all',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
            child: Column(
              children: recentClinics
                  .take(6)
                  .map((c) => _ClinicRow(clinic: c))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ClinicRow extends StatelessWidget {
  final Map clinic;
  const _ClinicRow({required this.clinic});

  @override
  Widget build(BuildContext context) {
    final status = clinic['status'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .18),
                  AppColors.primaryLight.withValues(alpha: .08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .22),
              ),
            ),
            child: const Icon(Icons.local_hospital_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinic['clinic_name'] as String? ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  clinic['city'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _StatusPill(status: status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'approved':
        bg = AppColors.successSurface;
        fg = AppColors.success;
        break;
      case 'pending':
        bg = AppColors.warningSurface;
        fg = AppColors.warning;
        break;
      case 'suspended':
        bg = AppColors.dangerSurface;
        fg = AppColors.danger;
        break;
      default:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: .2)),
      ),
      child: Text(
        status.isEmpty
            ? '—'
            : status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
