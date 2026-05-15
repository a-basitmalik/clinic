import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
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
    setState(() { _loading = true; _error = null; });
    try {
      _earnings = await DoctorService.earnings();
      _reports = await DoctorService.reports();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _earnings;
    final stats = e == null ? <DashboardStat>[] : [
      DashboardStat(title: 'Today', value: Helpers.formatCurrency(e.today), icon: Icons.today_rounded, color: AppColors.primary),
      DashboardStat(title: 'This Month', value: Helpers.formatCurrency(e.monthly), icon: Icons.calendar_month_rounded, color: AppColors.accent),
      DashboardStat(title: 'Total', value: Helpers.formatCurrency(e.total), icon: Icons.account_balance_wallet_rounded, color: AppColors.success),
      DashboardStat(title: 'Completed', value: '${e.completed}', icon: Icons.check_circle_rounded, color: AppColors.warning),
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
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisExtent: 150, crossAxisSpacing: 16, mainAxisSpacing: 16),
                    itemCount: stats.length,
                    itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                    child: Text('Patients seen: ${_reports['patients_seen'] ?? 0}\nPrescriptions: ${_reports['prescriptions'] ?? 0}\nFollow-ups: ${_reports['follow_ups'] ?? 0}'),
                  ),
                ]),
    );
  }
}
