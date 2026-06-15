import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/super_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/data_card_list.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_surface.dart';
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
      message:
          'Approve "${clinic.clinicName}" and activate all user accounts?',
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: .14),
                    AppColors.warning.withValues(alpha: .06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: .32)),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.warning.withValues(alpha: .10),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: .3)),
                  ),
                  child: const Icon(Icons.pending_actions_rounded,
                      color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      '${_clinics.length} clinic${_clinics.length == 1 ? '' : 's'} awaiting approval.',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
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
            Icon(Icons.check_circle_rounded, size: 56, color: AppColors.success),
            SizedBox(height: 12),
            Text('No pending approvals.',
                style:
                    TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    return DataCardList<ClinicModel>(
      items: _clinics,
      builder: (c) => ColoredGlassCard(
        color: AppColors.warning,
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withValues(alpha: .18),
                      AppColors.warning.withValues(alpha: .08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: .28)),
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c.clinicName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${c.ownerName}  •  ${c.city}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
              Text(
                Helpers.formatDate(c.createdAt),
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ]),
          ),
          Divider(
              height: 1, color: AppColors.divider.withValues(alpha: .5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              _FeatureChip(
                  icon: Icons.medical_services_rounded,
                  label: '${c.numberOfDoctors ?? 0} Dr'),
              if (c.hasReceptionist) ...[
                const SizedBox(width: 8),
                const _FeatureChip(
                    icon: Icons.support_agent_rounded, label: 'Reception'),
              ],
              if (c.hasPharmacy) ...[
                const SizedBox(width: 8),
                const _FeatureChip(
                    icon: Icons.local_pharmacy_rounded, label: 'Pharmacy'),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ClinicDetailScreen(clinicId: c.id)),
                ).then((_) => _load()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: .25)),
                  ),
                  child: const Text('Details',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _approve(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: .8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.success.withValues(alpha: .3),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text('Approve',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}
