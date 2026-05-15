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
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateSaleScreen()))
                .then((_) => _load()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Walk-in Sale'),
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

  Widget _card(PharmacySaleModel s) => Card(
          child: ListTile(
        title: Text('#${s.id} • ${Helpers.formatCurrency(s.totalAmount)}'),
        subtitle: Text(
            '${s.patientName ?? 'Walk-in'} • ${Helpers.formatDateTime(s.createdAt)}'),
        trailing: IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => _invoice(s)),
      ));

  void _invoice(PharmacySaleModel s) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => InvoiceScreen(saleId: s.id)));
}
