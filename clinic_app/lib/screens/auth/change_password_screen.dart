import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/api_response_model.dart';
import '../../routes/app_routes.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      await auth.changePassword(_current.text, _next.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context,
          AppRoutes.dashboardForRole(auth.currentUser!.role), (_) => false);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  const Text('Set a new password before continuing.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  CustomTextField(
                      label: 'Current password',
                      controller: _current,
                      isPassword: true,
                      validator: Validators.password),
                  const SizedBox(height: 12),
                  CustomTextField(
                      label: 'New password',
                      controller: _next,
                      isPassword: true,
                      validator: Validators.password),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Confirm new password',
                    controller: _confirm,
                    isPassword: true,
                    validator: (v) => Validators.confirmPassword(v, _next.text),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                      label: 'Change Password',
                      loading: _saving,
                      onPressed: _save),
                ]),
          ),
        ),
      ),
    );
  }
}
