import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_table.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/expiry_badge.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/medicine_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../core/widgets/stock_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/medicine_model.dart';
import '../../routes/app_routes.dart';
import 'add_edit_medicine_screen.dart';

class MedicineInventoryScreen extends StatefulWidget {
  const MedicineInventoryScreen({super.key});

  @override
  State<MedicineInventoryScreen> createState() =>
      _MedicineInventoryScreenState();
}

class _MedicineInventoryScreenState extends State<MedicineInventoryScreen> {
  List<MedicineModel> _items = [];
  bool _loading = true;
  String? _error;
  String? _search;
  String? _status = 'active';

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
      _items = await PharmacyService.items(search: _search, status: _status);
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  Future<void> _openForm([MedicineModel? medicine]) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AddEditMedicineScreen(medicine: medicine, onSaved: _load)));
    _load();
  }

  Future<void> _delete(MedicineModel medicine) async {
    await PharmacyService.deleteItem(medicine.id);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Medicine deactivated.')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Medicine Inventory',
      currentRoute: AppRoutes.inventory,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SearchFilterBar(
          hint: 'Search medicine, batch, supplier',
          onSearch: (q) {
            _search = q;
            _load();
          },
          onAdd: () => _openForm(),
          addLabel: 'Add Medicine',
          filters: [_statusFilter()],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
          AppTable<MedicineModel>(
            rows: _items,
            emptyMessage: 'No medicines found.',
            mobileCard: (m) => MedicineCard(
                medicine: m,
                onEdit: () => _openForm(m),
                onDelete: () => _delete(m)),
            columns: [
              AppTableColumn(
                  header: 'Medicine',
                  cell: (m) => Text(m.medicineName,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              AppTableColumn(
                  header: 'Category', cell: (m) => Text(m.category ?? '-')),
              AppTableColumn(
                  header: 'Batch', cell: (m) => Text(m.batchNumber ?? '-')),
              AppTableColumn(
                  header: 'Stock',
                  cell: (m) => StockBadge(
                      quantity: m.quantity, lowStockLimit: m.lowStockLimit)),
              AppTableColumn(
                  header: 'Expiry',
                  cell: (m) => ExpiryBadge(expiryDate: m.expiryDate)),
              AppTableColumn(
                  header: 'Price',
                  cell: (m) => Text(Helpers.formatCurrency(m.salePrice))),
              AppTableColumn(
                  header: 'Actions',
                  cell: (m) => Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            onPressed: () => _openForm(m),
                            icon: const Icon(Icons.edit_rounded, size: 18)),
                        IconButton(
                            onPressed: () => _delete(m),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.danger)),
                      ])),
            ],
          ),
      ]),
    );
  }

  Widget _statusFilter() => SizedBox(
        width: 150,
        child: DropdownButtonFormField<String?>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: null, child: Text('All')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
          ],
          onChanged: (v) {
            setState(() => _status = v);
            _load();
          },
        ),
      );
}
