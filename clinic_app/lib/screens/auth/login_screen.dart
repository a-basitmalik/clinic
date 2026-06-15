import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/api_response_model.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/premium_surface.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      final role = auth.currentUser!.role;
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.dashboardForRole(role), (_) => false);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(
          () => _error = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: Row(
          children: [
            if (isWide)
              Expanded(
                flex: 5,
                child: _HeroPanel(),
              ),
            Expanded(
              flex: isWide ? 4 : 1,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _LoginForm(
                      formKey: _formKey,
                      emailCtrl: _emailCtrl,
                      passCtrl: _passCtrl,
                      error: _error,
                      loading: _loading,
                      onSubmit: _submit,
                      showLogo: !isWide,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D2137),
                Color(0xFF093D38),
                Color(0xFF1BA89E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0, .52, 1],
            ),
          ),
          child: Stack(
            children: [
              // Decorative orbs
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: .10),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -60,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .04),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight.withValues(alpha: .06),
                  ),
                ),
              ),
              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: .45),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_hospital_rounded,
                            color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'MedCare',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.appTagline,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .65),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      ...[
                        _FeatureLine(
                            Icons.people_alt_rounded, 'Multi-role access control'),
                        const SizedBox(height: 16),
                        _FeatureLine(Icons.medical_services_rounded,
                            'Complete patient management'),
                        const SizedBox(height: 16),
                        _FeatureLine(Icons.analytics_rounded,
                            'Real-time analytics & reports'),
                        const SizedBox(height: 16),
                        _FeatureLine(Icons.local_pharmacy_rounded,
                            'Integrated pharmacy system'),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureLine(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .15)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .80),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;
  final bool showLogo;

  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.error,
    required this.loading,
    required this.onSubmit,
    required this.showLogo,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 30,
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLogo) ...[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .38),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: const Icon(Icons.local_hospital_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            AppStrings.welcomeBack,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.signInToContinue,
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 30),
          Form(
            key: formKey,
            child: Column(
              children: [
                CustomTextField(
                  label: AppStrings.email,
                  hint: 'you@example.com',
                  controller: emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: AppStrings.password,
                  controller: passCtrl,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  onSubmitted: (_) => onSubmit(),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: .3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(error!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          CustomButton(
            label: AppStrings.login,
            loading: loading,
            width: double.infinity,
            onPressed: loading ? null : onSubmit,
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.clinicRegister),
            icon: const Icon(Icons.add_business_rounded, size: 18),
            label: const Text(AppStrings.registerClinic),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primarySurface.withValues(alpha: .5),
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: .35),
                  width: 1.5),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
