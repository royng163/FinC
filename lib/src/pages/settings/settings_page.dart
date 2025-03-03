import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:go_router/go_router.dart';
import '../../components/app_routes.dart';
import '../../helpers/settings_service.dart';
import '../../helpers/authentication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_upgrade_page.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService controller;

  const SettingsPage({super.key, required this.controller});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final AuthenticationService _authService = AuthenticationService();
  late User _currentUser;
  bool _isAnonymous = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _currentUser = _authService.getCurrentUser();
    setState(() {
      _isAnonymous = _currentUser.isAnonymous;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Group settings by section for better organization
          _buildPreferencesSection(),
          _buildPaddedDivider(),
          _buildAccountSection(),
          _buildPaddedDivider(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  // PREFERENCES SECTION
  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Preferences'),

        // Theme
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text('Theme'),
          trailing: DropdownButton<ThemeMode>(
            value: widget.controller.themeMode,
            isDense: true,
            underline: const SizedBox(),
            onChanged: widget.controller.updateThemeMode,
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark'),
              ),
            ],
          ),
        ),

        // Currency
        ListTile(
          leading: const Icon(Icons.attach_money),
          title: const Text('Base Currency'),
          subtitle: Text(widget.controller.baseCurrency),
          onTap: () {
            showCurrencyPicker(
              context: context,
              onSelect: (Currency currency) {
                widget.controller.updateBaseCurrency(currency.code);
                setState(() {});
              },
            );
          },
        ),
      ],
    );
  }

  // ACCOUNT SECTION
  Widget _buildAccountSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Account'),

        // Create Account (only for anonymous users)
        if (_isAnonymous)
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Create Account'),
            subtitle: const Text('Sync your data across devices'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountUpgradePage(),
                ),
              ).then((_) => _loadUserData());
            },
          ),

        // Sign Out
        ListTile(
          leading: Icon(
            Icons.logout,
            color: _isAnonymous ? colorScheme.error : null,
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(
              color: _isAnonymous ? colorScheme.error : null,
            ),
          ),
          subtitle: _isAnonymous ? const Text('Warning: Guest users will lose all data') : null,
          onTap: () => _handleSignOut(),
        ),
      ],
    );
  }

  // ABOUT SECTION
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('App Version'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('Source Code'),
          onTap: () {
            // Open privacy policy
          },
        ),
      ],
    );
  }

  // SIGN OUT HELPER
  Future<void> _handleSignOut() async {
    // Show confirmation dialog for anonymous users
    if (_isAnonymous) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Warning'),
          content: const Text(
            'You will lose all your data permanently and won\'t be able to recover it. '
            'Create an account to sync your data and prevent data loss.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE & SIGN OUT'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    await _authService.signOut();
    if (mounted) {
      context.go(AppRoutes.signin);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaddedDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(),
    );
  }
}
