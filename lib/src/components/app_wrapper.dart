import 'package:flutter/material.dart';
import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import 'settings_controller.dart';

class AppWrapper extends StatefulWidget {
  final SettingsController settingsController;
  final StatefulNavigationShell navigationShell;

  const AppWrapper({
    super.key,
    required this.settingsController,
    required this.navigationShell,
  });

  @override
  AppWrapperState createState() => AppWrapperState();
}

class AppWrapperState extends State<AppWrapper> {
  final int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      body: widget.navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTransaction),
        child: const Icon(Icons.add),
      ),
      selectedIndex: _selectedIndex,
      destinations: [
        AdaptiveScaffoldDestination(
          title: 'Home',
          icon: Icons.home,
        ),
        AdaptiveScaffoldDestination(
          title: 'Accounts',
          icon: Icons.credit_card,
        ),
      ],
      onDestinationSelected: widget.navigationShell.goBranch,
    );
  }
}
