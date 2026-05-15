import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/clinic_registration_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_checkbox.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/review_card.dart';
import '../../core/widgets/step_indicator.dart';
import '../../models/api_response_model.dart';
import '../../models/clinic_registration_model.dart';
import '../../models/doctor_registration_model.dart';
import '../../routes/app_routes.dart';

// ── Per-doctor controller bundle ──────────────────────────────────────────────

class _DoctorCtrls {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final department = TextEditingController();
  final specialization = TextEditingController();
  final qualification = TextEditingController();
  final experience = TextEditingController();
  final license = TextEditingController();
  final fee = TextEditingController();
  final startTime = TextEditingController(text: '09:00');
  final endTime = TextEditingController(text: '17:00');
  List<String> availableDays = [];

  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    department.dispose();
    specialization.dispose();
    qualification.dispose();
    experience.dispose();
    license.dispose();
    fee.dispose();
    startTime.dispose();
    endTime.dispose();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ClinicRegisterScreen extends StatefulWidget {
  const ClinicRegisterScreen({super.key});

  @override
  State<ClinicRegisterScreen> createState() => _ClinicRegisterScreenState();
}

class _ClinicRegisterScreenState extends State<ClinicRegisterScreen> {
  // ── Step state ──────────────────────────────────────────────────────────────
  int _step = 0;
  static const _stepLabels = ['Clinic', 'Type', 'Doctors', 'Staff', 'Review'];

  // ── Step 1 — Clinic Information ─────────────────────────────────────────────
  final _clinicName = TextEditingController();
  final _ownerName = TextEditingController();
  final _clinicEmail = TextEditingController();
  final _clinicPhone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _openingTime = TextEditingController(text: '09:00');
  final _closingTime = TextEditingController(text: '17:00');
  List<String> _workingDays = [];
  String? _workingDaysError;
  final _step1Key = GlobalKey<FormState>();

  // ── Step 2 — Clinic Type ────────────────────────────────────────────────────
  String _clinicType = 'single_doctor';
  int _numDoctors = 1;
  bool _hasPharmacy = false;
  bool _hasReceptionist = false;

  // ── Step 3 — Doctors ────────────────────────────────────────────────────────
  List<_DoctorCtrls> _doctorCtrls = [];
  List<String?> _doctorDaysErrors = [];
  final _step3Key = GlobalKey<FormState>();

  // ── Step 4 — Staff ──────────────────────────────────────────────────────────
  final _recepName = TextEditingController();
  final _recepEmail = TextEditingController();
  final _recepPhone = TextEditingController();
  final _pharmName = TextEditingController();
  final _pharmEmail = TextEditingController();
  final _pharmPhone = TextEditingController();
  final _step4Key = GlobalKey<FormState>();

  // ── Submit state ────────────────────────────────────────────────────────────
  bool _submitting = false;
  String? _submitError;
  Map<String, dynamic>? _result;
  bool _submitted = false;

  // ── Init / Dispose ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _doctorCtrls = [_DoctorCtrls()];
    _doctorDaysErrors = [null];
  }

  @override
  void dispose() {
    _clinicName.dispose();
    _ownerName.dispose();
    _clinicEmail.dispose();
    _clinicPhone.dispose();
    _address.dispose();
    _city.dispose();
    _openingTime.dispose();
    _closingTime.dispose();
    for (final d in _doctorCtrls) d.dispose();
    _recepName.dispose();
    _recepEmail.dispose();
    _recepPhone.dispose();
    _pharmName.dispose();
    _pharmEmail.dispose();
    _pharmPhone.dispose();
    super.dispose();
  }

  // ── Doctor count management ─────────────────────────────────────────────────

  void _setClinicType(String type) {
    setState(() {
      _clinicType = type;
      final target =
          type == 'single_doctor' ? 1 : (_numDoctors < 2 ? 2 : _numDoctors);
      _adjustDoctorCount(target);
    });
  }

  void _updateDoctorCount(int count) {
    setState(() => _adjustDoctorCount(count));
  }

  void _adjustDoctorCount(int target) {
    while (_doctorCtrls.length < target) {
      _doctorCtrls.add(_DoctorCtrls());
      _doctorDaysErrors.add(null);
    }
    while (_doctorCtrls.length > target) {
      _doctorCtrls.removeLast().dispose();
      _doctorDaysErrors.removeLast();
    }
    _numDoctors = target;
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        final formOk = _step1Key.currentState?.validate() ?? false;
        final daysOk = _workingDays.isNotEmpty;
        setState(() {
          _workingDaysError =
              daysOk ? null : 'Select at least one working day.';
        });
        if (!formOk || !daysOk) return false;
        if (!Validators.isTimeLater(_openingTime.text, _closingTime.text)) {
          _snack('Closing time must be after opening time.');
          return false;
        }
        return true;

      case 1:
        return true;

      case 2:
        final formOk = _step3Key.currentState?.validate() ?? false;
        bool daysOk = true;
        for (int i = 0; i < _doctorCtrls.length; i++) {
          final ok = _doctorCtrls[i].availableDays.isNotEmpty;
          _doctorDaysErrors[i] =
              ok ? null : 'Select at least one available day.';
          if (!ok) daysOk = false;
          if (ok &&
              !Validators.isTimeLater(_doctorCtrls[i].startTime.text,
                  _doctorCtrls[i].endTime.text)) {
            setState(() {});
            _snack('Doctor ${i + 1}: End time must be after start time.');
            return false;
          }
        }
        setState(() {});
        return formOk && daysOk;

      case 3:
        if (!_hasReceptionist && !_hasPharmacy) return true;
        return _step4Key.currentState?.validate() ?? false;

      default:
        return true;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _next() {
    if (_validateCurrentStep()) setState(() => _step++);
  }

  void _prev() => setState(() => _step--);

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final model = ClinicRegistrationModel(
        clinicName: _clinicName.text.trim(),
        ownerName: _ownerName.text.trim(),
        email: _clinicEmail.text.trim(),
        phone: _clinicPhone.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        openingTime: _openingTime.text.trim(),
        closingTime: _closingTime.text.trim(),
        workingDays: List.from(_workingDays),
        clinicType: _clinicType,
        numberOfDoctors: _numDoctors,
        hasPharmacy: _hasPharmacy,
        hasReceptionist: _hasReceptionist,
        doctors: _doctorCtrls
            .map((d) => DoctorRegistrationModel(
                  name: d.name.text.trim(),
                  email: d.email.text.trim(),
                  phone: d.phone.text.trim(),
                  department: d.department.text.trim(),
                  specialization: d.specialization.text.trim(),
                  qualification: d.qualification.text.trim(),
                  experience: int.tryParse(d.experience.text.trim()) ?? 0,
                  licenseNumber: d.license.text.trim(),
                  consultationFee: double.tryParse(d.fee.text.trim()) ?? 0.0,
                  availableDays: List.from(d.availableDays),
                  availableStartTime: d.startTime.text.trim(),
                  availableEndTime: d.endTime.text.trim(),
                ))
            .toList(),
        receptionist: _hasReceptionist
            ? StaffMemberModel(
                name: _recepName.text.trim(),
                email: _recepEmail.text.trim(),
                phone: _recepPhone.text.trim(),
              )
            : null,
        pharmacy: _hasPharmacy
            ? StaffMemberModel(
                name: _pharmName.text.trim(),
                email: _pharmEmail.text.trim(),
                phone: _pharmPhone.text.trim(),
              )
            : null,
      );

      final res = await ClinicRegistrationService.register(model);
      if (mounted) {
        setState(() {
          _result = res.data;
          _submitted = true;
          _submitting = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _submitError = e.message;
          _submitting = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _submitError = e.toString();
          _submitting = false;
        });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          AppStrings.registerClinic,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_submitted)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: StepIndicator(
                  totalSteps: 5,
                  currentStep: _step,
                  labels: _stepLabels,
                ),
              ),
            Expanded(
              child: _submitted
                  ? _buildSuccess()
                  : IndexedStack(
                      index: _step,
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                        _buildStep3(),
                        _buildStep4(),
                        _buildReview(),
                      ],
                    ),
            ),
            if (!_submitted) _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  // ── Navigation buttons ───────────────────────────────────────────────────────

  Widget _buildNavButtons() {
    final isLast = _step == 4;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: CustomButton(
                label: 'Previous',
                variant: ButtonVariant.outlined,
                icon: Icons.arrow_back_rounded,
                onPressed: _prev,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: isLast
                ? CustomButton(
                    label: 'Submit Registration',
                    loading: _submitting,
                    icon: Icons.send_rounded,
                    onPressed: _submitting ? null : _submit,
                  )
                : CustomButton(
                    label: 'Next',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Clinic Information ────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader('Clinic Details', Icons.local_hospital_rounded),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Clinic Name *',
              hint: 'e.g. City Health Clinic',
              controller: _clinicName,
              prefixIcon: Icons.business_rounded,
              validator: (v) => Validators.required(v, 'Clinic name'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Owner Full Name *',
              controller: _ownerName,
              prefixIcon: Icons.person_rounded,
              validator: (v) => Validators.required(v, 'Owner name'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Clinic Email *',
              hint: 'clinic@example.com',
              controller: _clinicEmail,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Phone Number *',
              controller: _clinicPhone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.requiredPhone,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Address *',
              controller: _address,
              prefixIcon: Icons.location_on_outlined,
              validator: (v) => Validators.required(v, 'Address'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'City *',
              controller: _city,
              prefixIcon: Icons.location_city_rounded,
              validator: (v) => Validators.required(v, 'City'),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Working Hours', Icons.access_time_rounded),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimePickerField(
                    label: 'Opening Time *',
                    controller: _openingTime,
                    validator: Validators.time,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _TimePickerField(
                    label: 'Closing Time *',
                    controller: _closingTime,
                    validator: Validators.time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('Working Days *', Icons.calendar_month_rounded),
            const SizedBox(height: 12),
            DaysCheckboxGroup(
              selectedDays: _workingDays,
              errorText: _workingDaysError,
              onChanged: (days) => setState(() {
                _workingDays = days;
                if (days.isNotEmpty) _workingDaysError = null;
              }),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Clinic Type ───────────────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Clinic Type *', Icons.business_center_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TypeCard(
                  title: 'Single Doctor',
                  subtitle: 'One doctor, focused practice',
                  icon: Icons.person_rounded,
                  selected: _clinicType == 'single_doctor',
                  onTap: () => _setClinicType('single_doctor'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeCard(
                  title: 'Multi Doctor',
                  subtitle: 'Multiple doctors & departments',
                  icon: Icons.group_rounded,
                  selected: _clinicType == 'multi_doctor',
                  onTap: () => _setClinicType('multi_doctor'),
                ),
              ),
            ],
          ),
          if (_clinicType == 'multi_doctor') ...[
            const SizedBox(height: 24),
            _SectionHeader('Number of Doctors', Icons.people_rounded),
            const SizedBox(height: 8),
            const Text(
              'How many doctors will be registered?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CounterButton(
                  icon: Icons.remove_rounded,
                  enabled: _numDoctors > 2,
                  onTap: () => _updateDoctorCount(_numDoctors - 1),
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text(
                      '$_numDoctors',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'doctors',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                _CounterButton(
                  icon: Icons.add_rounded,
                  enabled: _numDoctors < 20,
                  onTap: () => _updateDoctorCount(_numDoctors + 1),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          _SectionHeader('Additional Staff', Icons.group_add_rounded),
          const SizedBox(height: 12),
          CustomCheckboxTile(
            label: 'Has Receptionist',
            subtitle: 'Appointment booking & patient registration',
            value: _hasReceptionist,
            onChanged: (v) => setState(() => _hasReceptionist = v),
          ),
          const SizedBox(height: 12),
          CustomCheckboxTile(
            label: 'Has Pharmacy',
            subtitle: 'Medication dispensing & inventory management',
            value: _hasPharmacy,
            onChanged: (v) => setState(() => _hasPharmacy = v),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Step 3: Doctor Information ────────────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < _doctorCtrls.length; i++) ...[
              if (_doctorCtrls.length > 1) ...[
                if (i > 0) const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Doctor ${i + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                _SectionHeader(
                    'Doctor Information', Icons.medical_services_rounded),
                const SizedBox(height: 16),
              ],
              _buildDoctorFields(i),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorFields(int i) {
    final d = _doctorCtrls[i];
    return Column(
      children: [
        CustomTextField(
          label: 'Full Name *',
          controller: d.name,
          prefixIcon: Icons.person_rounded,
          validator: (v) => Validators.required(v, 'Doctor name'),
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Email Address *',
          controller: d.email,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Phone Number *',
          controller: d.phone,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: Validators.requiredPhone,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Department *',
          hint: 'e.g. General, Cardiology',
          controller: d.department,
          prefixIcon: Icons.category_rounded,
          validator: (v) => Validators.required(v, 'Department'),
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Specialization *',
          controller: d.specialization,
          prefixIcon: Icons.health_and_safety_rounded,
          validator: (v) => Validators.required(v, 'Specialization'),
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'Qualification *',
          hint: 'e.g. MBBS, MD',
          controller: d.qualification,
          prefixIcon: Icons.school_rounded,
          validator: (v) => Validators.required(v, 'Qualification'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Experience (years) *',
                controller: d.experience,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.work_history_rounded,
                validator: (v) => Validators.positiveInt(v, 'Experience'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: CustomTextField(
                label: 'Consultation Fee *',
                controller: d.fee,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.payments_rounded,
                validator: (v) =>
                    Validators.positiveDecimal(v, 'Consultation fee'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: 'License Number *',
          controller: d.license,
          prefixIcon: Icons.badge_rounded,
          validator: (v) => Validators.required(v, 'License number'),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Days *',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            Text(
              '${d.availableDays.length} selected',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DaysCheckboxGroup(
          selectedDays: d.availableDays,
          errorText: _doctorDaysErrors.length > i ? _doctorDaysErrors[i] : null,
          onChanged: (days) => setState(() {
            d.availableDays = days;
            if (days.isNotEmpty && _doctorDaysErrors.length > i)
              _doctorDaysErrors[i] = null;
          }),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TimePickerField(
                label: 'Available From *',
                controller: d.startTime,
                validator: Validators.time,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _TimePickerField(
                label: 'Available Until *',
                controller: d.endTime,
                validator: Validators.time,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 4: Staff Setup ───────────────────────────────────────────────────────

  Widget _buildStep4() {
    if (!_hasReceptionist && !_hasPharmacy) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 36, color: AppColors.accent),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Staff Accounts Required',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'You did not select a receptionist or pharmacy. You can proceed to review.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step4Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasReceptionist) ...[
              _SectionHeader(
                  'Receptionist Account', Icons.support_agent_rounded),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Full Name *',
                controller: _recepName,
                prefixIcon: Icons.person_rounded,
                validator: (v) => Validators.required(v, 'Receptionist name'),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Email Address *',
                controller: _recepEmail,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Phone Number *',
                controller: _recepPhone,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.requiredPhone,
              ),
            ],
            if (_hasReceptionist && _hasPharmacy) const SizedBox(height: 28),
            if (_hasPharmacy) ...[
              _SectionHeader(
                  'Pharmacy User Account', Icons.local_pharmacy_rounded),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Full Name *',
                controller: _pharmName,
                prefixIcon: Icons.person_rounded,
                validator: (v) => Validators.required(v, 'Pharmacy user name'),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Email Address *',
                controller: _pharmEmail,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Phone Number *',
                controller: _pharmPhone,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.requiredPhone,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Step 5: Review ────────────────────────────────────────────────────────────

  Widget _buildReview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.info, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Review your details before submitting. You can go back to edit any section.',
                    style: TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ReviewCard(
            title: 'Clinic Information',
            icon: Icons.local_hospital_rounded,
            rows: [
              ReviewRow('Clinic Name', _clinicName.text),
              ReviewRow('Owner', _ownerName.text),
              ReviewRow('Email', _clinicEmail.text),
              ReviewRow('Phone', _clinicPhone.text),
              ReviewRow('Address', _address.text),
              ReviewRow('City', _city.text),
              ReviewRow('Opening', _openingTime.text),
              ReviewRow('Closing', _closingTime.text),
              ReviewRow('Working Days',
                  _workingDays.map((d) => d.substring(0, 3)).join(', ')),
            ],
          ),
          ReviewCard(
            title: 'Clinic Type',
            icon: Icons.business_center_rounded,
            rows: [
              ReviewRow(
                  'Type',
                  _clinicType == 'single_doctor'
                      ? 'Single Doctor'
                      : 'Multi Doctor'),
              ReviewRow('Doctors', '$_numDoctors'),
              ReviewRow('Receptionist', _hasReceptionist ? 'Yes' : 'No'),
              ReviewRow('Pharmacy', _hasPharmacy ? 'Yes' : 'No'),
            ],
          ),
          for (int i = 0; i < _doctorCtrls.length; i++)
            ReviewCard(
              title: _doctorCtrls.length > 1 ? 'Doctor ${i + 1}' : 'Doctor',
              icon: Icons.medical_services_rounded,
              accentColor: AppColors.accent,
              rows: [
                ReviewRow('Name', _doctorCtrls[i].name.text),
                ReviewRow('Email', _doctorCtrls[i].email.text),
                ReviewRow('Phone', _doctorCtrls[i].phone.text),
                ReviewRow('Department', _doctorCtrls[i].department.text),
                ReviewRow(
                    'Specialization', _doctorCtrls[i].specialization.text),
                ReviewRow('Qualification', _doctorCtrls[i].qualification.text),
                ReviewRow(
                    'Experience', '${_doctorCtrls[i].experience.text} years'),
                ReviewRow('License No.', _doctorCtrls[i].license.text),
                ReviewRow('Fee', 'PKR ${_doctorCtrls[i].fee.text}'),
                ReviewRow(
                    'Available Days',
                    _doctorCtrls[i]
                        .availableDays
                        .map((d) => d.substring(0, 3))
                        .join(', ')),
                ReviewRow('Hours',
                    '${_doctorCtrls[i].startTime.text} – ${_doctorCtrls[i].endTime.text}'),
              ],
            ),
          if (_hasReceptionist)
            ReviewCard(
              title: 'Receptionist',
              icon: Icons.support_agent_rounded,
              accentColor: AppColors.warning,
              rows: [
                ReviewRow('Name', _recepName.text),
                ReviewRow('Email', _recepEmail.text),
                ReviewRow('Phone', _recepPhone.text),
              ],
            ),
          if (_hasPharmacy)
            ReviewCard(
              title: 'Pharmacy User',
              icon: Icons.local_pharmacy_rounded,
              accentColor: AppColors.info,
              rows: [
                ReviewRow('Name', _pharmName.text),
                ReviewRow('Email', _pharmEmail.text),
                ReviewRow('Phone', _pharmPhone.text),
              ],
            ),
          if (_submitError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_submitError!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Success screen ────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 72),
          const SizedBox(height: 16),
          const Text(
            'Registration Submitted!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your clinic registration is pending approval by a Super Admin. '
            'You will be notified once it is approved.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (_result != null) _buildCredentials(_result!),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Back to Login',
            icon: Icons.login_rounded,
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.login, (_) => false),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCredentials(Map<String, dynamic> data) {
    final cards = <Widget>[];

    void addCard(String title, IconData icon, Map? account) {
      if (account == null) return;
      cards.add(_CredentialCard(
        title: title,
        icon: icon,
        name: account['name']?.toString() ?? '',
        email: account['email']?.toString() ?? '',
        password: account['temp_password']?.toString() ?? '',
      ));
    }

    addCard('Clinic Admin', Icons.admin_panel_settings_rounded,
        data['admin'] as Map?);

    final doctors = data['doctors'] as List?;
    if (doctors != null) {
      for (int i = 0; i < doctors.length; i++) {
        final d = doctors[i] as Map?;
        if (d == null) continue;
        addCard(
          doctors.length > 1 ? 'Doctor ${i + 1}: ${d['name'] ?? ''}' : 'Doctor',
          Icons.medical_services_rounded,
          d,
        );
      }
    }

    addCard('Receptionist', Icons.support_agent_rounded,
        data['receptionist'] as Map?);
    addCard('Pharmacy User', Icons.local_pharmacy_rounded,
        data['pharmacy'] as Map?);

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Created Accounts',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Save these credentials now. Passwords are shown only once '
                  'and must be changed on first login.',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...cards,
      ],
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _TimePickerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _TimePickerField({
    required this.label,
    required this.controller,
    this.validator,
  });

  Future<void> _pick(BuildContext context) async {
    TimeOfDay initial = TimeOfDay.now();
    final text = controller.text;
    if (text.contains(':')) {
      final parts = text.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      controller: controller,
      prefixIcon: Icons.access_time_rounded,
      readOnly: true,
      onTap: () => _pick(context),
      validator: validator,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 28,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _CounterButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySurface : AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String name;
  final String email;
  final String password;
  const _CredentialCard({
    required this.title,
    required this.icon,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          if (name.isNotEmpty) _Row('Name', name, selectable: false),
          _Row('Email', email),
          _Row('Temp Password', password, mono: true),
          const SizedBox(height: 4),
          const Text(
            '⚠ Must change password on first login.',
            style: TextStyle(fontSize: 11, color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _Row(String label, String value,
      {bool mono = false, bool selectable = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: selectable
                ? SelectableText(
                    value.isEmpty ? '—' : value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: mono ? 'monospace' : null,
                      letterSpacing: mono ? 0.5 : null,
                    ),
                  )
                : Text(
                    value.isEmpty ? '—' : value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                  ),
          ),
        ],
      ),
    );
  }
}
