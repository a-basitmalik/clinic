import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/super_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/data_card_list.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/clinic_model.dart';
import '../../routes/app_routes.dart';
import 'clinic_detail_screen.dart';

class PendingClinicsScreen extends StatefulWidget {
  const PendingClinicsScreen({super.key});

  @override
  State<PendingClinicsScreen> createState() => _PendingClinicsScreenState();
}

class _PendingClinicsScreenState extends State<PendingClinicsScreen> {
  List<ClinicModel> _clinics = [];
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
      _clinics = await SuperAdminService.getPendingClinics();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _approve(ClinicModel clinic) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Approve Clinic',
      message: 'Approve "${clinic.clinicName}" and activate all user accounts?',
      confirmLabel: 'Approve',
      confirmColor: AppColors.success,
    );
    if (!ok || !mounted) return;
    try {
      await SuperAdminService.approveClinic(clinic.id);
      _snack('${clinic.clinicName} approved.', success: true);
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: success ? AppColors.success : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.pendingApprovals,
      currentRoute: AppRoutes.pendingApprovals,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_loading && _clinics.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.pending_actions_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Text(
                    '${_clinics.length} clinic${_clinics.length == 1 ? '' : 's'} awaiting approval.',
                    style: const TextStyle(
                        color: AppColors.warning, fontWeight: FontWeight.w500)),
              ]),
            ),
          if (!_loading && _clinics.isNotEmpty) const SizedBox(height: 16),
          if (_loading)
            const LoadingWidget()
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else
            _buildList(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_clinics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_rounded,
                size: 56, color: AppColors.success),
            SizedBox(height: 12),
            Text('No pending approvals.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    return DataCardList<ClinicModel>(
      items: _clinics,
      builder: (c) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_hospital_rounded,
                    color: AppColors.warning, size: 22),
              ),
              title: Text(c.clinicName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${c.ownerName} • ${c.city}'),
              trailing: Text(
                Helpers.formatDate(c.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${c.numberOfDoctors ?? 0} doctors',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (c.hasReceptionist) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.support_agent_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    const Text('Receptionist',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  if (c.hasPharmacy) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.local_pharmacy_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    const Text('Pharmacy',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ClinicDetailScreen(clinicId: c.id)),
                    ).then((_) => _load()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child:
                        const Text('Details', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approve(c),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label:
                        const Text('Approve', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
