import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/login_page.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/register_page.dart';

class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({super.key});

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    final textDirection = context.watch<AppLocalizations>().textDirection;
    return Directionality(
      textDirection: textDirection,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLogin
            ? LoginPage(
                key: const ValueKey('login'),
                onRegisterTap: () => setState(() => _isLogin = false),
              )
            : RegisterPage(
                key: const ValueKey('register'),
                onLoginTap: () => setState(() => _isLogin = true),
              ),
      ),
    );
  }
}
