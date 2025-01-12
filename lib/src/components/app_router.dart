import 'package:finc/src/components/app_routes.dart';
import 'package:finc/src/components/app_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:finc/src/pages/home/add_account_view.dart';
import 'package:finc/src/pages/home/add_tag_view.dart';
import 'package:go_router/go_router.dart';
import 'package:finc/src/pages/settings/signin_page.dart';
import 'package:finc/src/models/user_model.dart';
import 'package:finc/src/pages/accounts/accounts_page.dart';
import 'package:finc/src/pages/settings/settings_page.dart';
import 'package:finc/src/pages/home/add_transaction_view.dart';
import 'package:finc/src/components/settings_controller.dart';

import '../pages/home/home_page.dart';

class AppRouter {
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final UserModel? currentUser;
  final SettingsController settingsController;

  AppRouter({
    this.currentUser,
    required this.settingsController,
  });

  late final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: currentUser == null ? AppRoutes.signin : AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppWrapper(
              settingsController: settingsController,
              navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) =>
                      HomePage(settingsController: settingsController),
                  routes: [
                    GoRoute(
                      path: AppRoutes.addAccount,
                      builder: (context, state) => AddAccountView(
                          settingsController: settingsController),
                    ),
                    GoRoute(
                      path: AppRoutes.addTag,
                      builder: (context, state) => AddTagView(),
                    ),
                  ]),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.accounts,
                builder: (context, state) =>
                    AccountsPage(settingsController: settingsController),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.signin,
                builder: (context, state) => SignInPage(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.addTransaction,
                builder: (context, state) =>
                    AddTransactionView(settingsController: settingsController),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) =>
                    SettingsPage(controller: settingsController),
              ),
            ]),
          ]),
    ],
  );
}
