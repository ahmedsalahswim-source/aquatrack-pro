import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  final String labelKey;
  final String? hintKey;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType keyboardType;
  final IconData? prefixIcon;

  const AuthTextField({
    super.key,
    required this.labelKey,
    this.hintKey,
    required this.controller,
    this.validator,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textDirection: t.textDirection,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: t.translate(labelKey),
        hintText: hintKey != null ? t.translate(hintKey!) : null,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.accent) : null,
      ),
      validator: validator,
    );
  }
}
