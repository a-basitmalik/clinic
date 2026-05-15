import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../routes/app_routes.dart';

class PharmacyReportsScreen extends StatefulWidget {
  const PharmacyReportsScreen({super.key});

  @override
  State<PharmacyReportsScreen> createState() => _PharmacyReportsScreenState();
}

class _PharmacyReportsScreenState extends State<PharmacyReportsScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;
  DateTimeRange? _range;

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
      _data = await PharmacyService.reports(
        startDate: _range?.start.toIso8601String().split('T').first,
        endDate: _range?.end.toIso8601String().split('T').first,
      );
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        title: 'Pharmacy Reports',
        currentRoute: AppRoutes.pharmacyReports,
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_rounded),
            label: Text(_range == null
                ? 'Date Range'
                : '${Helpers.formatDate(_range!.start.toIso8601String())} - ${Helpers.formatDate(_range!.end.toIso8601String())}'),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _range = picked);
                _load();
              }
            },
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LoadingWidget()
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else
            _content(),
        ]),
      );

  Widget _content() {
    final stats = [
      DashboardStat(
          title: 'Today Sales',
          value: Helpers.formatCurrency(_num('today_sales')),
          icon: Icons.today_rounded,
          color: AppColors.primary),
      DashboardStat(
          title: 'Monthly Sales',
          value: Helpers.formatCurrency(_num('monthly_sales')),
          icon: Icons.calendar_month_rounded,
          color: AppColors.accent),
      DashboardStat(
          title: 'Total Sales',
          value: Helpers.formatCurrency(_num('total_sales')),
          icon: Icons.point_of_sale_rounded,
          color: AppColors.success),
      DashboardStat(
          title: 'Profit Estimate',
          value: Helpers.formatCurrency(_num('total_profit_estimate')),
          icon: Icons.trending_up_rounded,
          color: AppColors.info),
      DashboardStat(
          title: 'Items Sold',
          value: Helpers.formatNumber(_num('total_items_sold')),
          icon: Icons.medication_rounded,
          color: AppColors.warning),
      DashboardStat(
          title: 'Low Stock',
          value: Helpers.formatNumber(_num('low_stock_count')),
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger),
    ];
    final mostSold = (_data['most_sold_medicines'] as List?) ?? const [];
    final methods = (_data['sales_by_payment_method'] as List?) ?? const [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 150,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16),
        itemCount: stats.length,
        itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
      ),
      const SizedBox(height: 24),
      _section('Most Sold Medicines', mostSold),
      const SizedBox(height: 16),
      _section('Sales by Payment Method', methods),
    ]);
  }

  Widget _section(String title, List rows) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Text('No data available.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            ...rows.map((r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text((r is Map
                          ? (r['medicine_name'] ??
                              r['method'] ??
                              r['payment_method'] ??
                              'Item')
                          : r)
                      .toString()),
                  trailing: Text((r is Map
                          ? (r['total'] ?? r['quantity'] ?? r['amount'] ?? '')
                          : '')
                      .toString()),
                )),
        ]),
      );

  num _num(String key) =>
      (_data[key] as num?) ??
      ((_data['summary'] is Map ? _data['summary'][key] : null) as num?) ??
      0;
}
