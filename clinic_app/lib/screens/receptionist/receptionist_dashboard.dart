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
        subtitle: 'Scheduled',
      ),
      DashboardStat(
        title: 'Waiting Patients',
        value: Helpers.formatNumber(d['waiting'] as num?),
        icon: Icons.hourglass_bottom_rounded,
        color: AppColors.warning,
        subtitle: 'In queue',
      ),
      DashboardStat(
        title: 'New Patients',
        value: Helpers.formatNumber(d['new_patients_today'] as num?),
        icon: Icons.person_add_rounded,
        color: AppColors.glowBlue,
        subtitle: 'Registered today',
      ),
      DashboardStat(
        title: 'Collected Today',
        value: Helpers.formatCurrency(d['collected_today'] as num?),
        icon: Icons.payments_rounded,
        color: AppColors.success,
        subtitle: 'Total collected',
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
        PremiumDashboardOverview(
          eyebrow: 'Front desk overview',
          headline: 'A smoother day starts here.',
          description:
              'Manage arrivals, appointments, patients and billing.',
          heroIcon: Icons.support_agent_rounded,
          stats: stats,
          actions: [
            DashboardQuickAction(
              label: 'Book Appointment',
              icon: Icons.calendar_month_rounded,
              color: AppColors.primary,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.bookAppointment),
            ),
            DashboardQuickAction(
              label: 'Register Patient',
              icon: Icons.person_add_rounded,
              color: AppColors.glowBlue,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.recPatients),
            ),
            DashboardQuickAction(
              label: 'Token Queue',
              icon: Icons.queue_rounded,
              color: AppColors.warning,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.tokenQueue),
            ),
            DashboardQuickAction(
              label: 'Billing',
              icon: Icons.payments_rounded,
              color: AppColors.success,
              onTap: () => Navigator.pushNamed(context, AppRoutes.billing),
            ),
          ],
        ),
        const SizedBox(height: 28),

        if (appointments.isNotEmpty) ...[
          PremiumDashboardSection(
            title: "Today's Appointments",
            trailing: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.tokenQueue),
              child: Text('View queue',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
            child: Column(
              children: appointments
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
    final isPaid = appt['payment_status'] == 'paid';
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
                  AppColors.primaryLight.withValues(alpha: .07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .22),
              ),
            ),
            child: Center(
              child: Text(
                '${appt['token_number'] ?? '–'}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14),
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
                  'Dr. ${appt['doctor_name'] ?? '—'} • ${Helpers.formatTime(appt['appointment_time'] as String?)}',
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
              color: isPaid ? AppColors.successSurface : AppColors.warningSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPaid
                    ? AppColors.success.withValues(alpha: .25)
                    : AppColors.warning.withValues(alpha: .25),
              ),
            ),
            child: Text(
              isPaid ? 'Paid' : 'Unpaid',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isPaid ? AppColors.success : AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
