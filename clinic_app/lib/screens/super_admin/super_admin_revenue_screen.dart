import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/super_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_surface.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../models/revenue_model.dart';
import '../../routes/app_routes.dart';

class SuperAdminRevenueScreen extends StatefulWidget {
  const SuperAdminRevenueScreen({super.key});

  @override
  State<SuperAdminRevenueScreen> createState() =>
      _SuperAdminRevenueScreenState();
}

class _SuperAdminRevenueScreenState extends State<SuperAdminRevenueScreen> {
  RevenueModel? _revenue;
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
      _revenue = await SuperAdminService.getRevenue();
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
      DashboardStat(
          title: 'Total Revenue',
          value: Helpers.formatCurrency(r.total),
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.primary),
      DashboardStat(
          title: 'Today',
          value: Helpers.formatCurrency(r.today),
          icon: Icons.today_rounded,
          color: AppColors.accent),
      DashboardStat(
          title: 'This Month',
          value: Helpers.formatCurrency(r.thisMonth),
          icon: Icons.calendar_month_rounded,
          color: AppColors.info),
      DashboardStat(
          title: 'This Year',
          value: Helpers.formatCurrency(r.thisYear),
          icon: Icons.bar_chart_rounded,
          color: AppColors.success),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisExtent: 168,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
      ),
      if (r.breakdown.isNotEmpty) ...[
        const SizedBox(height: 28),
        _SectionLabel(label: 'Revenue Breakdown'),
        const SizedBox(height: 12),
        GlassPanel(
          radius: 18,
          child: Column(
            children: r.breakdown.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == r.breakdown.length - 1;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: .18),
                            AppColors.primaryLight.withValues(alpha: .08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: .22)),
                      ),
                      child: const Icon(Icons.category_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                          _breakdownLabel(
                              item['type']?.toString() ??
                                  item['method']?.toString() ??
                                  'Other'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                        ),
                        if (item['count'] != null)
                          Text('${item['count']} transactions',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                      ]),
                    ),
                    ShaderMask(
                      shaderCallback: (r) => LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ).createShader(r),
                      child: Text(
                        Helpers.formatCurrency(
                            (item['amount'] as num?)?.toDouble()),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                    ),
                  ]),
                ),
                if (!isLast)
                  Divider(
                      height: 1,
                      color: AppColors.divider.withValues(alpha: .5)),
              ]);
            }).toList(),
          ),
        ),
      ],
      if (r.recentTransactions.isNotEmpty) ...[
        const SizedBox(height: 28),
        _SectionLabel(label: 'Recent Transactions'),
        const SizedBox(height: 12),
        GlassPanel(
          radius: 18,
          child: Column(
            children: r.recentTransactions.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final isLast = i == r.recentTransactions.length - 1;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success.withValues(alpha: .16),
                            AppColors.success.withValues(alpha: .07),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: .25)),
                      ),
                      child: const Icon(Icons.receipt_rounded,
                          color: AppColors.success, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            t['clinic_name']?.toString() ?? 'Transaction',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        Text(Helpers.formatDate(t['date']?.toString()),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: .28)),
                      ),
                      child: Text(
                        Helpers.formatCurrency(
                            (t['amount'] as num?)?.toDouble()),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success),
                      ),
                    ),
                  ]),
                ),
                if (!isLast)
                  Divider(
                      height: 1,
                      color: AppColors.divider.withValues(alpha: .5)),
              ]);
            }).toList(),
          ),
        ),
      ],
    ]);
  }

  String _breakdownLabel(String s) {
    const map = {
      'consultation': 'Consultation',
      'pharmacy': 'Pharmacy',
      'lab': 'Lab Tests',
      'other': 'Other',
      'cash': 'Cash',
      'card': 'Card',
      'easypaisa': 'EasyPaisa',
      'jazzcash': 'JazzCash',
      'bank': 'Bank Transfer',
    };
    return map[s] ?? s;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
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
      Text(
        label,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
      ),
    ]);
  }
}
