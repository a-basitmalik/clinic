import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_table.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/pharmacy_sale_model.dart';
import '../../routes/app_routes.dart';
import 'create_sale_screen.dart';
import 'invoice_screen.dart';

class PharmacySalesScreen extends StatefulWidget {
  const PharmacySalesScreen({super.key});

  @override
  State<PharmacySalesScreen> createState() => _PharmacySalesScreenState();
}

class _PharmacySalesScreenState extends State<PharmacySalesScreen> {
  List<PharmacySaleModel> _sales = [];
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
      _sales = await PharmacyService.sales();
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
        title: 'Medicine Sales',
        currentRoute: AppRoutes.sales,
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateSaleScreen()))
                .then((_) => _load()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: .35),
                      blurRadius: 14,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Walk-in Sale',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LoadingWidget()
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else
            AppTable<PharmacySaleModel>(
              rows: _sales,
              emptyMessage: 'No sales found.',
              mobileCard: _card,
              columns: [
                AppTableColumn(
                    header: 'Sale',
                    cell: (s) => Text('#${s.id}',
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                AppTableColumn(
                    header: 'Patient',
                    cell: (s) => Text(s.patientName ?? 'Walk-in')),
                AppTableColumn(
                    header: 'Date',
                    cell: (s) => Text(Helpers.formatDateTime(s.createdAt))),
                AppTableColumn(
                    header: 'Method',
                    cell: (s) => Text(Helpers.snakeToTitle(s.paymentMethod))),
                AppTableColumn(
                    header: 'Status',
                    cell: (s) => Text(Helpers.snakeToTitle(s.paymentStatus))),
                AppTableColumn(
                    header: 'Total',
                    cell: (s) => Text(Helpers.formatCurrency(s.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w800))),
                AppTableColumn(
                    header: 'Invoice',
                    cell: (s) => IconButton(
                        icon: const Icon(Icons.receipt_long_rounded,
                            color: AppColors.primary),
                        onPressed: () => _invoice(s))),
              ],
            ),
        ]),
      );

  Widget _card(PharmacySaleModel s) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .88),
              Colors.white.withValues(alpha: .65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: .05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .16),
                  AppColors.primaryLight.withValues(alpha: .07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('#${s.id}  •  ${Helpers.formatCurrency(s.totalAmount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              Text(
                '${s.patientName ?? 'Walk-in'}  •  ${Helpers.formatDateTime(s.createdAt)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ]),
          ),
          GestureDetector(
            onTap: () => _invoice(s),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: .2)),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ),
        ]),
      );

  void _invoice(PharmacySaleModel s) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => InvoiceScreen(saleId: s.id)));
}
