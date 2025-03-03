import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:finc/src/components/app_routes.dart';
import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/helpers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'balance_tab.dart';

class HomePage extends StatefulWidget {
  final SettingsService settingsService;

  const HomePage({super.key, required this.settingsService});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  BalanceTabState? balanceTabState;

  @override
  void initState() {
    super.initState();
    HiveService().syncData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AdaptiveAppBar(
          title: const Text('FinC'),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                text: "Balance",
              ),
              Tab(
                text: "Portfolio",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            BalanceTab(
              settingsService: widget.settingsService,
              registerState: (state) => balanceTabState = state,
            ),
            portfolioView(),
          ],
        ),
      ),
    );
  }

  Widget portfolioView() {
    return const Center(
      child: Text("To Be Implemented"),
    );
  }
}
