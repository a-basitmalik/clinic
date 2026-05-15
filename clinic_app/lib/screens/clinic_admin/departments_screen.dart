import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/department_service.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/form_dialog.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../models/api_response_model.dart';
import '../../models/department_model.dart';
import '../../routes/app_routes.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  List<DepartmentModel> _all      = [];
  List<DepartmentModel> _filtered = [];
  bool    _loading = true;
  String? _error;
  String  _search  = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _all = await DepartmentService.getDepartments();
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
        : _all.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _showForm({DepartmentModel? dept}) async {
    final ctrl   = TextEditingController(text: dept?.name ?? '');
    final formKey = GlobalKey<FormState>();

    await showFormDialog(
      context,
      title: dept == null ? 'Add Department' : 'Edit Department',
      formKey: formKey,
      fields: TextFormField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Department Name *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
      onSubmit: () async {
        if (dept == null) {
          await DepartmentService.createDepartment(ctrl.text.trim());
        } else {
          await DepartmentService.updateDepartment(dept.id, ctrl.text.trim());
        }
      },
    );
    ctrl.dispose();
    _load();
  }

  Future<void> _delete(DepartmentModel dept) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete Department',
      message: 'Delete "${dept.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    try {
      await DepartmentService.deleteDepartment(dept.id);
      _snack('Department deleted.');
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
      title: AppStrings.departments,
      currentRoute: AppRoutes.departments,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar(
            hint: 'Search departments…',
            onSearch: (q) => setState(() { _search = q; _applyFilter(); }),
            onAdd: () => _showForm(),
            addLabel: 'Add Department',
          ),
          const SizedBox(height: 16),
          if (_loading)            const LoadingWidget()
          else if (_error != null) ErrorView(message: _error!, onRetry: _load)
          else _buildList(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Text('No departments found.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _filtered.asMap().entries.map((entry) {
          final i    = entry.key;
          final dept = entry.value;
          final isLast = i == _filtered.length - 1;
          return Column(children: [
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 20),
              ),
              title: Text(dept.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              subtitle: dept.doctorCount != null
                  ? Text('${dept.doctorCount} doctor${dept.doctorCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12))
                  : null,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                  tooltip: 'Edit',
                  onPressed: () => _showForm(dept: dept),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.danger),
                  tooltip: 'Delete',
                  onPressed: () => _delete(dept),
                ),
              ]),
            ),
            if (!isLast) const Divider(height: 1, color: AppColors.divider),
          ]);
        }).toList(),
      ),
    );
  }
}
