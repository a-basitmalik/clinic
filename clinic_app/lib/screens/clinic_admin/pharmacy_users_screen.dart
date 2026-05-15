import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/staff_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/data_card_list.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/staff_user_model.dart';
import '../../routes/app_routes.dart';

class PharmacyUsersScreen extends StatefulWidget {
  const PharmacyUsersScreen({super.key});

  @override
  State<PharmacyUsersScreen> createState() => _PharmacyUsersScreenState();
}

class _PharmacyUsersScreenState extends State<PharmacyUsersScreen> {
  List<StaffUserModel> _all      = [];
  List<StaffUserModel> _filtered = [];
  bool    _loading = true;
  String? _error;
  String  _search  = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _all = await StaffService.getPharmacyUsers();
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
        : _all.where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q)).toList();
  }

  Future<void> _showAddDialog() async {
    final formKey   = GlobalKey<FormState>();
    final namCtrl   = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          title: const Text('Add Pharmacy User'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (dialogError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.dangerSurface, borderRadius: BorderRadius.circular(8)),
                    child: Text(dialogError!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: namCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  keyboardType: TextInputType.phone,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            _AddButton(onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              try {
                final user = await StaffService.createPharmacyUser({
                  'name':  namCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                await _showCreatedCredentials(user);
                _load();
              } on ApiException catch (e) {
                setDlgState(() => dialogError = e.message);
              }
            }),
          ],
        );
      }),
    );
    namCtrl.dispose(); emailCtrl.dispose(); phoneCtrl.dispose();
  }

  Future<void> _showCreatedCredentials(StaffUserModel user) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Pharmacy User Added'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Share these credentials. The password is shown only once.',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          _CredRow('Name',     user.name),
          _CredRow('Email',    user.email),
          _CredRow('Password', user.tempPassword ?? '—'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      ),
    );
  }

  Future<void> _deactivate(StaffUserModel staff) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Deactivate Pharmacy User',
      message: 'Deactivate ${staff.name}? They will no longer be able to log in.',
      confirmLabel: 'Deactivate',
    );
    if (!ok || !mounted) return;
    try {
      await StaffService.deactivatePharmacyUser(staff.id);
      _snack('${staff.name} deactivated.');
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
      title: 'Pharmacy Users',
      currentRoute: AppRoutes.pharmacyUsers,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar(
            hint: 'Search by name or email…',
            onSearch: (q) => setState(() { _search = q; _applyFilter(); }),
            onAdd: _showAddDialog,
            addLabel: 'Add Pharmacy User',
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
          child: Text('No pharmacy users found.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return DataCardList<StaffUserModel>(
      items: _filtered,
      builder: (s) => InfoCard(
        child: _StaffCardRow(
          staff: s,
          roleIcon: Icons.local_pharmacy_rounded,
          onDeactivate: s.isActive ? () => _deactivate(s) : null,
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  const _AddButton({required this.onPressed});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _loading ? null : () async {
        setState(() => _loading = true);
        await widget.onPressed();
        if (mounted) setState(() => _loading = false);
      },
      child: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Add'),
    );
  }
}

class _StaffCardRow extends StatelessWidget {
  final StaffUserModel staff;
  final IconData roleIcon;
  final VoidCallback? onDeactivate;
  const _StaffCardRow({required this.staff, required this.roleIcon, this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
        child: Icon(roleIcon, color: AppColors.primary, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(staff.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (staff.phone != null)
          Text(staff.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        StatusBadge(staff.status),
        const SizedBox(height: 4),
        if (onDeactivate != null)
          GestureDetector(
            onTap: onDeactivate,
            child: const Icon(Icons.block_rounded, size: 16, color: AppColors.danger),
          )
        else
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      ]),
    ]);
  }
}

class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  const _CredRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 70, child: Text('$label:', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
