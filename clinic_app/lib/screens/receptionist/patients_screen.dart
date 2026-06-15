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
  State<ReceptionistPatientsScreen> createState() =>
      _ReceptionistPatientsScreenState();
}

class _ReceptionistPatientsScreenState
    extends State<ReceptionistPatientsScreen> {
  List<PatientModel> _patients = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _patients = await PatientService.getPatients(search: search);
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  void _openDetail(PatientModel p) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientDetailsScreen(patientId: p.id),
        )).then((_) => _load(search: _search.isEmpty ? null : _search));
  }

  void _openRegister() {
    Navigator.push(
        context,
        MaterialPageRoute(
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
        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
          _buildList(),
      ]),
    );
  }

  Widget _buildList() {
    if (_patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: .16),
                    AppColors.primaryLight.withValues(alpha: .07),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: .22)),
              ),
              child: const Icon(Icons.people_alt_rounded,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No patients found.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _openRegister,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: .32),
                        blurRadius: 14,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_add_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Register New Patient',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .88),
              Colors.white.withValues(alpha: .65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: .15)),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: .05),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .22),
                  AppColors.primaryLight.withValues(alpha: .10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: .28)),
            ),
            child: Center(
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
          ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: .14),
                            AppColors.primaryLight.withValues(alpha: .06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: .22)),
                      ),
                      child: Text(p.patientCode,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (p.phone != null) ...[
                      const SizedBox(width: 8),
                      Text(p.phone!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ]),
                  if (p.age != null || p.gender != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (p.age != null) '${p.age} yrs',
                        if (p.gender != null) Helpers.capitalize(p.gender!)
                      ].join(' • '),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (p.bloodGroup != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.dangerSurface,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(p.bloodGroup!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ]),
        ]),
      ),
    );
  }
}
