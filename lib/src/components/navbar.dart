import 'package:finc/src/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:go_router/go_router.dart';
import '../pages/home/home_page.dart';
import '../pages/accounts/accounts_page.dart';
import 'settings_controller.dart';

class NavBar extends StatefulWidget {
  const NavBar({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  NavBarState createState() => NavBarState();
}

class NavBarState extends State<NavBar> {
  int currentIndex = 0;

  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home Navigator
    GlobalKey<NavigatorState>(), // Accounts Navigator
    GlobalKey<NavigatorState>(), // Settings Navigator
  ];

  final List<String> routes = [
    '/home',
    '/accounts',
    '/settings',
  ];

  Widget buildOffstageNavigator(int index) {
    return Offstage(
      offstage: currentIndex != index,
      child: Navigator(
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(builder: (context) {
            switch (index) {
              case 0:
                return const HomePage();
              case 1:
                return const AccountsPage();
              case 2:
                return SettingsPage(controller: widget.settingsController);
              default:
                return const HomePage();
            }
          });
        },
      ),
    );
  }

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.menu),
        //   onPressed: () {},
        // ),
        title: const Text('FinC'),
        // centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              onTap(2);
            },
          ),
        ],
      ),
      onDestinationSelected: onTap,
      body: Stack(
        children: [
          buildOffstageNavigator(0),
          buildOffstageNavigator(1),
          buildOffstageNavigator(2),
        ],
      ),
      selectedIndex: currentIndex,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add-transaction');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
