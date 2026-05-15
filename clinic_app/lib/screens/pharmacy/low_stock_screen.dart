import 'package:flutter/material.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/medicine_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/medicine_model.dart';
import '../../routes/app_routes.dart';
import 'add_edit_medicine_screen.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  List<MedicineModel> _items = [];
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
      _items = await PharmacyService.lowStock();
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
        title: 'Low Stock Alerts',
        currentRoute: AppRoutes.lowStock,
        body: _loading
            ? const LoadingWidget()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : Column(
                    children: _items
                        .map((m) => MedicineCard(
                              medicine: m,
                              onEdit: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => AddEditMedicineScreen(
                                          medicine: m, onSaved: _load))),
                            ))
                        .toList()),
      );
}
