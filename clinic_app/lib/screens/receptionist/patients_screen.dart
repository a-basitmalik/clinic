import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/patient_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../models/api_response_model.dart';
import '../../models/patient_model.dart';
import '../../routes/app_routes.dart';
import 'patient_details_screen.dart';
import 'patient_registration_screen.dart';

class ReceptionistPatientsScreen extends StatefulWidget {
  const ReceptionistPatientsScreen({super.key});

  @override
  State<ReceptionistPatientsScreen> createState() => _ReceptionistPatientsScreenState();
}

class _ReceptionistPatientsScreenState extends State<ReceptionistPatientsScreen> {
  List<PatientModel> _patients = [];
  bool    _loading = true;
  String? _error;
  String  _search  = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      _patients = await PatientService.getPatients(search: search);
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openDetail(PatientModel p) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PatientDetailsScreen(patientId: p.id),
    )).then((_) => _load(search: _search.isEmpty ? null : _search));
  }

  void _openRegister() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const PatientRegistrationScreen(),
    )).then((_) => _load(search: _search.isEmpty ? null : _search));
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Patients',
      currentRoute: AppRoutes.recPatients,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SearchFilterBar(
          hint: 'Search by name, phone, CNIC, code…',
          onSearch: (q) {
            _search = q;
            _load(search: q.isEmpty ? null : q);
          },
          onAdd: _openRegister,
          addLabel: 'Register Patient',
        ),
        const SizedBox(height: 16),
        if (_loading)            const LoadingWidget()
        else if (_error != null) ErrorView(message: _error!, onRetry: _load)
        else _buildList(),
      ]),
    );
  }

  Widget _buildList() {
    if (_patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_alt_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('No patients found.', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openRegister,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Register New Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _PatientListTile(
        patient: _patients[i],
        onTap: () => _openDetail(_patients[i]),
      ),
    );
  }
}

class _PatientListTile extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;

  const _PatientListTile({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = patient;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(p.patientCode, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                if (p.phone != null) ...[
                  const SizedBox(width: 8),
                  Text(p.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ]),
              if (p.age != null || p.gender != null) ...[
                const SizedBox(height: 2),
                Text(
                  [if (p.age != null) '${p.age} yrs', if (p.gender != null) Helpers.capitalize(p.gender!)].join(' • '),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (p.bloodGroup != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.dangerSurface, borderRadius: BorderRadius.circular(4)),
                  child: Text(p.bloodGroup!, style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ]),
          ]),
        ),
      ),
    );
  }
}
