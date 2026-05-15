import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/clinic_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_table.dart';
import '../../core/widgets/data_card_list.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../models/api_response_model.dart';
import '../../models/patient_model.dart';
import '../../routes/app_routes.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<PatientModel> _patients = [];
  bool _loading = true;
  String? _error;

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
      _patients = await ClinicAdminService.getPatients(search: search);
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.patients,
      currentRoute: AppRoutes.patients,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar(
            hint: 'Search by name, phone, CNIC…',
            onSearch: (q) {
              _load(search: q.isEmpty ? null : q);
            },
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LoadingWidget()
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (ResponsiveLayout.isMobile(context)) {
      return DataCardList<PatientModel>(
        items: _patients,
        emptyMessage: 'No patients found.',
        builder: (p) => InfoCard(child: _PatientCardContent(patient: p)),
      );
    }
    return AppTable<PatientModel>(
      rows: _patients,
      emptyMessage: 'No patients found.',
      columns: [
        AppTableColumn(
            header: 'Code',
            cell: (p) => Text(p.patientCode,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary))),
        AppTableColumn(
            header: 'Name',
            cell: (p) => Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        AppTableColumn(
            header: 'Age', cell: (p) => Text(p.age != null ? '${p.age}' : '—')),
        AppTableColumn(
            header: 'Gender',
            cell: (p) =>
                Text(p.gender != null ? Helpers.capitalize(p.gender!) : '—')),
        AppTableColumn(header: 'Phone', cell: (p) => Text(p.phone ?? '—')),
        AppTableColumn(header: 'Blood', cell: (p) => Text(p.bloodGroup ?? '—')),
        AppTableColumn(
            header: 'Registered',
            cell: (p) => Text(Helpers.formatDate(p.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary))),
      ],
    );
  }
}

class _PatientCardContent extends StatelessWidget {
  final PatientModel patient;
  const _PatientCardContent({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(patient.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(patient.patientCode,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (patient.phone != null)
          Text(patient.phone!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (patient.age != null)
          Text('${patient.age} yrs',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        if (patient.gender != null)
          Text(Helpers.capitalize(patient.gender!),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        if (patient.bloodGroup != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(4)),
            child: Text(patient.bloodGroup!,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600)),
          ),
      ]),
    ]);
  }
}
