import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../components/settings_controller.dart';
import 'account_upgrade_page.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsPage extends StatefulWidget {
  final SettingsController controller;

  const SettingsPage({super.key, required this.controller});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<ThemeMode>(
              // Read the selected themeMode from the controller
              value: widget.controller.themeMode,
              // Call the updateThemeMode method any time the user selects a theme.
              onChanged: widget.controller.updateThemeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Theme'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light Theme'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark Theme'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                showCurrencyPicker(
                  context: context,
                  onSelect: (Currency currency) {
                    widget.controller.updateBaseCurrency(currency.code);
                  },
                );
              },
              child: Text(
                  'Select Base Currency: ${widget.controller.baseCurrency}'),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const AccountUpgradePage(),
            //       ),
            //     );
            //   },
            //   child: const Text('Upgrade Account'),
            // ),
          ],
        ),
      ),
    );
  }
}
