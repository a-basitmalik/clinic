import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/patient_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/api_response_model.dart';
import '../../models/patient_model.dart';
import 'book_appointment_screen.dart';
import 'patient_history_screen.dart';
import 'patient_registration_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final int patientId;
  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  PatientModel? _patient;
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _patient = await PatientService.getPatient(widget.patientId);
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openEdit() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PatientRegistrationScreen(patient: _patient),
    )).then((updated) {
      if (updated is PatientModel) setState(() => _patient = updated);
    });
  }

  void _openBookAppointment() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BookAppointmentScreen(patient: _patient),
    ));
  }

  void _openHistory() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PatientHistoryScreen(patientId: widget.patientId),
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
          _patient?.name ?? 'Patient Details',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (_patient != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              tooltip: 'Edit',
              onPressed: _openEdit,
            ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = _patient!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(6)),
                child: Text(p.patientCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              if (p.age != null || p.gender != null) ...[
                const SizedBox(height: 6),
                Text(
                  [if (p.age != null) '${p.age} yrs', if (p.gender != null) Helpers.capitalize(p.gender!)].join(' • '),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ])),
            if (p.bloodGroup != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.dangerSurface, borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  const Icon(Icons.water_drop_rounded, color: AppColors.danger, size: 16),
                  const SizedBox(height: 2),
                  Text(p.bloodGroup!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(children: [
          Expanded(child: CustomButton(
            label: 'Book Appointment',
            icon: Icons.calendar_month_rounded,
            onPressed: _openBookAppointment,
          )),
          const SizedBox(width: 12),
          Expanded(child: CustomButton(
            label: 'View History',
            icon: Icons.history_rounded,
            variant: ButtonVariant.secondary,
            onPressed: _openHistory,
          )),
        ]),
        const SizedBox(height: 20),

        // Contact info
        _Section('Contact Information', [
          _InfoRow(Icons.phone_rounded,     'Phone',           p.phone ?? '—'),
          _InfoRow(Icons.badge_rounded,     'CNIC',            p.cnic ?? '—'),
          _InfoRow(Icons.location_on_rounded, 'Address',       p.address ?? '—'),
          _InfoRow(Icons.emergency_rounded, 'Emergency',       p.emergencyContact ?? '—'),
        ]),
        const SizedBox(height: 16),
        _Section('Registration', [
          _InfoRow(Icons.calendar_today_rounded, 'Registered', Helpers.formatDate(p.createdAt)),
        ]),
      ]),
    );
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
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        Padding(padding: const EdgeInsets.all(16), child: Column(children: rows)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
