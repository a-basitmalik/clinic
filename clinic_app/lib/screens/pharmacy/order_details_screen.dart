import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/api_response_model.dart';
import '../../models/prescription_order_model.dart';
import 'create_sale_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int prescriptionId;

  const OrderDetailsScreen({super.key, required this.prescriptionId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  PrescriptionOrderModel? _order;
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
      _order = await PharmacyService.prescriptionOrder(widget.prescriptionId);
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  Future<void> _setStatus(String status) async {
    await PharmacyService.updateOrderStatus(widget.prescriptionId, status);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prescription #${widget.prescriptionId}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const LoadingWidget()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : _content(context, _order!),
      ),
    );
  }

  Widget _content(BuildContext context, PrescriptionOrderModel order) {
    return ListView(children: [
      Wrap(spacing: 24, runSpacing: 8, children: [
        _meta('Patient', order.patientName),
        _meta('Doctor', order.doctorName),
        _meta('Date',
            Helpers.formatDate(order.appointmentDate ?? order.createdAt)),
        _meta('Status', Helpers.snakeToTitle(order.pharmacyStatus)),
      ]),
      const SizedBox(height: 20),
      ...order.medicines.map((m) => Card(
            child: ListTile(
              leading: const Icon(Icons.medication_rounded,
                  color: AppColors.primary),
              title: Text(m.prescribed.medicineName),
              subtitle: Text([
                m.prescribed.dosage,
                m.prescribed.frequency,
                m.prescribed.duration,
                'Stock: ${m.availableStock}',
              ].where((e) => e != null && e.toString().isNotEmpty).join(' • ')),
              trailing: Text(m.inventoryMatch?.medicineName ?? 'No match',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          )),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 12, children: [
        CustomButton(
          label: 'Create Sale',
          icon: Icons.point_of_sale_rounded,
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateSaleScreen(order: order))),
        ),
        CustomButton(
          label: 'Mark Partial',
          variant: ButtonVariant.outlined,
          onPressed: () => _setStatus('partial_dispensed'),
        ),
        CustomButton(
          label: 'Mark Dispensed',
          variant: ButtonVariant.secondary,
          onPressed: () => _setStatus('dispensed'),
        ),
      ]),
    ]);
  }

  Widget _meta(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]);
}
