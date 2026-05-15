import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/assistant_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/permission_checkbox_group.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/assistant_model.dart';
import '../../routes/app_routes.dart';

class DoctorAssistantsScreen extends StatefulWidget {
  const DoctorAssistantsScreen({super.key});

  @override
  State<DoctorAssistantsScreen> createState() => _DoctorAssistantsScreenState();
}

class _DoctorAssistantsScreenState extends State<DoctorAssistantsScreen> {
  List<AssistantModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _items = await AssistantService.listMine();
      if (_items.isEmpty) _items = await AssistantService.listAll();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openForm([AssistantModel? assistant]) async {
    final created = await showDialog<AssistantModel>(context: context, builder: (_) => _AssistantFormDialog(assistant: assistant));
    if (created != null && mounted) {
      final temp = created.tempPassword;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(temp == null ? 'Assistant saved.' : 'Assistant created. Temporary password: $temp'),
        backgroundColor: AppColors.success,
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Assistants',
      currentRoute: AppRoutes.assistants,
      actions: [IconButton(onPressed: () => _openForm(), icon: const Icon(Icons.person_add_alt_1_rounded))],
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No assistants yet.', style: TextStyle(color: AppColors.textSecondary))))
                  : Column(children: _items.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AppColors.primarySurface, child: Icon(Icons.group_rounded, color: AppColors.primary)),
                        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text([a.email, a.phone, a.status].where((e) => e != null && e.isNotEmpty).join(' • ')),
                        trailing: Wrap(spacing: 4, children: [
                          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _openForm(a)),
                          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), onPressed: () async {
                            await AssistantService.delete(a.id);
                            _load();
                          }),
                        ]),
                      ),
                    )).toList()),
    );
  }
}

class _AssistantFormDialog extends StatefulWidget {
  final AssistantModel? assistant;
  const _AssistantFormDialog({this.assistant});

  @override
  State<_AssistantFormDialog> createState() => _AssistantFormDialogState();
}

class _AssistantFormDialogState extends State<_AssistantFormDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.assistant?.name ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.assistant?.email ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.assistant?.phone ?? '');
  late Map<String, bool> _perms = Map<String, bool>.from(widget.assistant?.permissions ?? {
    'can_view_appointments': true,
    'can_add_vitals': true,
    'can_upload_reports': false,
    'can_prepare_prescription_draft': true,
    'can_print_prescription': false,
    'can_view_patient_history': true,
  });
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        ..._perms,
      };
      final result = widget.assistant == null
          ? await AssistantService.create(body)
          : await AssistantService.update(widget.assistant!.id, body);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.assistant == null ? 'Add Assistant' : 'Edit Assistant'),
    content: SizedBox(width: 620, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      CustomTextField(label: 'Name', controller: _name),
      const SizedBox(height: 10),
      CustomTextField(label: 'Email', controller: _email),
      const SizedBox(height: 10),
      CustomTextField(label: 'Phone', controller: _phone),
      const SizedBox(height: 14),
      PermissionCheckboxGroup(permissions: _perms, onChanged: (k, v) => setState(() => _perms[k] = v)),
    ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      CustomButton(label: 'Save', loading: _saving, onPressed: _save, width: 120),
    ],
  );
}
