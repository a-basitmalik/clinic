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
        subtitle: 'Active staff',
      ),
      DashboardStat(
        title: 'Total Patients',
        value: Helpers.formatNumber(d['total_patients'] as num?),
        icon: Icons.people_alt_rounded,
        color: AppColors.glowBlue,
        subtitle: 'Registered',
      ),
      DashboardStat(
        title: "Today's Appointments",
        value: Helpers.formatNumber(d['appointments_today'] as num?),
        icon: Icons.calendar_today_rounded,
        color: AppColors.info,
        subtitle: 'Scheduled',
      ),
      DashboardStat(
        title: 'Pending Payments',
        value: Helpers.formatNumber(d['pending_payments'] as num?),
        icon: Icons.pending_rounded,
        color: AppColors.warning,
        subtitle: 'Awaiting',
      ),
      DashboardStat(
        title: 'Monthly Revenue',
        value: Helpers.formatCurrency(d['monthly_revenue'] as num?),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
        subtitle: 'This month',
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
        PremiumDashboardOverview(
          eyebrow: 'Clinic command center',
          headline: 'Your clinic, beautifully organized.',
          description:
              'Doctors, patients, appointments and revenue at a glance.',
          heroIcon: Icons.local_hospital_rounded,
          stats: stats,
          actions: [
            DashboardQuickAction(
              label: 'Manage Doctors',
              icon: Icons.medical_services_rounded,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, AppRoutes.doctors),
            ),
            DashboardQuickAction(
              label: 'View Patients',
              icon: Icons.people_alt_rounded,
              color: AppColors.glowBlue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.patients),
            ),
            DashboardQuickAction(
              label: 'Appointments',
              icon: Icons.calendar_month_rounded,
              color: AppColors.info,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.appointments),
            ),
            DashboardQuickAction(
              label: 'Reports',
              icon: Icons.bar_chart_rounded,
              color: AppColors.success,
              onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
            ),
          ],
        ),
        const SizedBox(height: 28),

        if (recentAppts.isNotEmpty) ...[
          PremiumDashboardSection(
            title: 'Recent Appointments',
            trailing: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.appointments),
              child: Text('View all',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
            child: Column(
              children: recentAppts
                  .take(6)
                  .map((a) => _AppointmentRow(appt: a))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final Map appt;
  const _AppointmentRow({required this.appt});

  @override
  Widget build(BuildContext context) {
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
                  AppColors.glowBlue.withValues(alpha: .18),
                  AppColors.glowBlue.withValues(alpha: .07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.glowBlue.withValues(alpha: .22),
              ),
            ),
            child: Center(
              child: Text(
                '#${appt['token_number'] ?? '–'}',
                style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt['patient_name'] as String? ?? '—',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. ${appt['doctor_name'] ?? '—'} • ${Helpers.formatDate(appt['appointment_date'] as String?)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#${appt['token_number'] ?? '—'}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}
