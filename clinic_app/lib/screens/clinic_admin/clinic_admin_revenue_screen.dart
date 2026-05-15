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
import '../../models/revenue_model.dart';
import '../../routes/app_routes.dart';

class ClinicAdminRevenueScreen extends StatefulWidget {
  const ClinicAdminRevenueScreen({super.key});

  @override
  State<ClinicAdminRevenueScreen> createState() => _ClinicAdminRevenueScreenState();
}

class _ClinicAdminRevenueScreenState extends State<ClinicAdminRevenueScreen> {
  RevenueModel? _revenue;
  bool    _loading = true;
  String? _error;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _revenue = await ClinicAdminService.getRevenue(
        from: _from != null ? _formatDate(_from!) : null,
        to:   _to   != null ? _formatDate(_to!)   : null,
      );
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateRange() async {
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
      title: 'Revenue',
      currentRoute: AppRoutes.clinicAdminRevenue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateRangeBar(from: _from, to: _to, onTap: _pickDateRange, onClear: _clearRange),
          const SizedBox(height: 16),
          if (_loading)            const LoadingWidget()
          else if (_error != null) ErrorView(message: _error!, onRetry: _load)
          else _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final r = _revenue!;
    final stats = [
      DashboardStat(title: 'Total Revenue', value: Helpers.formatCurrency(r.total),     icon: Icons.account_balance_wallet_rounded, color: AppColors.primary),
      DashboardStat(title: 'Today',         value: Helpers.formatCurrency(r.today),     icon: Icons.today_rounded,                  color: AppColors.accent),
      DashboardStat(title: 'This Month',    value: Helpers.formatCurrency(r.thisMonth), icon: Icons.calendar_month_rounded,         color: AppColors.info),
      DashboardStat(title: 'This Year',     value: Helpers.formatCurrency(r.thisYear),  icon: Icons.bar_chart_rounded,              color: AppColors.success),
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
      if (r.breakdown.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Text('Revenue Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: r.breakdown.asMap().entries.map((entry) {
              final i    = entry.key;
              final item = entry.value;
              final isLast = i == r.breakdown.length - 1;
              return Column(children: [
                ListTile(
                  title: Text(
                    _label(item['type']?.toString() ?? item['method']?.toString() ?? 'Other'),
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  subtitle: item['count'] != null
                      ? Text('${item['count']} transactions', style: const TextStyle(fontSize: 12))
                      : null,
                  trailing: Text(
                    Helpers.formatCurrency((item['amount'] as num?)?.toDouble()),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
                  ),
                ),
                if (!isLast) const Divider(height: 1, color: AppColors.divider),
              ]);
            }).toList(),
          ),
        ),
      ],
      if (r.recentTransactions.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.recentTransactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) {
              final t = r.recentTransactions[i];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.receipt_rounded, color: AppColors.primary, size: 18),
                ),
                title: Text(t['patient_name']?.toString() ?? t['clinic_name']?.toString() ?? 'Transaction',
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(Helpers.formatDate(t['date']?.toString()), style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  Helpers.formatCurrency((t['amount'] as num?)?.toDouble()),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              );
            },
          ),
        ),
      ],
    ]);
  }

  String _label(String s) {
    const map = {
      'consultation': 'Consultation', 'pharmacy': 'Pharmacy', 'lab': 'Lab Tests',
      'cash': 'Cash', 'card': 'Card', 'easypaisa': 'EasyPaisa',
      'jazzcash': 'JazzCash', 'bank': 'Bank Transfer', 'other': 'Other',
    };
    return map[s] ?? s;
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
