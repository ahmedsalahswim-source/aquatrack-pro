import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/services/app_preferences.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/privacy_policy_page.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/terms_of_service_page.dart';

class SettingsTab extends StatefulWidget {
  final UserEntity user;

  const SettingsTab({super.key, required this.user});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _hasRated = false;

  void _showRateDialog(AppLocalizations t) {
    if (_hasRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('rate_already'))),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.translate('rate_question')),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.sentiment_dissatisfied, color: AppColors.warning, size: 36),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.translate('feedback_thanks'))),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.sentiment_neutral, color: AppColors.textMuted, size: 36),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _hasRated = true);
              },
            ),
            IconButton(
              icon: const Icon(Icons.sentiment_satisfied, color: AppColors.success, size: 36),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _hasRated = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.translate('rate_already'))),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.translate('rate_later')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    final user = widget.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: t.translate('account_info')),
          _SettingTile(
            icon: Icons.badge_outlined,
            title: t.translate('account_type'),
            subtitle: user.isPro ? t.translate('pro') : t.translate('free'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: user.isPro ? AppColors.accent.withValues(alpha:  0.15) : AppColors.textMuted.withValues(alpha:  0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isPro ? 'Pro' : 'Free',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: user.isPro ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          _SettingTile(
            icon: Icons.people_outlined,
            title: t.translate('athlete_count'),
            subtitle: '${user.athleteIds.length}',
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: t.translate('settings')),
          _SettingTile(
            icon: Icons.language,
            title: t.translate('language'),
            subtitle: context.watch<AppPreferences>().isArabic ? t.translate('arabic') : t.translate('english'),
            onTap: () => context.read<AppPreferences>().toggleLocale(),
          ),
          const Divider(height: 1),
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: t.translate('notifications'),
            subtitle: t.translate('enabled'),
            trailing: Switch(
              value: true,
              activeThumbColor: AppColors.accent,
              onChanged: (_) {},
            ),
          ),
          const Divider(height: 1),
          _SettingTile(
            icon: Icons.dark_mode_outlined,
            title: t.translate('dark_mode'),
            trailing: Switch(
              value: context.watch<AppPreferences>().isDark,
              activeThumbColor: AppColors.accent,
              onChanged: (_) => context.read<AppPreferences>().toggleTheme(),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: t.translate('about')),
          _SettingTile(
            icon: Icons.info_outlined,
            title: t.translate('version'),
            subtitle: '1.0.0',
          ),
          const Divider(height: 1),
          _SettingTile(
            icon: Icons.description_outlined,
            title: t.translate('privacy_policy'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
          ),
          const Divider(height: 1),
          _SettingTile(
            icon: Icons.article_outlined,
            title: t.translate('terms_of_service'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
            ),
          ),
          const Divider(height: 1),
          _SettingTile(
            icon: Icons.help_outlined,
            title: t.translate('help'),
            onTap: () {},
          ),
          const Divider(height: 1),
          _SettingTile(
            icon: Icons.star_outlined,
            title: t.translate('rate_app'),
            onTap: () => _showRateDialog(t),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(t.translate('logout_confirm_title')),
                    content: Text(t.translate('logout_confirm_body')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(t.translate('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.read<AuthBloc>().add(const LogoutEvent());
                        },
                        child: Text(t.translate('logout_btn'), style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: Text(t.translate('logout_btn'), style: const TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_left, color: AppColors.textMuted) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
