import 'package:flutter/material.dart';
import 'package:nvm_desktop/utils/shared_preferences.dart';

class AppConfigProvider with ChangeNotifier {
  // 持久化存储的 Key
  static const String _keyLocale = 'app_locale';
  static const String _keyTheme = 'app_theme_mode';

  // 内存状态
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  // 获取接口
  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  AppConfigProvider() {
    _loadFromPrefs();
  }

  // 初始化加载
  Future<void> _loadFromPrefs() async {
    // 1. 加载语言 (如果没存过，则为 null，MaterialApp 会自动随系统)
    String? langCode = SpUtil().getString(_keyLocale);
    if (langCode != null) {
      _locale = Locale(langCode);
    }
    // 2. 加载主题 (如果没存过，默认为 system)
    String? themeStr = SpUtil().getString(_keyTheme);
    if (themeStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeStr,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

  // 设置语言并保存
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await SpUtil().remove(_keyLocale);
    } else {
      await SpUtil().setString(_keyLocale, locale.languageCode);
    }
  }

  // 设置主题并保存
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await SpUtil().setString(_keyTheme, mode.toString());
  }
}
