import 'package:flutter/material.dart';
import '../../models/medicine_model.dart';
import '../utils/validators.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

class MedicineForm extends StatefulWidget {
  final MedicineModel? medicine;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const MedicineForm({super.key, this.medicine, required this.onSubmit});

  @override
  State<MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends State<MedicineForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.medicine?.medicineName ?? '');
  late final _category =
      TextEditingController(text: widget.medicine?.category ?? '');
  late final _batch =
      TextEditingController(text: widget.medicine?.batchNumber ?? '');
  late final _expiry =
      TextEditingController(text: widget.medicine?.expiryDate ?? '');
  late final _purchase = TextEditingController(
      text: widget.medicine == null ? '' : '${widget.medicine!.purchasePrice}');
  late final _sale = TextEditingController(
      text: widget.medicine == null ? '' : '${widget.medicine!.salePrice}');
  late final _quantity = TextEditingController(
      text: widget.medicine == null ? '' : '${widget.medicine!.quantity}');
  late final _supplier =
      TextEditingController(text: widget.medicine?.supplier ?? '');
  late final _rack =
      TextEditingController(text: widget.medicine?.rackNumber ?? '');
  late final _lowLimit = TextEditingController(
      text:
          widget.medicine == null ? '10' : '${widget.medicine!.lowStockLimit}');
  late String _status = widget.medicine?.status ?? 'active';
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _category,
      _batch,
      _expiry,
      _purchase,
      _sale,
      _quantity,
      _supplier,
      _rack,
      _lowLimit
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSubmit({
      'medicine_name': _name.text.trim(),
      'category': _category.text.trim(),
      'batch_number': _batch.text.trim(),
      'expiry_date': _expiry.text.trim(),
      'purchase_price': double.parse(_purchase.text),
      'sale_price': double.parse(_sale.text),
      'quantity': int.parse(_quantity.text),
      'supplier': _supplier.text.trim(),
      'rack_number': _rack.text.trim(),
      'low_stock_limit': int.parse(_lowLimit.text),
      'status': _status,
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            _field(_name, 'Medicine Name', validator: Validators.required),
            _field(_category, 'Category'),
            _field(_batch, 'Batch Number', validator: Validators.required),
            _field(_expiry, 'Expiry Date',
                hint: 'YYYY-MM-DD', validator: Validators.required),
            _field(_purchase, 'Purchase Price',
                keyboardType: TextInputType.number,
                validator: Validators.required),
            _field(_sale, 'Sale Price',
                keyboardType: TextInputType.number,
                validator: Validators.required),
            _field(_quantity, 'Quantity',
                keyboardType: TextInputType.number,
                validator: Validators.required),
            _field(_lowLimit, 'Low Stock Limit',
                keyboardType: TextInputType.number,
                validator: Validators.required),
            _field(_supplier, 'Supplier'),
            _field(_rack, 'Rack Number'),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          CustomButton(
            label: widget.medicine == null ? 'Add Medicine' : 'Save Medicine',
            icon: Icons.save_rounded,
            loading: _saving,
            onPressed: _submit,
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {String? hint,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return SizedBox(
      width: 260,
      child: CustomTextField(
        controller: c,
        label: label,
        hint: hint,
        keyboardType: keyboardType ?? TextInputType.text,
        validator: validator,
      ),
    );
  }
}
