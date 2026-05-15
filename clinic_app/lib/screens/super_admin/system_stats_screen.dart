import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/report_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../routes/app_routes.dart';

class SystemStatsScreen extends StatefulWidget {
  const SystemStatsScreen({super.key});

  @override
  State<SystemStatsScreen> createState() => _SystemStatsScreenState();
}

class _SystemStatsScreenState extends State<SystemStatsScreen> {
  Map<String, dynamic> _data = {};
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _data = await ReportService.getSuperAdminStats();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<DashboardStat> _buildStats() {
    final clinics  = _data['clinics']  as Map? ?? {};
    final users    = _data['users']    as Map? ?? {};
    final appts    = _data['appointments'] as Map? ?? {};
    final patients = _data['patients'] as Map? ?? {};
    return [
      DashboardStat(title: 'Total Clinics',     value: Helpers.formatNumber(clinics['total']  as num?), icon: Icons.local_hospital_rounded,   color: AppColors.primary,  subtitle: '${clinics['approved'] ?? 0} approved'),
      DashboardStat(title: 'Pending Approvals', value: Helpers.formatNumber(clinics['pending'] as num?), icon: Icons.pending_actions_rounded, color: AppColors.warning),
      DashboardStat(title: 'Suspended',         value: Helpers.formatNumber(clinics['suspended'] as num?), icon: Icons.block_rounded,         color: AppColors.danger),
      DashboardStat(title: 'Total Users',       value: Helpers.formatNumber(users['total']    as num?), icon: Icons.people_alt_rounded,        color: AppColors.accent),
      DashboardStat(title: 'Total Doctors',     value: Helpers.formatNumber(users['doctors']  as num?), icon: Icons.medical_services_rounded,  color: AppColors.info),
      DashboardStat(title: 'Total Patients',    value: Helpers.formatNumber(patients['total'] as num?), icon: Icons.personal_injury_rounded,   color: AppColors.primary),
      DashboardStat(title: 'Total Appointments',value: Helpers.formatNumber(appts['total']    as num?), icon: Icons.calendar_month_rounded,    color: AppColors.accent),
      DashboardStat(title: 'Today Appointments',value: Helpers.formatNumber(appts['today']    as num?), icon: Icons.today_rounded,             color: AppColors.success),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'System Statistics',
      currentRoute: AppRoutes.systemStats,
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final stats = _buildStats();
    final usersByRole = _data['users_by_role'] as Map? ?? {};

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260, mainAxisExtent: 150,
          crossAxisSpacing: 16, mainAxisSpacing: 16,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
      ),
      if (usersByRole.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Text('Users by Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: (usersByRole.entries.toList().asMap().entries.map((entry) {
              final i     = entry.key;
              final e     = entry.value;
              final isLast = i == usersByRole.length - 1;
              return Column(children: [
                ListTile(
                  leading: const Icon(Icons.person_rounded, color: AppColors.primary),
                  title: Text(_roleLabel(e.key), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  trailing: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
                ),
                if (!isLast) const Divider(height: 1, color: AppColors.divider),
              ]);
            })).toList(),
          ),
        ),
      ],
    ]);
  }

  String _roleLabel(String role) {
    const map = {
      'super_admin': 'Super Admin', 'clinic_admin': 'Clinic Admin',
      'doctor': 'Doctor', 'assistant': 'Doctor Assistant',
      'receptionist': 'Receptionist', 'pharmacy': 'Pharmacy', 'patient': 'Patient',
    };
    return map[role] ?? role;
  }
}
