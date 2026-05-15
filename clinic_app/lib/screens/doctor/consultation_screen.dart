import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/doctor_service.dart';
import '../../core/services/prescription_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/lab_test_form.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/prescription_medicine_form.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';

class ConsultationScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const ConsultationScreen({super.key, required this.appointment});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptoms = TextEditingController();
  final _diagnosis = TextEditingController();
  final _notes = TextEditingController();
  final _followUp = TextEditingController();
  final List<PrescriptionMedicineDraft> _medicines = [PrescriptionMedicineDraft()];
  final List<LabTestDraft> _labTests = [];
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startAndLoad();
  }

  @override
  void dispose() {
    _symptoms.dispose();
    _diagnosis.dispose();
    _notes.dispose();
    _followUp.dispose();
    for (final m in _medicines) { m.dispose(); }
    for (final t in _labTests) { t.dispose(); }
    super.dispose();
  }

  Future<void> _startAndLoad() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.appointment.status != 'in_consultation') {
        await DoctorService.startConsultation(widget.appointment.id);
      }
      if (widget.appointment.patientId != null) {
        _profile = await DoctorService.patientProfile(widget.appointment.patientId!);
      }
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickFollowUp() async {
    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now().add(const Duration(days: 7)));
    if (d != null) _followUp.text = DateFormat('yyyy-MM-dd').format(d);
  }

  Future<void> _save({required bool complete}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final meds = _medicines.map((m) => m.toJson()).where((m) => (m['medicine_name'] as String).isNotEmpty).toList();
      final tests = _labTests.map((t) => t.toJson()).where((t) => (t['test_name'] as String).isNotEmpty).toList();
      await PrescriptionService.create({
        'appointment_id': widget.appointment.id,
        'patient_id': widget.appointment.patientId,
        'symptoms': _symptoms.text.trim(),
        'diagnosis': _diagnosis.text.trim(),
        'notes': _notes.text.trim(),
        'follow_up_date': _followUp.text.trim().isEmpty ? null : _followUp.text.trim(),
        'medicines': meds,
        'lab_tests': tests,
        'mark_appointment_completed': complete,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription saved.'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final patient = _profile['patient'] as Map<String, dynamic>? ?? {};
    final vitals = (_profile['vitals'] as List? ?? []).take(3).toList();
    final prescriptions = (_profile['prescriptions'] as List? ?? []).take(3).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Consultation • Token ${widget.appointment.tokenNumber}')),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Panel(title: patient['name'] as String? ?? widget.appointment.patientName, child: Text([patient['patient_code'], patient['phone'], patient['blood_group']].where((e) => e != null && '$e'.isNotEmpty).join(' • '))),
                      const SizedBox(height: 14),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 2, child: Column(children: [
                          _Panel(title: 'Consultation Notes', child: Column(children: [
                            CustomTextField(label: 'Symptoms', controller: _symptoms, maxLines: 3, validator: (v) => v == null || v.trim().isEmpty ? 'Symptoms are required.' : null),
                            const SizedBox(height: 12),
                            CustomTextField(label: 'Diagnosis', controller: _diagnosis, maxLines: 3, validator: (v) => v == null || v.trim().isEmpty ? 'Diagnosis is required.' : null),
                            const SizedBox(height: 12),
                            CustomTextField(label: 'Notes', controller: _notes, maxLines: 3),
                            const SizedBox(height: 12),
                            CustomTextField(label: 'Follow-up date', controller: _followUp, readOnly: true, onTap: _pickFollowUp, prefixIcon: Icons.event_repeat_rounded),
                          ])),
                          const SizedBox(height: 14),
                          _Panel(title: 'Medicines', action: TextButton.icon(onPressed: () => setState(() => _medicines.add(PrescriptionMedicineDraft())), icon: const Icon(Icons.add_rounded), label: const Text('Add')), child: Column(children: [
                            for (int i = 0; i < _medicines.length; i++) Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PrescriptionMedicineForm(draft: _medicines[i], index: i, onRemove: () => setState(() { if (_medicines.length > 1) _medicines.removeAt(i).dispose(); })),
                            ),
                          ])),
                          const SizedBox(height: 14),
                          _Panel(title: 'Lab Tests', action: TextButton.icon(onPressed: () => setState(() => _labTests.add(LabTestDraft())), icon: const Icon(Icons.add_rounded), label: const Text('Add')), child: _labTests.isEmpty ? const Text('No lab tests added.', style: TextStyle(color: AppColors.textSecondary)) : Column(children: [
                            for (int i = 0; i < _labTests.length; i++) Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LabTestForm(draft: _labTests[i], index: i, onRemove: () => setState(() => _labTests.removeAt(i).dispose())),
                            ),
                          ])),
                        ])),
                        const SizedBox(width: 14),
                        Expanded(child: Column(children: [
                          _Panel(title: 'Recent Vitals', child: vitals.isEmpty ? const Text('No vitals yet.', style: TextStyle(color: AppColors.textSecondary)) : Column(children: vitals.map((v) => ListTile(contentPadding: EdgeInsets.zero, title: Text('BP ${v['blood_pressure'] ?? '-'} • Pulse ${v['pulse'] ?? '-'}'), subtitle: Text('${v['temperature'] ?? '-'}° • O₂ ${v['oxygen_level'] ?? '-'}'))).toList())),
                          const SizedBox(height: 14),
                          _Panel(title: 'Previous Prescriptions', child: prescriptions.isEmpty ? const Text('No previous prescriptions.', style: TextStyle(color: AppColors.textSecondary)) : Column(children: prescriptions.map((p) => ListTile(contentPadding: EdgeInsets.zero, title: Text(p['diagnosis'] as String? ?? 'Prescription #${p['id']}'), subtitle: Text(p['created_at'] as String? ?? ''))).toList())),
                        ])),
                      ]),
                      const SizedBox(height: 18),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        CustomButton(label: 'Save Prescription', icon: Icons.save_rounded, loading: _saving, onPressed: () => _save(complete: false)),
                        CustomButton(label: 'Save & Complete', icon: Icons.check_circle_rounded, variant: ButtonVariant.secondary, loading: _saving, onPressed: () => _save(complete: true)),
                      ]),
                    ]),
                  ),
                ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Panel({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), if (action != null) action!]),
      const SizedBox(height: 12),
      child,
    ]),
  );
}
