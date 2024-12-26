import 'package:flutter/material.dart';

import '../helpers/settings_service.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class SettingsController with ChangeNotifier {
  SettingsController(this.settingsService);

  // Make SettingsService a private variable so it is not used directly.
  final SettingsService settingsService;

  // The user's preferred ThemeMode.
  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  // The user's preferred base currency.
  late String _baseCurrency;
  String get baseCurrency => _baseCurrency;

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    _themeMode = await settingsService.themeMode();
    _baseCurrency = await settingsService.baseCurrency();

    // Important! Inform listeners a change has occurred.
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

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await settingsService.updateThemeMode(newThemeMode);
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

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await settingsService.updateBaseCurrency(newBaseCurrency);
  }
}
