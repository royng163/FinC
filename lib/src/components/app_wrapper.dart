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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      body: widget.navigationShell,
      selectedIndex: _selectedIndex,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          switch (_selectedIndex) {
            case 0:
              await context.push(AppRoutes.addTransaction);
              break;
            case 1:
              await context.push(AppRoutes.addAccount);
              break;
            case 2:
              await context.push(AppRoutes.addTag);
              break;
          }
        },
        child: const Icon(Icons.add),
      ),
      destinations: [
        AdaptiveScaffoldDestination(
          title: 'Home',
          icon: Icons.home,
        ),
        AdaptiveScaffoldDestination(
          title: 'Accounts',
          icon: Icons.credit_card,
        ),
        AdaptiveScaffoldDestination(
          title: 'Tags',
          icon: Icons.local_offer,
        ),
      ],
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
        widget.navigationShell.goBranch(index);
      },
    );
  }
}
