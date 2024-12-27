import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that stores and retrieves user settings.
class SettingsService {
  static const String themeModeKey = 'themeMode';
  static const String baseCurrencyKey = 'baseCurrency';

  /// Loads the User's preferred ThemeMode from local storage.
  Future<ThemeMode> themeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(themeModeKey) ?? 'system';
    return themeModeFromString(themeModeString);
  }

  /// Persists the user's preferred ThemeMode to local storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, themeModeToString(theme));
  }

  /// Loads the User's preferred base currency from local storage.
  Future<String> baseCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(baseCurrencyKey) ?? 'HKD';
  }

  /// Persists the user's preferred base currency to local storage.
  Future<void> updateBaseCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(baseCurrencyKey, currency);
  }

  ThemeMode themeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
