import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
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
      ),
      DashboardStat(
        title: 'Total Items',
        value: Helpers.formatNumber(
            (d['total_medicines'] ?? d['total_items']) as num?),
        icon: Icons.inventory_2_rounded,
        color: AppColors.accent,
      ),
      DashboardStat(
        title: 'Low Stock',
        value: Helpers.formatNumber(
            (d['low_stock_count'] ?? d['low_stock']) as num?),
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
      DashboardStat(
        title: 'Expiring Soon',
        value: Helpers.formatNumber(
            (d['expiring_count'] ?? d['expiring_soon']) as num?),
        icon: Icons.access_time_rounded,
        color: AppColors.danger,
      ),
      DashboardStat(
        title: 'Pending Orders',
        value: Helpers.formatNumber(
            (d['pending_prescription_orders'] ?? d['pending_orders']) as num?),
        icon: Icons.receipt_long_rounded,
        color: AppColors.info,
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
    final lowStockItems = (data['low_stock_items'] as List?)?.cast<Map>() ?? [];
    final recentSales = (data['recent_sales'] as List?)?.cast<Map>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 150,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => DashboardCard(stat: stats[i]),
        ),
        const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: [
          CustomButton(
              label: 'Add Medicine',
              icon: Icons.add_rounded,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.inventory)),
          CustomButton(
              label: 'Create Sale',
              icon: Icons.point_of_sale_rounded,
              variant: ButtonVariant.secondary,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.sales)),
          CustomButton(
              label: 'Orders',
              icon: Icons.assignment_rounded,
              variant: ButtonVariant.outlined,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.pharmacyOrders)),
        ]),
        const SizedBox(height: 24),
        if (lowStockItems.isNotEmpty) ...[
          const Text('Low Stock Alert',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStockItems.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final item = lowStockItems[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.warningSurface,
                    child: Icon(Icons.medication_rounded,
                        color: AppColors.warning, size: 20),
                  ),
                  title: Text(item['name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      'Stock: ${item['quantity'] ?? 0} • Min: ${item['min_stock'] ?? 0}'),
                  trailing: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (recentSales.isNotEmpty) ...[
          const Text('Recent Sales',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSales.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final s = recentSales[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accentSurface,
                    child: Icon(Icons.receipt_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                  title: Text(s['patient_name'] as String? ?? 'Walk-in',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle:
                      Text(Helpers.formatDateTime(s['created_at'] as String?)),
                  trailing: Text(
                    Helpers.formatCurrency(s['total_amount'] as num?),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
