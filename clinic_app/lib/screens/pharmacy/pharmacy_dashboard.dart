import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_dashboard.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/dashboard_stat_model.dart';
import '../../routes/app_routes.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
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
      final data = await PharmacyService.dashboard();
      if (mounted)
        setState(() {
          _data = data;
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
        title: "Today's Sales",
        value: Helpers.formatCurrency(
            (d['today_sales'] ?? d['sales_today']) as num?),
        icon: Icons.point_of_sale_rounded,
        color: AppColors.primary,
        subtitle: 'Revenue today',
      ),
      DashboardStat(
        title: 'Total Items',
        value: Helpers.formatNumber(
            (d['total_medicines'] ?? d['total_items']) as num?),
        icon: Icons.inventory_2_rounded,
        color: AppColors.glowBlue,
        subtitle: 'In inventory',
      ),
      DashboardStat(
        title: 'Low Stock',
        value: Helpers.formatNumber(
            (d['low_stock_count'] ?? d['low_stock']) as num?),
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        subtitle: 'Need restock',
      ),
      DashboardStat(
        title: 'Expiring Soon',
        value: Helpers.formatNumber(
            (d['expiring_count'] ?? d['expiring_soon']) as num?),
        icon: Icons.access_time_rounded,
        color: AppColors.danger,
        subtitle: 'Within 30 days',
      ),
      DashboardStat(
        title: 'Pending Orders',
        value: Helpers.formatNumber(
            (d['pending_prescription_orders'] ?? d['pending_orders']) as num?),
        icon: Icons.receipt_long_rounded,
        color: AppColors.info,
        subtitle: 'Awaiting fulfilment',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.dashboard,
      currentRoute: AppRoutes.pharmacyDashboard,
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
    final lowStockItems =
        (data['low_stock_items'] as List?)?.cast<Map>() ?? [];
    final recentSales = (data['recent_sales'] as List?)?.cast<Map>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumDashboardOverview(
          eyebrow: 'Pharmacy intelligence',
          headline: 'Stock, sales and orders in sync.',
          description:
              'Stay ahead of inventory risks and patient orders.',
          heroIcon: Icons.local_pharmacy_rounded,
          stats: stats,
          actions: [
            DashboardQuickAction(
              label: 'Add Medicine',
              icon: Icons.add_rounded,
              color: AppColors.primary,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.inventory),
            ),
            DashboardQuickAction(
              label: 'Create Sale',
              icon: Icons.point_of_sale_rounded,
              color: AppColors.glowBlue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
            ),
            DashboardQuickAction(
              label: 'Rx Orders',
              icon: Icons.assignment_rounded,
              color: AppColors.info,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.pharmacyOrders),
            ),
            DashboardQuickAction(
              label: 'Low Stock',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.lowStock),
            ),
          ],
        ),
        const SizedBox(height: 28),

        if (lowStockItems.isNotEmpty) ...[
          PremiumDashboardSection(
            title: 'Low Stock Alert',
            trailing: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.lowStock),
              child: Text('View all',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700)),
            ),
            child: Column(
              children: lowStockItems
                  .take(5)
                  .map((item) => _StockRow(item: item))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (recentSales.isNotEmpty) ...[
          PremiumDashboardSection(
            title: 'Recent Sales',
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.sales),
              child: Text('View all',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
            child: Column(
              children: recentSales
                  .take(5)
                  .map((s) => _SaleRow(sale: s))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  final Map item;
  const _StockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final qty = item['quantity'] as num? ?? 0;
    final min = item['min_stock'] as num? ?? 0;
    final pct = min > 0 ? (qty / min).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: .3)),
            ),
            child: const Icon(Icons.medication_rounded,
                color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? '—',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          backgroundColor:
                              AppColors.warning.withValues(alpha: .15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.warning),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$qty / $min',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 18),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final Map sale;
  const _SaleRow({required this.sale});

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
                  AppColors.primary.withValues(alpha: .18),
                  AppColors.primaryLight.withValues(alpha: .07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: .22)),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale['patient_name'] as String? ?? 'Walk-in',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  Helpers.formatDateTime(sale['created_at'] as String?),
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
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: .25)),
            ),
            child: Text(
              Helpers.formatCurrency(sale['total_amount'] as num?),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
