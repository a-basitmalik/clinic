import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/clinic_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../routes/app_routes.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic> _data = {};
  bool    _loading = true;
  String? _error;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _data = await ClinicAdminService.getReports(
        from: _from != null ? _fmtDate(_from!) : null,
        to:   _to   != null ? _fmtDate(_to!)   : null,
      );
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (range != null) {
      setState(() { _from = range.start; _to = range.end; });
      _load();
    }
  }

  void _clearRange() { setState(() { _from = null; _to = null; }); _load(); }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Reports',
      currentRoute: AppRoutes.reports,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateRangeBar(from: _from, to: _to, onTap: _pickRange, onClear: _clearRange),
          const SizedBox(height: 16),
          if (_loading)            const LoadingWidget()
          else if (_error != null) ErrorView(message: _error!, onRetry: _load)
          else _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final appts   = _data['appointments'] as Map? ?? {};
    final rev     = _data['revenue']      as Map? ?? {};
    final patients = _data['patients']    as Map? ?? {};

    final stats = [
      DashboardStat(title: 'Total Appointments', value: Helpers.formatNumber(appts['total'] as num?),     icon: Icons.calendar_month_rounded,            color: AppColors.primary),
      DashboardStat(title: 'Completed',          value: Helpers.formatNumber(appts['completed'] as num?), icon: Icons.check_circle_outline_rounded,       color: AppColors.success),
      DashboardStat(title: 'Cancelled',          value: Helpers.formatNumber(appts['cancelled'] as num?), icon: Icons.cancel_outlined,                   color: AppColors.danger),
      DashboardStat(title: 'Total Revenue',      value: Helpers.formatCurrency((rev['total'] as num?)?.toDouble()), icon: Icons.account_balance_wallet_rounded, color: AppColors.accent),
      DashboardStat(title: 'New Patients',       value: Helpers.formatNumber(patients['new'] as num?),    icon: Icons.person_add_alt_1_rounded,           color: AppColors.info),
      DashboardStat(title: 'Total Patients',     value: Helpers.formatNumber(patients['total'] as num?),  icon: Icons.people_alt_rounded,                color: AppColors.primary),
    ];

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
      if (_data['top_doctors'] != null) ...[
        const SizedBox(height: 24),
        const Text('Top Doctors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildDoctorsTable(_data['top_doctors'] as List? ?? []),
      ],
      if (_data['appointment_by_type'] != null) ...[
        const SizedBox(height: 24),
        const Text('Appointments by Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildBreakdownTable(_data['appointment_by_type'] as List? ?? []),
      ],
    ]);
  }

  Widget _buildDoctorsTable(List data) {
    if (data.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: data.asMap().entries.map((entry) {
          final i    = entry.key;
          final item = entry.value as Map;
          final isLast = i == data.length - 1;
          return Column(children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primarySurface,
                child: Text('${i + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              title: Text(item['doctor_name']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              subtitle: Text('${item['appointments'] ?? 0} appointments', style: const TextStyle(fontSize: 12)),
              trailing: Text(
                Helpers.formatCurrency((item['revenue'] as num?)?.toDouble()),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
              ),
            ),
            if (!isLast) const Divider(height: 1, color: AppColors.divider),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildBreakdownTable(List data) {
    if (data.isEmpty) return const SizedBox.shrink();
    const typeLabels = {'new': 'New', 'followup': 'Follow-up', 'emergency': 'Emergency'};
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: data.asMap().entries.map((entry) {
          final i    = entry.key;
          final item = entry.value as Map;
          final isLast = i == data.length - 1;
          final typeKey = item['type']?.toString() ?? '';
          return Column(children: [
            ListTile(
              title: Text(typeLabels[typeKey] ?? Helpers.snakeToTitle(typeKey),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              trailing: Text('${item['count'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
            ),
            if (!isLast) const Divider(height: 1, color: AppColors.divider),
          ]);
        }).toList(),
      ),
    );
  }
}

class _DateRangeBar extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _DateRangeBar({this.from, this.to, required this.onTap, required this.onClear});

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasRange = from != null && to != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasRange ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasRange ? AppColors.primary : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.date_range_rounded, size: 18,
              color: hasRange ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            hasRange ? '${_fmt(from!)}  –  ${_fmt(to!)}' : 'Filter by date range',
            style: TextStyle(fontSize: 13,
                color: hasRange ? AppColors.primary : AppColors.textSecondary),
          ),
          if (hasRange) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
            ),
          ],
        ]),
      ),
    );
  }
}
