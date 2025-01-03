import 'package:flutter/material.dart';
import '../../components/settings_controller.dart';
import 'balance_tab.dart';

class HomePage extends StatefulWidget {
  final SettingsController settingsController;

  const HomePage({super.key, required this.settingsController});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: const TabBar(
          tabs: <Widget>[
            Tab(
              text: "Balance",
            ),
            Tab(
              text: "Portfolio",
            ),
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            BalanceTab(settingsController: widget.settingsController),
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
