import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';

Widget wrapWithMaterialApp(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    home: Provider<AppLocalizations>.value(
      value: AppLocalizations(locale),
      child: child,
    ),
  );
}
