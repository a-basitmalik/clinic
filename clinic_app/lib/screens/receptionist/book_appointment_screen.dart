import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/doctor_service.dart';
import '../../core/services/patient_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/patient_model.dart';

class BookAppointmentScreen extends StatefulWidget {
  final PatientModel? patient; // pre-filled if navigated from patient details
  const BookAppointmentScreen({super.key, this.patient});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Patient search
  PatientModel? _selectedPatient;
  final _patientSearchCtrl = TextEditingController();
  List<PatientModel> _patientResults = [];
  bool _searchingPatient = false;

  // Doctor
  List<DoctorModel> _doctors = [];
  DoctorModel? _selectedDoctor;
  bool _loadingDoctors = true;

  // Appointment fields
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _consultationType = 'new';
  String _paymentStatus = 'unpaid';
  String? _paymentMethod;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _selectedPatient = widget.patient;
      _patientSearchCtrl.text = widget.patient!.name;
    }
    _initDate();
    _loadDoctors();
  }

  void _initDate() {
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDoctors() async {
    try {
      _doctors = await DoctorService.getDoctors();
    } catch (_) {}
    if (mounted) setState(() => _loadingDoctors = false);
  }

  @override
  void dispose() {
    for (final c in [
      _patientSearchCtrl,
      _dateCtrl,
      _timeCtrl,
      _feeCtrl,
      _paidCtrl,
      _notesCtrl
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _searchPatients(String query) async {
    if (query.length < 2) {
      setState(() => _patientResults = []);
      return;
    }
    setState(() => _searchingPatient = true);
    try {
      _patientResults =
          await PatientService.getPatients(search: query, perPage: 10);
    } catch (_) {}
    if (mounted) setState(() => _searchingPatient = false);
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      _dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime() async {
    final init = const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      _timeCtrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  void _onDoctorChanged(DoctorModel? doc) {
    setState(() {
      _selectedDoctor = doc;
      if (doc?.consultationFee != null) {
        _feeCtrl.text = doc!.consultationFee!.toStringAsFixed(0);
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedPatient == null) {
      setState(() => _error = 'Please select a patient.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'patient_id': _selectedPatient!.id,
      'doctor_id': _selectedDoctor?.id,
      'appointment_date': _dateCtrl.text.trim(),
      'appointment_time': _timeCtrl.text.trim(),
      'consultation_type': _consultationType,
      'fee': double.tryParse(_feeCtrl.text.trim()),
      'payment_status': _paymentStatus,
      'paid_amount': double.tryParse(_paidCtrl.text.trim()),
      'payment_method': _paymentMethod,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      final appt = await AppointmentService.createAppointment(body);
      if (!mounted) return;
      await _showSuccess(appt);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSuccess(AppointmentModel appt) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12)
                ]),
            child: Center(
              child: Text('${appt.tokenNumber}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Token Number',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const Text('Appointment Booked!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '${appt.patientName} • Dr. ${appt.doctorName}',
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            '${Helpers.formatDate(appt.appointmentDate)} at ${appt.appointmentTime}',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reset();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Book Another'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    if (widget.patient == null) {
      setState(() {
        _selectedPatient = null;
        _patientSearchCtrl.clear();
      });
    }
    _timeCtrl.clear();
    _paidCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _paymentStatus = 'unpaid';
      _paymentMethod = null;
      _consultationType = 'new';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Book Appointment',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loadingDoctors
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.dangerSurface,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _Label('Patient'),
                      if (_selectedPatient != null) ...[
                        _SelectedPatientCard(
                            patient: _selectedPatient!,
                            onClear: widget.patient == null
                                ? () => setState(() {
                                      _selectedPatient = null;
                                      _patientSearchCtrl.clear();
                                    })
                                : null),
                      ] else ...[
                        _PatientSearchField(
                          ctrl: _patientSearchCtrl,
                          results: _patientResults,
                          loading: _searchingPatient,
                          onChanged: _searchPatients,
                          onSelected: (p) => setState(() {
                            _selectedPatient = p;
                            _patientSearchCtrl.text = p.name;
                            _patientResults = [];
                          }),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _Label('Doctor'),
                      CustomDropdown<DoctorModel?>(
                        label: 'Select Doctor',
                        value: _selectedDoctor,
                        items: _doctors
                            .where((d) => d.isActive)
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                      'Dr. ${d.name}${d.departmentName != null ? ' (${d.departmentName})' : ''}'),
                                ))
                            .toList(),
                        onChanged: (v) => _onDoctorChanged(v),
                      ),
                      const SizedBox(height: 20),
                      _Label('Schedule'),
                      Row(children: [
                        Expanded(
                            child: CustomTextField(
                          label: 'Date *',
                          controller: _dateCtrl,
                          readOnly: true,
                          onTap: _pickDate,
                          prefixIcon: Icons.calendar_today_rounded,
                          validator: Validators.required,
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: CustomTextField(
                          label: 'Time *',
                          controller: _timeCtrl,
                          readOnly: true,
                          onTap: _pickTime,
                          prefixIcon: Icons.access_time_rounded,
                          validator: Validators.required,
                        )),
                      ]),
                      const SizedBox(height: 12),
                      _Label('Consultation Type'),
                      _TypeSelector(
                          value: _consultationType,
                          onChanged: (v) =>
                              setState(() => _consultationType = v)),
                      const SizedBox(height: 20),
                      _Label('Payment'),
                      CustomTextField(
                        label: 'Consultation Fee (PKR)',
                        controller: _feeCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.payments_rounded,
                      ),
                      const SizedBox(height: 12),
                      _Label('Payment Status'),
                      _PaymentStatusSelector(
                          value: _paymentStatus,
                          onChanged: (v) => setState(() => _paymentStatus = v)),
                      if (_paymentStatus != 'unpaid') ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: CustomTextField(
                            label: 'Paid Amount (PKR)',
                            controller: _paidCtrl,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.account_balance_wallet_rounded,
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: CustomDropdown<String?>(
                            label: 'Payment Method',
                            value: _paymentMethod,
                            items: const [
                              DropdownMenuItem(
                                  value: 'cash', child: Text('Cash')),
                              DropdownMenuItem(
                                  value: 'card', child: Text('Card')),
                              DropdownMenuItem(
                                  value: 'easypaisa', child: Text('EasyPaisa')),
                              DropdownMenuItem(
                                  value: 'jazzcash', child: Text('JazzCash')),
                              DropdownMenuItem(
                                  value: 'bank', child: Text('Bank Transfer')),
                            ],
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v),
                          )),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Notes (optional)',
                        controller: _notesCtrl,
                        maxLines: 2,
                        prefixIcon: Icons.note_rounded,
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        label: 'Book Appointment',
                        icon: Icons.calendar_month_rounded,
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ]),
              ),
            ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );
}

class _SelectedPatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback? onClear;
  const _SelectedPatientCard({required this.patient, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.success.withValues(alpha: 0.2),
          child: Text(patient.name[0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(patient.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(
              '${patient.patientCode}${patient.phone != null ? ' • ${patient.phone}' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ])),
        if (onClear != null)
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: onClear,
          ),
      ]),
    );
  }
}

class _PatientSearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final List<PatientModel> results;
  final bool loading;
  final void Function(String) onChanged;
  final void Function(PatientModel) onSelected;

  const _PatientSearchField({
    required this.ctrl,
    required this.results,
    required this.loading,
    required this.onChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextFormField(
        controller: ctrl,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name, phone, CNIC, or code…',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 20),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        validator: (v) => null,
      ),
      if (results.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = results[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(p.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                title: Text(p.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text(
                    '${p.patientCode}${p.phone != null ? ' • ${p.phone}' : ''}',
                    style: const TextStyle(fontSize: 11)),
                onTap: () => onSelected(p),
              );
            },
          ),
        ),
    ]);
  }
}

class _TypeSelector extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _TypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Chip('new', 'New', value, onChanged),
      const SizedBox(width: 8),
      _Chip('followup', 'Follow-up', value, onChanged),
      const SizedBox(width: 8),
      _Chip('emergency', 'Emergency', value, onChanged),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String val, label, current;
  final void Function(String) onChanged;
  const _Chip(this.val, this.label, this.current, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final active = val == current;
    Color c = val == 'emergency'
        ? AppColors.danger
        : (val == 'followup' ? AppColors.accent : AppColors.primary);
    return GestureDetector(
      onTap: () => onChanged(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? c : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}

class _PaymentStatusSelector extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _PaymentStatusSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _PSChip('unpaid', 'Unpaid', value, onChanged),
      const SizedBox(width: 8),
      _PSChip('paid', 'Paid', value, onChanged),
      const SizedBox(width: 8),
      _PSChip('partial', 'Partial', value, onChanged),
    ]);
  }
}

class _PSChip extends StatelessWidget {
  final String val, label, current;
  final void Function(String) onChanged;
  const _PSChip(this.val, this.label, this.current, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final active = val == current;
    final c = val == 'paid'
        ? AppColors.success
        : (val == 'partial' ? AppColors.warning : AppColors.textSecondary);
    return GestureDetector(
      onTap: () => onChanged(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? c : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? c : AppColors.textPrimary)),
      ),
    );
  }
}
