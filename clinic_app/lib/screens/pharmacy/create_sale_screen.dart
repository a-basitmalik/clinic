import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/sale_item_row.dart';
import '../../models/api_response_model.dart';
import '../../models/medicine_model.dart';
import '../../models/prescription_order_model.dart';
import 'invoice_screen.dart';

class CreateSaleScreen extends StatefulWidget {
  final PrescriptionOrderModel? order;

  const CreateSaleScreen({super.key, this.order});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  List<MedicineModel> _medicines = [];
  final List<SaleItemDraft> _items = [SaleItemDraft()];
  String _paymentStatus = 'paid';
  String _paymentMethod = 'cash';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  double get _total => _items.fold(0, (sum, item) => sum + item.total);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _medicines = await PharmacyService.items(status: 'active');
      if (widget.order != null) {
        _items.clear();
        for (final med in widget.order!.medicines) {
          if (med.inventoryMatch != null) {
            _items
                .add(SaleItemDraft(medicine: med.inventoryMatch, quantity: 1));
          }
        }
        if (_items.isEmpty) _items.add(SaleItemDraft());
      }
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  Future<void> _submit() async {
    final valid =
        _items.where((i) => i.medicine != null && i.quantity > 0).toList();
    if (valid.isEmpty) {
      setState(() => _error = 'Add at least one medicine.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final sale = await PharmacyService.createSale({
        'patient_id': widget.order?.patientId,
        'prescription_id': widget.order?.prescriptionId,
        'payment_status': _paymentStatus,
        'payment_method': _paymentMethod,
        'items': valid
            .map((i) => {'medicine_id': i.medicine!.id, 'quantity': i.quantity})
            .toList(),
      });
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => InvoiceScreen(saleId: sale.id)));
      }
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _saving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.order == null
                ? 'Walk-in Sale'
                : 'Sale from Prescription #${widget.order!.prescriptionId}')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const LoadingWidget()
              : _error != null && _medicines.isEmpty
                  ? ErrorView(message: _error!, onRetry: _load)
                  : ListView(children: [
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: AppColors.dangerSurface,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.danger)),
                        ),
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        _dropdown(
                            'Payment Status',
                            _paymentStatus,
                            ['paid', 'pending'],
                            (v) => setState(() => _paymentStatus = v)),
                        _dropdown(
                            'Payment Method',
                            _paymentMethod,
                            ['cash', 'card', 'easypaisa', 'jazzcash', 'bank'],
                            (v) => setState(() => _paymentMethod = v)),
                      ]),
                      const SizedBox(height: 20),
                      ..._items.asMap().entries.map((entry) => SaleItemRow(
                            item: entry.value,
                            medicines: _medicines,
                            onChanged: () => setState(() {}),
                            onRemove: () => setState(() {
                              if (_items.length > 1) _items.removeAt(entry.key);
                            }),
                          )),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _items.add(SaleItemDraft())),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add item'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Total: ${Helpers.formatCurrency(_total)}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                          label: 'Create Sale',
                          icon: Icons.receipt_long_rounded,
                          loading: _saving,
                          onPressed: _submit),
                    ]),
        ),
      );

  Widget _dropdown(String label, String value, List<String> values,
          ValueChanged<String> onChanged) =>
      SizedBox(
        width: 220,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: values
              .map((v) => DropdownMenuItem(
                  value: v, child: Text(Helpers.snakeToTitle(v))))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
        ),
      );
}
