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

class ExpiryAlertsScreen extends StatefulWidget {
  const ExpiryAlertsScreen({super.key});

  @override
  State<ExpiryAlertsScreen> createState() => _ExpiryAlertsScreenState();
}

class _ExpiryAlertsScreenState extends State<ExpiryAlertsScreen> {
  List<MedicineModel> _items = [];
  bool _expired = false;
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
      _items = await PharmacyService.expiring(expired: _expired);
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
        title: 'Expiry Alerts',
        currentRoute: AppRoutes.expiryAlerts,
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                  value: false,
                  label: Text('Expiring Soon'),
                  icon: Icon(Icons.event_available_rounded)),
              ButtonSegment(
                  value: true,
                  label: Text('Expired'),
                  icon: Icon(Icons.event_busy_rounded)),
            ],
            selected: {_expired},
            onSelectionChanged: (v) {
              setState(() => _expired = v.first);
              _load();
            },
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LoadingWidget()
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else
            Column(
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
        ]),
      );
}
