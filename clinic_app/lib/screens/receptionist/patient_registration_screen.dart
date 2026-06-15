import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/patient_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/api_response_model.dart';
import '../../models/patient_model.dart';

class PatientRegistrationScreen extends StatefulWidget {
  final PatientModel? patient; // non-null = edit mode
  const PatientRegistrationScreen({super.key, this.patient});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _phone;
  late final TextEditingController _cnic;
  late final TextEditingController _address;
  late final TextEditingController _emergency;

  String? _gender;
  String? _bloodGroup;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.patient != null;

  static const _genders = ['male', 'female', 'other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _name = TextEditingController(text: p?.name ?? '');
    _age = TextEditingController(text: p?.age?.toString() ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _cnic = TextEditingController(text: p?.cnic ?? '');
    _address = TextEditingController(text: p?.address ?? '');
    _emergency = TextEditingController(text: p?.emergencyContact ?? '');
    _gender = p?.gender;
    _bloodGroup = p?.bloodGroup;
  }

  @override
  void dispose() {
    for (final c in [_name, _age, _phone, _cnic, _address, _emergency])
      c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'age': int.tryParse(_age.text.trim()),
      'gender': _gender,
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'cnic': _cnic.text.trim().isEmpty ? null : _cnic.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'blood_group': _bloodGroup,
      'emergency_contact':
          _emergency.text.trim().isEmpty ? null : _emergency.text.trim(),
    };

    try {
      PatientModel result;
      if (_isEdit) {
        result = await PatientService.updatePatient(widget.patient!.id, body);
        if (mounted) {
          _snack('Patient updated.', success: true);
          Navigator.pop(context, result);
        }
      } else {
        result = await PatientService.createPatient(body);
        if (mounted) await _showSuccess(result);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSuccess(PatientModel p) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: AppColors.successSurface, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Patient Registered!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Patient has been registered successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Patient Code',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  SelectableText(p.patientCode,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, p);
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Clear form for next patient
              _name.clear();
              _age.clear();
              _phone.clear();
              _cnic.clear();
              _address.clear();
              _emergency.clear();
              setState(() {
                _gender = null;
                _bloodGroup = null;
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Register Another'),
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
          _isEdit ? 'Edit Patient' : 'Register Patient',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.dangerSurface,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(_error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],
            _Label('Basic Information'),
            CustomTextField(
              label: 'Full Name *',
              controller: _name,
              validator: Validators.required,
              prefixIcon: Icons.person_rounded,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: CustomTextField(
                label: 'Age',
                controller: _age,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake_rounded,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: CustomDropdown<String?>(
                label: 'Gender',
                value: _gender,
                items: _genders
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(_capitalize(g))))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              )),
            ]),
            const SizedBox(height: 12),
            CustomDropdown<String?>(
              label: 'Blood Group',
              value: _bloodGroup,
              items: _bloodGroups
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v),
            ),
            const SizedBox(height: 20),
            _Label('Contact Details'),
            CustomTextField(
              label: 'Phone Number',
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_rounded,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'CNIC (optional)',
              controller: _cnic,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.badge_rounded,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Address',
              controller: _address,
              maxLines: 2,
              prefixIcon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Emergency Contact',
              controller: _emergency,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.emergency_rounded,
            ),
            const SizedBox(height: 28),
            CustomButton(
              label: _isEdit ? 'Update Patient' : 'Register Patient',
              icon: _isEdit ? Icons.check_rounded : Icons.person_add_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ]),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
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
