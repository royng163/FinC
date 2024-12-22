import 'package:finc/src/pages/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_navigation/adaptive_navigation.dart';
import '../pages/home/home_page.dart';
import '../pages/accounts/accounts_page.dart';
import '../pages/settings/settings_controller.dart';
import '../pages/home/add_transaction_view.dart';

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

  // Define the destinations
  final List<AdaptiveScaffoldDestination> destinations = [
    AdaptiveScaffoldDestination(
      title: 'Home',
      icon: Icons.home,
    ),
    AdaptiveScaffoldDestination(
      title: 'Accounts',
      icon: Icons.credit_card,
    ),
  ];

  // Build individual Navigators for each tab
  Widget buildOffstageNavigator(int index) {
    return Offstage(
      offstage: currentIndex != index,
      child: Navigator(
        key: navigatorKeys[index],
        onGenerateRoute: (RouteSettings settings) {
          Widget page;
          switch (index) {
            case 0:
              page = const HomePage();
              break;
            case 1:
              page = const AccountsPage();
              break;
            case 2:
              page = SettingsView(controller: widget.settingsController);
              break;
            default:
              page = const HomePage();
          }
          return MaterialPageRoute(builder: (_) => page);
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
      destinations: destinations,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionView()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
