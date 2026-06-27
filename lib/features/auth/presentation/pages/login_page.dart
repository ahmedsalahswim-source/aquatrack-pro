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

class LoginPage extends StatefulWidget {
  final VoidCallback? onRegisterTap;

  const LoginPage({super.key, this.onRegisterTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, current) => current is AuthPasswordResetSent,
      listener: (ctx, state) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(t.translate('reset_email_sent')),
            backgroundColor: AppColors.success,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.08),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('🏊', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.translate('app_name'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.translate('app_subtitle'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: size.height * 0.06),
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
                      validator: (v) => v == null || v.isEmpty ? t.translate('error') : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: t.textDirection == TextDirection.rtl
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(context),
                        child: Text(
                          t.translate('forgot_password'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthButton(
                      text: t.translate('login'),
                      isLoading: state is AuthLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            t.translate('or_continue_with'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AuthButton(
                      text: t.translate('google_sign_in'),
                      icon: Icons.g_mobiledata,
                      backgroundColor: Colors.white,
                      onPressed: () => context.read<AuthBloc>().add(const GoogleSignInEvent()),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.translate('no_account'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: widget.onRegisterTap,
                          child: Text(t.translate('create_account')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (state is AuthError)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha:  0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.message,
                                style: const TextStyle(color: AppColors.danger, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  void _showForgotPasswordDialog(BuildContext dialogContext) {
    final t = dialogContext.read<AppLocalizations>();
    final emailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: dialogContext,
      builder: (ctx) => BlocListener<AuthBloc, AuthState>(
        listener: (listenerCtx, state) {
          if (state is AuthPasswordResetSent) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(listenerCtx).showSnackBar(
              SnackBar(
                content: Text(t.translate('reset_email_sent')),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is AuthError) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(listenerCtx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        child: AlertDialog(
          title: Text(t.translate('forgot_password')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.translate('forgot_password_body'),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: t.translate('email'),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.accent),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                dialogContext.read<AuthBloc>().add(ForgotPasswordEvent(email: email));
              },
              child: Text(t.translate('send_reset_link')),
            ),
          ],
        ),
      ),
    );
  }
}
