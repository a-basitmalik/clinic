import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/super_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_table.dart';
import '../../core/widgets/data_card_list.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/clinic_model.dart';
import '../../routes/app_routes.dart';
import 'clinic_detail_screen.dart';

class AllClinicsScreen extends StatefulWidget {
  const AllClinicsScreen({super.key});

  @override
  State<AllClinicsScreen> createState() => _AllClinicsScreenState();
}

class _AllClinicsScreenState extends State<AllClinicsScreen> {
  List<ClinicModel> _all      = [];
  List<ClinicModel> _filtered = [];
  bool    _loading = true;
  String? _error;
  String  _search = '';
  String? _statusFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, String>{};
      if (_statusFilter != null) params['status'] = _statusFilter!;
      _all = await SuperAdminService.getAllClinics(queryParams: params);
      if (mounted) { _applyFilter(); setState(() => _loading = false); }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_all)
        : _all.where((c) =>
            c.clinicName.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q) ||
            c.ownerName.toLowerCase().contains(q)).toList();
  }

  void _openDetail(ClinicModel clinic) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClinicDetailScreen(clinicId: clinic.id)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.clinics,
      currentRoute: AppRoutes.clinics,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar(
            hint: 'Search by name, city, owner…',
            onSearch: (q) => setState(() { _search = q; _applyFilter(); }),
            filters: [_StatusFilter(value: _statusFilter, onChanged: (v) { setState(() => _statusFilter = v); _load(); })],
          ),
          const SizedBox(height: 16),
          if (_loading)       const LoadingWidget()
          else if (_error != null) ErrorView(message: _error!, onRetry: _load)
          else _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (ResponsiveLayout.isMobile(context)) {
      return DataCardList<ClinicModel>(
        items: _filtered,
        emptyMessage: 'No clinics found.',
        builder: (c) => InfoCard(
          onTap: () => _openDetail(c),
          child: _ClinicCardContent(clinic: c),
        ),
      );
    }
    return AppTable<ClinicModel>(
      rows: _filtered,
      emptyMessage: 'No clinics found.',
      columns: [
        AppTableColumn(header: 'Clinic Name', cell: (c) => Text(c.clinicName, style: const TextStyle(fontWeight: FontWeight.w500))),
        AppTableColumn(header: 'Owner',       cell: (c) => Text(c.ownerName)),
        AppTableColumn(header: 'City',        cell: (c) => Text(c.city)),
        AppTableColumn(header: 'Type',        cell: (c) => Text(c.clinicType == 'single_doctor' ? 'Single' : 'Multi')),
        AppTableColumn(header: 'Doctors',     cell: (c) => Text('${c.numberOfDoctors ?? 0}')),
        AppTableColumn(header: 'Status',      cell: (c) => StatusBadge(c.status)),
        AppTableColumn(header: 'Registered',  cell: (c) => Text(Helpers.formatDate(c.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        AppTableColumn(header: 'Actions',     cell: (c) => IconButton(
          icon: const Icon(Icons.visibility_rounded, size: 18, color: AppColors.primary),
          tooltip: 'View Details',
          onPressed: () => _openDetail(c),
        )),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  const _StatusFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text('All Status', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          items: const [
            DropdownMenuItem(value: null,         child: Text('All Status')),
            DropdownMenuItem(value: 'pending',    child: Text('Pending')),
            DropdownMenuItem(value: 'approved',   child: Text('Approved')),
            DropdownMenuItem(value: 'suspended',  child: Text('Suspended')),
          ],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          icon: const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ClinicCardContent extends StatelessWidget {
  final ClinicModel clinic;
  const _ClinicCardContent({required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(clinic.clinicName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(clinic.ownerName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${clinic.city} • ${clinic.clinicType == 'single_doctor' ? 'Single' : 'Multi'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(clinic.status),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ],
    );
  }
}
