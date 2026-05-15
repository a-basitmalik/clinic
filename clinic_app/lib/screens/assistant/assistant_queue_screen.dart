import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/assistant_service.dart';
import '../../core/services/prescription_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/queue_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/vitals_form.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../routes/app_routes.dart';

class AssistantQueueScreen extends StatefulWidget {
  final AppointmentModel? initialAppointment;
  const AssistantQueueScreen({super.key, this.initialAppointment});

  @override
  State<AssistantQueueScreen> createState() => _AssistantQueueScreenState();
}

class _AssistantQueueScreenState extends State<AssistantQueueScreen> {
  List<AppointmentModel> _queue = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (widget.initialAppointment != null && mounted) {
        _openActions(widget.initialAppointment!);
      }
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _queue = await AssistantService.queue();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _callNext(AppointmentModel a) async {
    try {
      await AssistantService.callNext(a.id);
      _snack('Patient called.', success: true);
      _load();
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String msg, {bool success = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: success ? AppColors.success : null));

  Future<void> _openActions(AppointmentModel a) async {
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _AssistantActionsSheet(appointment: a, onDone: () { Navigator.pop(context); _load(); }));
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Assistant Queue',
      currentRoute: AppRoutes.assistantQueue,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _queue.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No patients in queue.', style: TextStyle(color: AppColors.textSecondary))))
                  : Column(children: _queue.map((a) => QueueCard(
                      appointment: a,
                      primaryLabel: 'Actions',
                      primaryIcon: Icons.tune_rounded,
                      onPrimary: () => _openActions(a),
                      onTap: () => _callNext(a),
                    )).toList()),
    );
  }
}

class _AssistantActionsSheet extends StatefulWidget {
  final AppointmentModel appointment;
  final VoidCallback onDone;
  const _AssistantActionsSheet({required this.appointment, required this.onDone});

  @override
  State<_AssistantActionsSheet> createState() => _AssistantActionsSheetState();
}

class _AssistantActionsSheetState extends State<_AssistantActionsSheet> {
  final _vitals = VitalsDraft();
  final _symptoms = TextEditingController();
  final _summary = TextEditingController();
  final _reportTitle = TextEditingController();
  final _reportType = TextEditingController();
  final _reportUrl = TextEditingController();
  final _reportNotes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _vitals.dispose();
    _symptoms.dispose();
    _summary.dispose();
    _reportTitle.dispose();
    _reportType.dispose();
    _reportUrl.dispose();
    _reportNotes.dispose();
    super.dispose();
  }

  Future<void> _saveVitals() async {
    if (widget.appointment.patientId == null) return;
    setState(() => _saving = true);
    try {
      await AssistantService.addVitals(_vitals.toJson(patientId: widget.appointment.patientId!, appointmentId: widget.appointment.id));
      widget.onDone();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveDraft() async {
    if (widget.appointment.patientId == null) return;
    setState(() => _saving = true);
    try {
      await AssistantService.saveSymptomsDraft({
        'appointment_id': widget.appointment.id,
        'patient_id': widget.appointment.patientId,
        'symptoms_draft': _symptoms.text.trim(),
        'vitals_summary': _summary.text.trim(),
      });
      widget.onDone();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadReport() async {
    if (widget.appointment.patientId == null) return;
    setState(() => _saving = true);
    try {
      await AssistantService.uploadReport({
        'appointment_id': widget.appointment.id,
        'patient_id': widget.appointment.patientId,
        'report_title': _reportTitle.text.trim(),
        'report_type': _reportType.text.trim(),
        'file_url': _reportUrl.text.trim(),
        'notes': _reportNotes.text.trim(),
      });
      widget.onDone();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showHistory() async {
    if (widget.appointment.patientId == null) return;
    setState(() => _saving = true);
    try {
      final data = await AssistantService.patientHistory(widget.appointment.patientId!);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Patient History'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: Text(data.toString())),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showPrintData() async {
    setState(() => _saving = true);
    try {
      final rx = await PrescriptionService.byAppointment(widget.appointment.id);
      if (rx == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No prescription found for this appointment.')));
        return;
      }
      final data = await AssistantService.printData(rx.id);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Prescription Print Data'),
        content: SizedBox(width: 560, child: SingleChildScrollView(child: Text(data.toString()))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.appointment.patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text('Vitals', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          VitalsForm(draft: _vitals),
          const SizedBox(height: 10),
          CustomButton(label: 'Save Vitals', loading: _saving, icon: Icons.monitor_heart_rounded, onPressed: _saveVitals),
          const Divider(height: 32),
          const Text('Symptoms Draft', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          CustomTextField(label: 'Symptoms draft', controller: _symptoms, maxLines: 3),
          const SizedBox(height: 10),
          CustomTextField(label: 'Vitals summary', controller: _summary, maxLines: 2),
          const SizedBox(height: 10),
          CustomButton(label: 'Save Draft', variant: ButtonVariant.secondary, loading: _saving, icon: Icons.edit_note_rounded, onPressed: _saveDraft),
          const Divider(height: 32),
          const Text('Upload Report Metadata', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          CustomTextField(label: 'Report title', controller: _reportTitle),
          const SizedBox(height: 10),
          CustomTextField(label: 'Report type', controller: _reportType),
          const SizedBox(height: 10),
          CustomTextField(label: 'File URL', controller: _reportUrl),
          const SizedBox(height: 10),
          CustomTextField(label: 'Notes', controller: _reportNotes, maxLines: 2),
          const SizedBox(height: 10),
          CustomButton(label: 'Upload Metadata', loading: _saving, icon: Icons.upload_file_rounded, onPressed: _uploadReport),
          const Divider(height: 32),
          Wrap(spacing: 10, runSpacing: 10, children: [
            CustomButton(label: 'View History', variant: ButtonVariant.outlined, loading: _saving, icon: Icons.history_rounded, onPressed: _showHistory),
            CustomButton(label: 'Print Prescription', variant: ButtonVariant.outlined, loading: _saving, icon: Icons.print_rounded, onPressed: _showPrintData),
          ]),
        ]),
      ),
    );
  }
}
