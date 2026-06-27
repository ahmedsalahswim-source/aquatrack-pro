import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/validators.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_state.dart';
import 'package:aquatrack_pro/features/auth/presentation/widgets/auth_button.dart';
import 'package:aquatrack_pro/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/privacy_policy_page.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/terms_of_service_page.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onLoginTap;

  const RegisterPage({super.key, this.onLoginTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('register')),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  AuthTextField(
                    labelKey: 'full_name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outlined,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    labelKey: 'email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textDirection: t.textDirection,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      labelText: t.translate('password'),
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.accent),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textDirection: t.textDirection,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      labelText: t.translate('confirm_password'),
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.accent),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) => Validators.validateConfirmPassword(v, _passwordController.text),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                        activeColor: AppColors.accent,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              button: true,
                              label: 'الموافقة على الشروط',
                              child: InkWell(
                                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                                borderRadius: BorderRadius.circular(8),
                                child: Text(
                                  t.translate('consent_text'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              children: [
                                Semantics(
                                  button: true,
                                  label: 'شروط الخدمة',
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Text(
                                      t.translate('terms_of_service'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.accent,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  t.translate('and'),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'سياسة الخصوصية',
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Text(
                                      t.translate('privacy_policy'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.accent,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return AuthButton(
                        text: t.translate('create_account'),
                        isLoading: state is AuthLoading,
                        onPressed: _acceptedTerms ? _handleRegister : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.translate('have_account'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: widget.onLoginTap,
                        child: Text(t.translate('login')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
        ),
      ),
    );
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(RegisterEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          ));
    }
  }
}
