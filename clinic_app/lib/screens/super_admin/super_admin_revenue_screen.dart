import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/super_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../models/revenue_model.dart';
import '../../routes/app_routes.dart';

class SuperAdminRevenueScreen extends StatefulWidget {
  const SuperAdminRevenueScreen({super.key});

  @override
  State<SuperAdminRevenueScreen> createState() => _SuperAdminRevenueScreenState();
}

class _SuperAdminRevenueScreenState extends State<SuperAdminRevenueScreen> {
  RevenueModel? _revenue;
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _revenue = await SuperAdminService.getRevenue();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'System Revenue',
      currentRoute: AppRoutes.superAdminRevenue,
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final r = _revenue!;
    final stats = [
      DashboardStat(title: 'Total Revenue',   value: Helpers.formatCurrency(r.total),      icon: Icons.account_balance_wallet_rounded, color: AppColors.primary),
      DashboardStat(title: 'Today',           value: Helpers.formatCurrency(r.today),      icon: Icons.today_rounded,                  color: AppColors.accent),
      DashboardStat(title: 'This Month',      value: Helpers.formatCurrency(r.thisMonth),  icon: Icons.calendar_month_rounded,         color: AppColors.info),
      DashboardStat(title: 'This Year',       value: Helpers.formatCurrency(r.thisYear),   icon: Icons.bar_chart_rounded,              color: AppColors.success),
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
                    _breakdownLabel(item['type']?.toString() ?? item['method']?.toString() ?? 'Other'),
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
                title: Text(t['clinic_name']?.toString() ?? 'Transaction', style: const TextStyle(fontSize: 14)),
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

  String _breakdownLabel(String s) {
    const map = {
      'consultation': 'Consultation', 'pharmacy': 'Pharmacy',
      'lab': 'Lab Tests', 'other': 'Other',
      'cash': 'Cash', 'card': 'Card',
      'easypaisa': 'EasyPaisa', 'jazzcash': 'JazzCash', 'bank': 'Bank Transfer',
    };
    return map[s] ?? s;
  }
}
