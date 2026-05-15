import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/prescription_service.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/prescription_preview.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/prescription_model.dart';
import '../../routes/app_routes.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  List<PrescriptionModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _items = await PrescriptionService.list();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _open(PrescriptionModel p) => showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: PrescriptionPreview(prescription: p)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Prescriptions',
      currentRoute: AppRoutes.prescriptions,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No prescriptions found.', style: TextStyle(color: AppColors.textSecondary))))
                  : Column(children: _items.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                        title: Text(p.diagnosis ?? 'Prescription #${p.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Patient #${p.patientId ?? '-'} • Pharmacy: ${p.pharmacyStatus.replaceAll('_', ' ')}'),
                        trailing: const Icon(Icons.print_rounded),
                        onTap: () => _open(p),
                      ),
                    )).toList()),
    );
  }
}
