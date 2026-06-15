import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_surface.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../models/doctor_earnings_model.dart';
import '../../routes/app_routes.dart';

class DoctorEarningsScreen extends StatefulWidget {
  const DoctorEarningsScreen({super.key});

  @override
  State<DoctorEarningsScreen> createState() => _DoctorEarningsScreenState();
}

class _DoctorEarningsScreenState extends State<DoctorEarningsScreen> {
  DoctorEarningsModel? _earnings;
  Map<String, dynamic> _reports = {};
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
      _earnings = await DoctorService.earnings();
      _reports = await DoctorService.reports();
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
    final e = _earnings;
    final stats = e == null
        ? <DashboardStat>[]
        : [
            DashboardStat(
                title: 'Today',
                value: Helpers.formatCurrency(e.today),
                icon: Icons.today_rounded,
                color: AppColors.primary),
            DashboardStat(
                title: 'This Month',
                value: Helpers.formatCurrency(e.monthly),
                icon: Icons.calendar_month_rounded,
                color: AppColors.accent),
            DashboardStat(
                title: 'Total',
                value: Helpers.formatCurrency(e.total),
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.success),
            DashboardStat(
                title: 'Completed',
                value: '${e.completed}',
                icon: Icons.check_circle_rounded,
                color: AppColors.warning),
          ];
    return ResponsiveLayout(
      title: 'Earnings',
      currentRoute: AppRoutes.earnings,
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisExtent: 168,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16),
                    itemCount: stats.length,
                    itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
                  ),
                  const SizedBox(height: 28),
                  Row(children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Activity Summary',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  GlassPanel(
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatPill(
                            icon: Icons.people_rounded,
                            label: 'Patients Seen',
                            value: '${_reports['patients_seen'] ?? 0}',
                            color: AppColors.primary,
                          ),
                          _StatPill(
                            icon: Icons.receipt_long_rounded,
                            label: 'Prescriptions',
                            value: '${_reports['prescriptions'] ?? 0}',
                            color: AppColors.glowPurple,
                          ),
                          _StatPill(
                            icon: Icons.event_repeat_rounded,
                            label: 'Follow-ups',
                            value: '${_reports['follow_ups'] ?? 0}',
                            color: AppColors.info,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: .18),
              color.withValues(alpha: .08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: .28)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: .15),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 10),
      ShaderMask(
        shaderCallback: (r) =>
            LinearGradient(colors: [color, color.withValues(alpha: .7)])
                .createShader(r),
        child: Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white),
        ),
      ),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary)),
    ]);
  }
}
