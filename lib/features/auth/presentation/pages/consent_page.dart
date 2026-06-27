import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_state.dart';
import 'package:aquatrack_pro/features/auth/presentation/widgets/auth_button.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';

class ConsentPage extends StatelessWidget {
  final UserEntity user;

  const ConsentPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(t.translate('consent_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('🛡️', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.translate('consent_title'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('👤', t.translate('full_name'), user.displayName),
                  const Divider(height: 20),
                  _buildInfoRow('📧', t.translate('email'), user.email),
                  const Divider(height: 20),
                  _buildInfoRow('📅', t.translate('account_created'), '${user.createdAt.year}/${user.createdAt.month}/${user.createdAt.day}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha:  0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha:  0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 ما الذي نوافق عليه؟',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBullet('تسجيل بيانات النوم والنبض والتغذية والتدريب'),
                  _buildBullet('تحليل البيانات حسابياً لتقييم الإجهاد الرياضي'),
                  _buildBullet('تقديم توصيات مخصصة بناءً على البيانات'),
                  _buildBullet('تخزين البيانات بشكل آمن ومشفّر'),
                  const SizedBox(height: 12),
                  const Text(
                    'لن تتم مشاركة البيانات مع أي طرف ثالث دون موافقتك.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Column(
                  children: [
                    AuthButton(
                      text: t.translate('consent_agree'),
                      onPressed: () {
                        context.read<AuthBloc>().add(const UpdateConsentEvent(consented: true));
                      },
                      isLoading: state is AuthLoading,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(const LogoutEvent());
                      },
                      child: Text(
                        t.translate('consent_disagree'),
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.accent, fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
