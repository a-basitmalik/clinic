import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/department_service.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/api_response_model.dart';
import '../../models/department_model.dart';
import '../../models/doctor_model.dart';

class DoctorFormScreen extends StatefulWidget {
  final DoctorModel? doctor;
  const DoctorFormScreen({super.key, this.doctor});

  @override
  State<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends State<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _spec;
  late final TextEditingController _qual;
  late final TextEditingController _exp;
  late final TextEditingController _license;
  late final TextEditingController _fee;
  late final TextEditingController _startTime;
  late final TextEditingController _endTime;

  int? _departmentId;
  List<String> _selectedDays = [];
  String? _daysError;

  List<DepartmentModel> _departments = [];
  bool _loadingDepts = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.doctor != null;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _name = TextEditingController(text: d?.name ?? '');
    _email = TextEditingController(text: d?.email ?? '');
    _phone = TextEditingController(text: d?.phone ?? '');
    _spec = TextEditingController(text: d?.specialization ?? '');
    _qual = TextEditingController(text: d?.qualification ?? '');
    _exp = TextEditingController(text: d?.experience?.toString() ?? '');
    _license = TextEditingController(text: d?.licenseNumber ?? '');
    _fee = TextEditingController(
        text: d?.consultationFee?.toStringAsFixed(0) ?? '');
    _startTime = TextEditingController(text: d?.availableStartTime ?? '');
    _endTime = TextEditingController(text: d?.availableEndTime ?? '');
    _departmentId = d?.departmentId;
    _selectedDays = List.from(d?.availableDays ?? []);
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      _departments = await DepartmentService.getDepartments();
    } catch (_) {}
    if (mounted) setState(() => _loadingDepts = false);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _spec,
      _qual,
      _exp,
      _license,
      _fee,
      _startTime,
      _endTime
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final init = (parts.length == 2)
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDays.isEmpty) {
      setState(() => _daysError = 'Select at least one working day');
      return;
    }
    setState(() {
      _daysError = null;
      _saving = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'department_id': _departmentId,
      'specialization': _spec.text.trim().isEmpty ? null : _spec.text.trim(),
      'qualification': _qual.text.trim().isEmpty ? null : _qual.text.trim(),
      'experience': int.tryParse(_exp.text.trim()),
      'license_number':
          _license.text.trim().isEmpty ? null : _license.text.trim(),
      'consultation_fee': double.tryParse(_fee.text.trim()),
      'available_days': _selectedDays,
      'available_start_time':
          _startTime.text.trim().isEmpty ? null : _startTime.text.trim(),
      'available_end_time':
          _endTime.text.trim().isEmpty ? null : _endTime.text.trim(),
    };

    try {
      DoctorModel result;
      if (_isEdit) {
        result = await DoctorService.updateDoctor(widget.doctor!.id, body);
      } else {
        result = await DoctorService.createDoctor(body);
      }
      if (!mounted) return;
      if (!_isEdit && result.tempPassword != null) {
        await _showTempPassword(result);
      } else {
        _snack(_isEdit ? 'Doctor updated.' : 'Doctor added.', success: true);
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showTempPassword(DoctorModel result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Doctor Created'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Share these credentials with the doctor. The password is shown only once.',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              _CredRow('Name', result.name),
              _CredRow('Email', result.email),
              _CredRow('Password', result.tempPassword ?? '—'),
            ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
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
        title: Text(
          _isEdit ? 'Edit Doctor' : 'Add Doctor',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loadingDepts
          ? const Center(child: CircularProgressIndicator())
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _sectionLabel('Basic Information'),
                      CustomTextField(
                          label: 'Full Name *',
                          controller: _name,
                          validator: Validators.required),
                      const SizedBox(height: 12),
                      CustomTextField(
                          label: 'Email *',
                          controller: _email,
                          validator: Validators.email,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: _isEdit),
                      const SizedBox(height: 12),
                      CustomTextField(
                          label: 'Phone',
                          controller: _phone,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 20),
                      _sectionLabel('Professional Details'),
                      if (_departments.isNotEmpty) ...[
                        CustomDropdown<int?>(
                          label: 'Department',
                          value: _departmentId,
                          items: _departments
                              .map((d) => DropdownMenuItem(
                                  value: d.id, child: Text(d.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _departmentId = v),
                        ),
                        const SizedBox(height: 12),
                      ],
                      CustomTextField(
                          label: 'Specialization', controller: _spec),
                      const SizedBox(height: 12),
                      CustomTextField(
                          label: 'Qualification', controller: _qual),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: CustomTextField(
                                label: 'Experience (years)',
                                controller: _exp,
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: CustomTextField(
                                label: 'Consultation Fee (PKR)',
                                controller: _fee,
                                keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 12),
                      CustomTextField(
                          label: 'License Number', controller: _license),
                      const SizedBox(height: 20),
                      _sectionLabel('Availability'),
                      Row(children: [
                        Expanded(
                            child: CustomTextField(
                          label: 'Start Time',
                          controller: _startTime,
                          readOnly: true,
                          onTap: () => _pickTime(_startTime),
                          prefixIcon: Icons.access_time_rounded,
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: CustomTextField(
                          label: 'End Time',
                          controller: _endTime,
                          readOnly: true,
                          onTap: () => _pickTime(_endTime),
                          prefixIcon: Icons.access_time_rounded,
                        )),
                      ]),
                      const SizedBox(height: 12),
                      const Text('Working Days',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _days.map((day) {
                          final sel = _selectedDays.contains(day);
                          return FilterChip(
                            label: Text(day.substring(0, 3),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight:
                                      sel ? FontWeight.w600 : FontWeight.w400,
                                )),
                            selected: sel,
                            onSelected: (v) => setState(() {
                              if (v)
                                _selectedDays.add(day);
                              else
                                _selectedDays.remove(day);
                              _daysError = null;
                            }),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                                color:
                                    sel ? AppColors.primary : AppColors.border),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      if (_daysError != null) ...[
                        const SizedBox(height: 6),
                        Text(_daysError!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 12)),
                      ],
                      const SizedBox(height: 28),
                      CustomButton(
                        label: _isEdit ? 'Update Doctor' : 'Add Doctor',
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ]),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );
}

class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  const _CredRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 70,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary))),
        Expanded(
            child: SelectableText(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
