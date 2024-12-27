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
    GlobalKey<NavigatorState>(), // Accounts Navigatorator
  ];

  final List<Widget> pages = [
    const HomePage(),
    const AccountsPage(),
  ];

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
              context.push('/settings');
            },
          ),
        ],
      ),
      onDestinationSelected: onTap,
      body: IndexedStack(
        index: currentIndex,
        children: pages,
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
          context.go('/home/add-transaction');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
