import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_table.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/data_card_list.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/doctor_model.dart';
import '../../routes/app_routes.dart';
import 'doctor_form_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<DoctorModel> _all = [];
  List<DoctorModel> _filtered = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _all = await DoctorService.getDoctors();
      if (mounted) {
        _applyFilter();
        setState(() => _loading = false);
      }
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

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_all)
        : _all
            .where((d) =>
                d.name.toLowerCase().contains(q) ||
                (d.specialization?.toLowerCase().contains(q) ?? false) ||
                (d.departmentName?.toLowerCase().contains(q) ?? false))
            .toList();
  }

  void _openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DoctorFormScreen()),
    ).then((_) => _load());
  }

  void _openEdit(DoctorModel doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DoctorFormScreen(doctor: doctor)),
    ).then((_) => _load());
  }

  Future<void> _deactivate(DoctorModel doctor) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Deactivate Doctor',
      message:
          'Deactivate Dr. ${doctor.name}? They will no longer be able to log in.',
      confirmLabel: 'Deactivate',
    );
    if (!ok || !mounted) return;
    try {
      await DoctorService.deactivateDoctor(doctor.id);
      _snack('Dr. ${doctor.name} deactivated.');
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
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
    return ResponsiveLayout(
      title: AppStrings.doctors,
      currentRoute: AppRoutes.doctors,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar(
            hint: 'Search by name, specialization, department…',
            onSearch: (q) => setState(() {
              _search = q;
              _applyFilter();
            }),
            onAdd: _openAdd,
            addLabel: 'Add Doctor',
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
      return DataCardList<DoctorModel>(
        items: _filtered,
        emptyMessage: 'No doctors found.',
        builder: (d) => InfoCard(
          onTap: () => _openEdit(d),
          child:
              _DoctorCardContent(doctor: d, onDeactivate: () => _deactivate(d)),
        ),
      );
    }
    return AppTable<DoctorModel>(
      rows: _filtered,
      emptyMessage: 'No doctors found.',
      columns: [
        AppTableColumn(
            header: 'Name',
            cell: (d) => Text(d.name,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        AppTableColumn(
            header: 'Department', cell: (d) => Text(d.departmentName ?? '—')),
        AppTableColumn(
            header: 'Specialization',
            cell: (d) => Text(d.specialization ?? '—')),
        AppTableColumn(
            header: 'Fee',
            cell: (d) => Text(Helpers.formatCurrency(d.consultationFee))),
        AppTableColumn(header: 'Status', cell: (d) => StatusBadge(d.status)),
        AppTableColumn(
            header: 'Actions',
            cell: (d) => Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        size: 18, color: AppColors.primary),
                    tooltip: 'Edit',
                    onPressed: () => _openEdit(d),
                  ),
                  if (d.isActive)
                    IconButton(
                      icon: const Icon(Icons.block_rounded,
                          size: 18, color: AppColors.danger),
                      tooltip: 'Deactivate',
                      onPressed: () => _deactivate(d),
                    ),
                ])),
      ],
    );
  }
}

class _DoctorCardContent extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onDeactivate;
  const _DoctorCardContent({required this.doctor, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: .18),
              AppColors.primaryLight.withValues(alpha: .08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: .25)),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: .10),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: const Icon(Icons.person_rounded,
            color: AppColors.primary, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(doctor.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        if (doctor.departmentName != null)
          Text(doctor.departmentName!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        if (doctor.specialization != null)
          Text(doctor.specialization!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        StatusBadge(doctor.status),
        const SizedBox(height: 4),
        if (doctor.isActive)
          GestureDetector(
            onTap: onDeactivate,
            child: const Icon(Icons.block_rounded,
                size: 16, color: AppColors.danger),
          )
        else
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
      ]),
    ]);
  }
}
