import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/super_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/clinic_model.dart';

class ClinicDetailScreen extends StatefulWidget {
  final int clinicId;
  const ClinicDetailScreen({super.key, required this.clinicId});

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  ClinicModel? _clinic;
  bool _loading = true;
  String? _error;
  bool _actioning = false;

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
      _clinic = await SuperAdminService.getClinicDetail(widget.clinicId);
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

  Future<void> _approve() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Approve Clinic',
      message: 'Activate "${_clinic!.clinicName}" and all its user accounts?',
      confirmLabel: 'Approve',
      confirmColor: AppColors.success,
    );
    if (!ok || !mounted) return;
    setState(() => _actioning = true);
    try {
      await SuperAdminService.approveClinic(widget.clinicId);
      _snack('Clinic approved.', success: true);
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<void> _suspend() async {
    final reasonCtrl = TextEditingController();
    final ok = await ConfirmDialog.show(
      context,
      title: 'Suspend Clinic',
      message:
          'Suspending will block all users of this clinic from logging in.',
      confirmLabel: 'Suspend',
      extraContent: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
    if (!ok || !mounted) return;
    setState(() => _actioning = true);
    try {
      await SuperAdminService.suspendClinic(widget.clinicId,
          reason:
              reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim());
      _snack('Clinic suspended.');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<void> _unsuspend() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Reactivate Clinic',
      message: 'Reactivate "${_clinic!.clinicName}" and restore access?',
      confirmLabel: 'Reactivate',
      confirmColor: AppColors.success,
    );
    if (!ok || !mounted) return;
    setState(() => _actioning = true);
    try {
      await SuperAdminService.unsuspendClinic(widget.clinicId);
      _snack('Clinic reactivated.', success: true);
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _actioning = false);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(_clinic?.clinicName ?? 'Clinic Details',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final c = _clinic!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(c.clinicName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(c.ownerName,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    StatusBadge(c.status, fontSize: 12),
                  ])),
            ]),
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (!_actioning) _buildActions(c),
          if (_actioning)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator())),
          const SizedBox(height: 20),

          // Info sections
          _Section('Contact', [
            _Row('Email', c.email),
            _Row('Phone', c.phone ?? '—'),
            _Row('Address', c.address ?? '—'),
            _Row('City', c.city),
          ]),
          const SizedBox(height: 16),
          _Section('Clinic Details', [
            _Row(
                'Type',
                c.clinicType == 'single_doctor'
                    ? 'Single Doctor'
                    : 'Multi Doctor'),
            _Row('Doctors', '${c.numberOfDoctors ?? 0}'),
            _Row('Receptionist', c.hasReceptionist ? 'Yes' : 'No'),
            _Row('Pharmacy', c.hasPharmacy ? 'Yes' : 'No'),
            _Row('Opening', c.openingTime ?? '—'),
            _Row('Closing', c.closingTime ?? '—'),
            _Row('Working Days',
                c.workingDays.map((d) => d.substring(0, 3)).join(', ')),
          ]),
          const SizedBox(height: 16),
          _Section('Timestamps', [
            _Row('Registered', Helpers.formatDate(c.createdAt)),
            _Row('Approved At',
                c.approvedAt != null ? Helpers.formatDate(c.approvedAt) : '—'),
          ]),
        ],
      ),
    );
  }

  Widget _buildActions(ClinicModel c) {
    return Row(children: [
      if (c.isPending)
        Expanded(
          child: CustomButton(
            label: 'Approve',
            icon: Icons.check_rounded,
            onPressed: _approve,
          ),
        ),
      if (c.isApproved) ...[
        Expanded(
          child: CustomButton(
            label: 'Suspend',
            variant: ButtonVariant.danger,
            icon: Icons.block_rounded,
            onPressed: _suspend,
          ),
        ),
      ],
      if (c.isSuspended) ...[
        Expanded(
          child: CustomButton(
            label: 'Reactivate',
            variant: ButtonVariant.secondary,
            icon: Icons.check_circle_rounded,
            onPressed: _unsuspend,
          ),
        ),
      ],
    ]);
  }

  Widget _Section(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: rows),
        ),
      ]),
    );
  }

  Widget _Row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
