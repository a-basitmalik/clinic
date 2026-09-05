import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser!;
    _name = TextEditingController(text: user.name);
    _email = TextEditingController(text: user.email);
    _phone = TextEditingController(text: user.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().updateProfile(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'My Profile',
      currentRoute: AppRoutes.profile,
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            CustomTextField(
                label: 'Name',
                controller: _name,
                validator: Validators.required),
            const SizedBox(height: 12),
            CustomTextField(
                label: 'Email',
                controller: _email,
                validator: Validators.email),
            const SizedBox(height: 12),
            CustomTextField(
                label: 'Phone',
                controller: _phone,
                validator: Validators.phone),
            const SizedBox(height: 20),
            Wrap(spacing: 12, children: [
              CustomButton(
                  label: 'Save Profile', loading: _saving, onPressed: _save),
              OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.changePassword),
                  child: const Text('Change Password')),
            ]),
          ]),
        ),
      ),
    );
  }
}
