import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/appointment_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/token_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import 'billing_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final int appointmentId;
  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  AppointmentModel? _appt;
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
      _appt = await AppointmentService.getAppointment(widget.appointmentId);
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

  Future<void> _updateStatus(String status) async {
    setState(() => _actioning = true);
    try {
      _appt =
          await AppointmentService.updateStatus(widget.appointmentId, status);
      _snack('Status updated.', success: true);
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<void> _cancel() async {
    final reasonCtrl = TextEditingController();
    final ok = await ConfirmDialog.show(
      context,
      title: 'Cancel Appointment',
      message: 'Cancel this appointment? This action cannot be undone.',
      confirmLabel: 'Cancel Appointment',
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
      _appt = await AppointmentService.cancelAppointment(
        widget.appointmentId,
        reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      );
      _snack('Appointment cancelled.');
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _actioning = false);
      reasonCtrl.dispose();
    }
  }

  Future<void> _reschedule() async {
    final dateCtrl = TextEditingController(text: _appt?.appointmentDate ?? '');
    final timeCtrl = TextEditingController(text: _appt?.appointmentTime ?? '');

    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reschedule Appointment'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'New Date',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        DateTime.tryParse(dateCtrl.text) ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    dateCtrl.text =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: timeCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'New Time',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                onTap: () async {
                  final parts = timeCtrl.text.split(':');
                  final init = parts.length == 2
                      ? TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 9,
                          minute: int.tryParse(parts[1]) ?? 0)
                      : const TimeOfDay(hour: 9, minute: 0);
                  final picked =
                      await showTimePicker(context: ctx, initialTime: init);
                  if (picked != null) {
                    timeCtrl.text =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Reschedule')),
            ],
          ),
        ) ??
        false;

    if (!ok || !mounted) return;
    setState(() => _actioning = true);
    try {
      _appt = await AppointmentService.rescheduleAppointment(
        widget.appointmentId,
        date: dateCtrl.text,
        time: timeCtrl.text,
      );
      _snack('Appointment rescheduled.', success: true);
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _actioning = false);
      dateCtrl.dispose();
      timeCtrl.dispose();
    }
  }

  void _openBilling() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillingScreen(appointment: _appt),
        )).then((_) => _load());
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
        title: const Text('Appointment Details',
            style: TextStyle(
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
    final a = _appt!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Token + status header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            TokenBadge(a.tokenNumber, size: 60),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(a.patientName,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  if (a.patientCode != null)
                    Text(a.patientCode!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(children: [
                    StatusBadge(a.status),
                    const SizedBox(width: 8),
                    StatusBadge(a.paymentStatus)
                  ]),
                ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Actions (not shown if actioning or terminal status)
        if (_actioning)
          const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator()))
        else if (!a.isCancelled) ...[
          _buildActions(a),
          const SizedBox(height: 16),
        ],

        // Info
        _Section('Appointment', [
          _Row('Doctor', 'Dr. ${a.doctorName}'),
          if (a.departmentName != null) _Row('Department', a.departmentName!),
          _Row('Date', Helpers.formatDate(a.appointmentDate)),
          _Row('Time', Helpers.formatTime(a.appointmentTime)),
          _Row('Type', _typeLabel(a.consultationType)),
        ]),
        const SizedBox(height: 16),
        _Section('Payment', [
          _Row('Fee', Helpers.formatCurrency(a.fee)),
          _Row('Status', a.paymentStatus),
          if (a.paidAmount != null)
            _Row('Paid', Helpers.formatCurrency(a.paidAmount)),
          if (a.paymentMethod != null)
            _Row('Method', _methodLabel(a.paymentMethod!)),
        ]),
        if (a.notes != null) ...[
          const SizedBox(height: 16),
          _Section('Notes', [_Row('', a.notes!)]),
        ],
      ]),
    );
  }

  Widget _buildActions(AppointmentModel a) {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      if (!a.isPaid)
        ElevatedButton.icon(
          onPressed: _openBilling,
          icon: const Icon(Icons.payments_rounded, size: 16),
          label: const Text('Collect Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      if (a.status == 'waiting')
        OutlinedButton.icon(
          onPressed: () => _updateStatus('in_consultation'),
          icon: const Icon(Icons.medical_services_rounded, size: 16),
          label: const Text('Send to Doctor'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      if (a.status == 'in_consultation')
        OutlinedButton.icon(
          onPressed: () => _updateStatus('completed'),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
          label: const Text('Mark Complete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.success,
            side: const BorderSide(color: AppColors.success),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      if (a.isActive)
        OutlinedButton.icon(
          onPressed: _reschedule,
          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
          label: const Text('Reschedule'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      if (a.isActive)
        OutlinedButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.cancel_outlined, size: 16),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ),
        Padding(
            padding: const EdgeInsets.all(14), child: Column(children: rows)),
      ]),
    );
  }

  Widget _Row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          if (label.isNotEmpty)
            SizedBox(
                width: 100,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      );

  String _typeLabel(String s) {
    const m = {
      'new': 'New Patient',
      'followup': 'Follow-up',
      'emergency': 'Emergency'
    };
    return m[s] ?? s;
  }

  String _methodLabel(String s) {
    const m = {
      'cash': 'Cash',
      'card': 'Card',
      'easypaisa': 'EasyPaisa',
      'jazzcash': 'JazzCash',
      'bank': 'Bank Transfer'
    };
    return m[s] ?? s;
  }
}
