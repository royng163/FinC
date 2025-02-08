import 'package:finc/src/helpers/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsService with ChangeNotifier {
  static const String themeModeKey = 'themeMode';
  static const String baseCurrencyKey = 'baseCurrency';
  late final Box<dynamic> _box;

  // The user's preferred ThemeMode and getter.
  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  // The user's preferred base currency and getter.
  late String _baseCurrency;
  String get baseCurrency => _baseCurrency;

  /// Initialize the settings service by loading the user's settings.
  Future<void> init() async {
    _box = await HiveService().openBox<dynamic>('Settings');
    await loadSettings();
  }

  /// Load settings directly from the Hive box.
  Future<void> loadSettings() async {
    final themeModeString = _box.get(themeModeKey, defaultValue: 'system') as String;
    _themeMode = themeModeFromString(themeModeString);

    _baseCurrency = _box.get(baseCurrencyKey, defaultValue: 'HKD') as String;

    notifyListeners();
  }

  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    // Do not perform any work if new and old ThemeMode are identical
    if (newThemeMode == _themeMode) return;

    // Otherwise, store the new ThemeMode in memory
    _themeMode = newThemeMode;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    await _box.put(themeModeKey, themeModeToString(newThemeMode));
  }

  /// Update and persist the base currency based on the user's selection.
  Future<void> updateBaseCurrency(String newBaseCurrency) async {
    if (newBaseCurrency.isEmpty) return;

    // Do not perform any work if new and old base currency are identical
    if (newBaseCurrency == _baseCurrency) return;

    // Otherwise, store the new base currency in memory
    _baseCurrency = newBaseCurrency;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    await _box.put(baseCurrencyKey, newBaseCurrency);
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
