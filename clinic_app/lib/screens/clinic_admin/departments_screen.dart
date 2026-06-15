import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/department_service.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/form_dialog.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_surface.dart';
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
  List<DepartmentModel> _all = [];
  List<DepartmentModel> _filtered = [];
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
      _all = await DepartmentService.getDepartments();
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
        : _all.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _showForm({DepartmentModel? dept}) async {
    final ctrl = TextEditingController(text: dept?.name ?? '');
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
            onSearch: (q) => setState(() {
              _search = q;
              _applyFilter();
            }),
            onAdd: () => _showForm(),
            addLabel: 'Add Department',
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LoadingWidget()
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else
            _buildList(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Text('No departments found.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return GlassPanel(
      radius: 18,
      child: Column(
        children: _filtered.asMap().entries.map((entry) {
          final i = entry.key;
          final dept = entry.value;
          final isLast = i == _filtered.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
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
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: .25)),
                  ),
                  child: const Icon(Icons.category_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(dept.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    if (dept.doctorCount != null)
                      Text(
                          '${dept.doctorCount} doctor${dept.doctorCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _ActionIcon(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    onTap: () => _showForm(dept: dept),
                  ),
                  const SizedBox(width: 6),
                  _ActionIcon(
                    icon: Icons.delete_rounded,
                    color: AppColors.danger,
                    onTap: () => _delete(dept),
                  ),
                ]),
              ]),
            ),
            if (!isLast)
              Divider(height: 1, color: AppColors.divider.withValues(alpha: .5)),
          ]);
        }).toList(),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
