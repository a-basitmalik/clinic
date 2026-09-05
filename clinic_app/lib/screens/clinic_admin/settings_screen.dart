import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/clinic_admin_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/clinic_model.dart';
import '../../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _opening = TextEditingController();
  final _closing = TextEditingController();
  final _days = <String>{};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  static const weekdays = [
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
    _load();
  }

  Future<void> _load() async {
    final clinicId = context.read<AuthService>().currentUser?.clinicId;
    if (clinicId == null) {
      setState(() {
        _error = 'Clinic context is missing.';
        _loading = false;
      });
      return;
    }
    try {
      final clinic = await ClinicAdminService.getClinic(clinicId);
      _fill(clinic);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(ClinicModel c) {
    _name.text = c.clinicName;
    _owner.text = c.ownerName;
    _phone.text = c.phone ?? '';
    _address.text = c.address ?? '';
    _city.text = c.city;
    _opening.text = c.openingTime ?? '09:00';
    _closing.text = c.closingTime ?? '17:00';
    _days
      ..clear()
      ..addAll(c.workingDays);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_days.isEmpty) {
      setState(() => _error = 'Select at least one working day.');
      return;
    }
    if (!Validators.isTimeLater(_opening.text, _closing.text)) {
      setState(() => _error = 'Closing time must be after opening time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final clinicId = context.read<AuthService>().currentUser!.clinicId!;
      await ClinicAdminService.updateClinic(clinicId, {
        'clinic_name': _name.text.trim(),
        'owner_name': _owner.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'opening_time': _opening.text.trim(),
        'closing_time': _closing.text.trim(),
        'working_days': _days.toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clinic settings saved.')));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _owner,
      _phone,
      _address,
      _city,
      _opening,
      _closing
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Clinic Settings',
      currentRoute: AppRoutes.settings,
      body: _loading
          ? const LoadingWidget()
          : Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      CustomTextField(
                          label: 'Clinic Name',
                          controller: _name,
                          validator: Validators.required),
                      const SizedBox(height: 12),
                      CustomTextField(
                          label: 'Owner Name',
                          controller: _owner,
                          validator: Validators.required),
                      const SizedBox(height: 12),
                      CustomTextField(
                          label: 'Phone',
                          controller: _phone,
                          validator: Validators.requiredPhone),
                      const SizedBox(height: 12),
                      CustomTextField(
                          label: 'Address', controller: _address, maxLines: 2),
                      const SizedBox(height: 12),
                      CustomTextField(label: 'City', controller: _city),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: CustomTextField(
                                label: 'Opening Time',
                                controller: _opening,
                                validator: Validators.time)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: CustomTextField(
                                label: 'Closing Time',
                                controller: _closing,
                                validator: Validators.time)),
                      ]),
                      const SizedBox(height: 16),
                      const Text('Working Days',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Wrap(
                        spacing: 8,
                        children: weekdays
                            .map((day) => FilterChip(
                                  label: Text(day),
                                  selected: _days.contains(day),
                                  onSelected: (v) => setState(() =>
                                      v ? _days.add(day) : _days.remove(day)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                          label: 'Save Settings',
                          loading: _saving,
                          onPressed: _save),
                    ]),
              ),
            ),
    );
  }
}
