import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppPreferences extends ChangeNotifier {
  static const String _boxName = 'app_cache';
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale_lang';

  late Box _box;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('ar', 'SA');

  AppPreferences() {
    _init();
  }

  void _init() {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
    } else {
      // Fallback if not initialized (though HiveCacheService should handle it)
      return;
    }
    
    final isDark = _box.get(_themeKey, defaultValue: true);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    final lang = _box.get(_localeKey, defaultValue: 'ar');
    _locale = lang == 'en' ? const Locale('en', 'US') : const Locale('ar', 'SA');
    notifyListeners();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isArabic => _locale.languageCode == 'ar';

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _box.put(_themeKey, mode == ThemeMode.dark);
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _box.put(_localeKey, locale.languageCode);
    notifyListeners();
  }

  void toggleLocale() {
    setLocale(_locale.languageCode == 'ar' ? const Locale('en', 'US') : const Locale('ar', 'SA'));
  }
}
