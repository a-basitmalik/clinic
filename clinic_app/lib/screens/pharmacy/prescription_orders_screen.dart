import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_table.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/prescription_order_model.dart';
import '../../routes/app_routes.dart';
import 'create_sale_screen.dart';
import 'order_details_screen.dart';

class PrescriptionOrdersScreen extends StatefulWidget {
  const PrescriptionOrdersScreen({super.key});

  @override
  State<PrescriptionOrdersScreen> createState() =>
      _PrescriptionOrdersScreenState();
}

class _PrescriptionOrdersScreenState extends State<PrescriptionOrdersScreen> {
  List<PrescriptionOrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  String? _status;

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
      _orders = await PharmacyService.prescriptionOrders(status: _status);
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
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Prescription Orders',
      currentRoute: AppRoutes.pharmacyOrders,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                    value: 'partial_dispensed', child: Text('Partial')),
                DropdownMenuItem(value: 'dispensed', child: Text('Dispensed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (v) {
                setState(() => _status = v);
                _load();
              },
            )),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
          AppTable<PrescriptionOrderModel>(
            rows: _orders,
            emptyMessage: 'No prescription orders found.',
            mobileCard: _card,
            columns: [
              AppTableColumn(
                  header: 'ID', cell: (o) => Text('#${o.prescriptionId}')),
              AppTableColumn(
                  header: 'Patient',
                  cell: (o) => Text(o.patientName,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              AppTableColumn(header: 'Doctor', cell: (o) => Text(o.doctorName)),
              AppTableColumn(
                  header: 'Date',
                  cell: (o) => Text(
                      Helpers.formatDate(o.appointmentDate ?? o.createdAt))),
              AppTableColumn(
                  header: 'Status',
                  cell: (o) => Text(Helpers.snakeToTitle(o.pharmacyStatus))),
              AppTableColumn(
                  header: 'Actions',
                  cell: (o) => Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            icon: const Icon(Icons.visibility_rounded),
                            onPressed: () => _details(o)),
                        IconButton(
                            icon: const Icon(Icons.point_of_sale_rounded,
                                color: AppColors.primary),
                            onPressed: () => _sale(o)),
                      ])),
            ],
          ),
      ]),
    );
  }

  Widget _card(PrescriptionOrderModel o) => Card(
          child: ListTile(
        title: Text('${o.patientName} • #${o.prescriptionId}'),
        subtitle:
            Text('${o.doctorName} • ${Helpers.snakeToTitle(o.pharmacyStatus)}'),
        trailing: IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _details(o)),
      ));

  void _details(PrescriptionOrderModel o) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              OrderDetailsScreen(prescriptionId: o.prescriptionId)));
  void _sale(PrescriptionOrderModel o) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => CreateSaleScreen(order: o)));
}
