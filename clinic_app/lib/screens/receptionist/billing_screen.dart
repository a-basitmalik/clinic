import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/patient_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/receipt_view.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../models/patient_model.dart';
import '../../routes/app_routes.dart';

class BillingScreen extends StatefulWidget {
  final AppointmentModel?
      appointment; // pre-filled if navigated from appointment
  const BillingScreen({super.key, this.appointment});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Patient search (if not pre-filled)
  PatientModel? _selectedPatient;
  final _patientSearchCtrl = TextEditingController();
  List<PatientModel> _patientResults = [];
  bool _searchingPatient = false;

  // Appointment search (optional)
  AppointmentModel? _selectedAppt;
  List<AppointmentModel> _apptResults = [];
  bool _loadingAppts = false;

  // Payment fields
  final _amountCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _paymentType = 'consultation';
  String _paymentMethod = 'cash';
  bool _saving = false;
  String? _error;

  bool get _hasPrefilledAppt => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    if (_hasPrefilledAppt) {
      _selectedAppt = widget.appointment;
      // Pre-fill amount from appointment fee
      final fee = widget.appointment!.fee;
      if (fee != null) _amountCtrl.text = fee.toStringAsFixed(0);
      final paid = widget.appointment!.paidAmount;
      if (paid != null && paid > 0) _paidCtrl.text = paid.toStringAsFixed(0);
      if (widget.appointment!.paymentMethod != null)
        _paymentMethod = widget.appointment!.paymentMethod!;
    }
  }

  @override
  void dispose() {
    for (final c in [_patientSearchCtrl, _amountCtrl, _paidCtrl, _notesCtrl])
      c.dispose();
    super.dispose();
  }

  Future<void> _searchPatients(String query) async {
    if (query.length < 2) {
      setState(() {
        _patientResults = [];
        _apptResults = [];
      });
      return;
    }
    setState(() => _searchingPatient = true);
    try {
      _patientResults =
          await PatientService.getPatients(search: query, perPage: 10);
    } catch (_) {}
    if (mounted) setState(() => _searchingPatient = false);
  }

  Future<void> _loadPatientAppointments(int patientId) async {
    setState(() => _loadingAppts = true);
    try {
      _apptResults = await AppointmentService.getAppointments(
        search: '$patientId',
      );
      // filter to unpaid/partial
      _apptResults =
          _apptResults.where((a) => a.paymentStatus != 'paid').toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingAppts = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final patientId = _selectedPatient?.id ?? _selectedAppt?.patientId;
    if (patientId == null) {
      setState(() => _error = 'Please select a patient or appointment.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final total = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final paid = double.tryParse(_paidCtrl.text.trim().isEmpty
            ? _amountCtrl.text.trim()
            : _paidCtrl.text.trim()) ??
        total;
    final status = paid >= total ? 'paid' : 'partial';

    final body = <String, dynamic>{
      'patient_id': patientId,
      'appointment_id': _selectedAppt?.id,
      'amount': total,
      'paid_amount': paid,
      'payment_method': _paymentMethod,
      'payment_type': _paymentType,
      'status': status,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      final payment = await PaymentService.createPayment(body);
      if (!mounted) return;
      await ReceiptView.show(context, payment);
      if (!_hasPrefilledAppt && mounted)
        Navigator.pop(context, payment);
      else if (mounted) Navigator.pop(context, payment);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If opened from AppointmentDetails, use Scaffold directly (not ResponsiveLayout)
    if (_hasPrefilledAppt) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('Collect Payment',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20), child: _buildForm()),
      );
    }
    return ResponsiveLayout(
      title: 'Billing',
      currentRoute: AppRoutes.billing,
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    final appt = _selectedAppt ?? widget.appointment;
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(10)),
            child: Text(_error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],

        // Appointment summary (if pre-filled)
        if (appt != null) ...[
          _Label('Appointment'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appt.patientName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Dr. ${appt.doctorName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              Text(
                  '${Helpers.formatDate(appt.appointmentDate)} • Token #${appt.tokenNumber}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 20),
        ] else ...[
          // Patient search
          _Label('Patient *'),
          if (_selectedPatient != null)
            _SelectedCard(
              name: _selectedPatient!.name,
              subtitle: _selectedPatient!.patientCode,
              onClear: () => setState(() {
                _selectedPatient = null;
                _selectedAppt = null;
                _patientSearchCtrl.clear();
              }),
            )
          else
            _SearchField(
              ctrl: _patientSearchCtrl,
              hint: 'Search patient by name, phone, code…',
              loading: _searchingPatient,
              onChanged: _searchPatients,
              results: _patientResults,
              onSelected: (p) {
                setState(() {
                  _selectedPatient = p;
                  _patientSearchCtrl.text = p.name;
                  _patientResults = [];
                });
                _loadPatientAppointments(p.id);
              },
            ),

          if (_selectedPatient != null && _apptResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Label('Link to Appointment (optional)'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppointmentModel?>(
                  value: _selectedAppt,
                  hint: const Text('Select appointment',
                      style: TextStyle(fontSize: 13)),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('No appointment',
                            style: TextStyle(fontSize: 13))),
                    ..._apptResults.map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                              'Token #${a.tokenNumber} • ${Helpers.formatDate(a.appointmentDate)}',
                              style: const TextStyle(fontSize: 13)),
                        )),
                  ],
                  onChanged: (a) {
                    setState(() {
                      _selectedAppt = a;
                      if (a?.fee != null)
                        _amountCtrl.text = a!.fee!.toStringAsFixed(0);
                    });
                  },
                ),
              ),
            ),
          ] else if (_loadingAppts)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator()),
          const SizedBox(height: 20),
        ],

        _Label('Payment Type'),
        _TypeRow(
            value: _paymentType,
            onChanged: (v) => setState(() => _paymentType = v)),
        const SizedBox(height: 16),

        _Label('Amounts'),
        Row(children: [
          Expanded(
              child: CustomTextField(
            label: 'Total Fee (PKR) *',
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            validator: Validators.positiveDecimal,
            prefixIcon: Icons.receipt_rounded,
          )),
          const SizedBox(width: 12),
          Expanded(
              child: CustomTextField(
            label: 'Paid Amount (PKR)',
            controller: _paidCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.payments_rounded,
          )),
        ]),
        const SizedBox(height: 12),

        _Label('Payment Method'),
        _MethodRow(
            value: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v)),
        const SizedBox(height: 12),

        CustomTextField(
          label: 'Notes (optional)',
          controller: _notesCtrl,
          maxLines: 2,
          prefixIcon: Icons.note_rounded,
        ),
        const SizedBox(height: 28),
        CustomButton(
          label: 'Record Payment & Print Receipt',
          icon: Icons.receipt_long_rounded,
          loading: _saving,
          onPressed: _save,
        ),
      ]),
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

class _SelectedCard extends StatelessWidget {
  final String name, subtitle;
  final VoidCallback onClear;
  const _SelectedCard(
      {required this.name, required this.subtitle, required this.onClear});

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
            child: Text(name[0].toUpperCase(),
                style: const TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w700))),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ])),
        IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: onClear),
      ]),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool loading;
  final void Function(String) onChanged;
  final List<PatientModel> results;
  final void Function(PatientModel) onSelected;

  const _SearchField(
      {required this.ctrl,
      required this.hint,
      required this.loading,
      required this.onChanged,
      required this.results,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        controller: ctrl,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppColors.textSecondary),
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
              ]),
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
                            fontWeight: FontWeight.w700))),
                title: Text(p.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle:
                    Text(p.patientCode, style: const TextStyle(fontSize: 11)),
                onTap: () => onSelected(p),
              );
            },
          ),
        ),
    ]);
  }
}

class _TypeRow extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _TypeRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const types = [
      ('consultation', 'Consultation'),
      ('pharmacy', 'Pharmacy'),
      ('lab', 'Lab'),
      ('other', 'Other')
    ];
    return Wrap(
        spacing: 8,
        children: types.map((t) {
          final active = t.$1 == value;
          return GestureDetector(
            onTap: () => onChanged(t.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.border),
              ),
              child: Text(t.$2,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? Colors.white : AppColors.textPrimary)),
            ),
          );
        }).toList());
  }
}

class _MethodRow extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _MethodRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const methods = [
      ('cash', 'Cash'),
      ('card', 'Card'),
      ('easypaisa', 'EasyPaisa'),
      ('jazzcash', 'JazzCash'),
      ('bank', 'Bank')
    ];
    return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: methods.map((m) {
          final active = m.$1 == value;
          return GestureDetector(
            onTap: () => onChanged(m.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: active ? AppColors.accent : AppColors.border),
              ),
              child: Text(m.$2,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? Colors.white : AppColors.textPrimary)),
            ),
          );
        }).toList());
  }
}
