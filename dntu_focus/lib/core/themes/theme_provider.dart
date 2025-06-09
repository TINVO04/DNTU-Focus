import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { light, dark, auto }

class ThemeProvider with ChangeNotifier {
  ThemeModeOption _themeMode = ThemeModeOption.auto;

  ThemeModeOption get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'auto';
    _themeMode = ThemeModeOption.values.firstWhere(
          (e) => e.toString().split('.').last == themeModeString,
      orElse: () => ThemeModeOption.auto,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeModeOption themeMode) async {
    _themeMode = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.toString().split('.').last);
    notifyListeners();
  }

  ThemeMode getThemeMode() {
    switch (_themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.auto:
        return ThemeMode.system;
    }
  }
}