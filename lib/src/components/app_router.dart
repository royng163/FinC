import 'package:finc/src/components/app_routes.dart';
import 'package:finc/src/components/app_wrapper.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:finc/src/pages/home/edit_transaction_view.dart';
import 'package:finc/src/pages/tags/edit_tag_view.dart';
import 'package:finc/src/pages/tags/tags_page.dart';
import 'package:flutter/material.dart';
import 'package:finc/src/pages/accounts/add_account_view.dart';
import 'package:finc/src/pages/home/add_tag_view.dart';
import 'package:go_router/go_router.dart';
import 'package:finc/src/pages/settings/signin_page.dart';
import 'package:finc/src/models/user_model.dart';
import 'package:finc/src/pages/accounts/accounts_page.dart';
import 'package:finc/src/pages/settings/settings_page.dart';
import 'package:finc/src/pages/home/add_transaction_view.dart';
import 'package:finc/src/components/settings_controller.dart';

import '../models/account_model.dart';
import '../models/tag_model.dart';
import '../pages/accounts/edit_account_view.dart';
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
          builder: (context, state, navigationShell) =>
              AppWrapper(settingsController: settingsController, navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => HomePage(settingsController: settingsController),
              )
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.accounts,
                builder: (context, state) => AccountsPage(settingsController: settingsController),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: AppRoutes.tags, builder: (context, state) => TagsPage()),
            ]),
          ]),
      GoRoute(
        path: AppRoutes.signin,
        builder: (context, state) => SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => SettingsPage(controller: settingsController),
      ),
      GoRoute(
        path: AppRoutes.addTransaction,
        builder: (context, state) => AddTransactionView(settingsController: settingsController),
      ),
      GoRoute(
          path: AppRoutes.editTransaction,
          builder: (context, state) => EditTransactionView(transaction: state.extra as TransactionModel)),
      GoRoute(
        path: AppRoutes.addAccount,
        builder: (context, state) => AddAccountView(settingsController: settingsController),
      ),
      GoRoute(
          path: AppRoutes.editAccount,
          builder: (context, state) => EditAccountView(account: state.extra as AccountModel)),
      GoRoute(
          path: AppRoutes.editTransaction,
          builder: (context, state) => EditTransactionView(transaction: state.extra as TransactionModel)),
      GoRoute(
        path: AppRoutes.addTag,
        builder: (context, state) => AddTagView(),
      ),
      GoRoute(path: AppRoutes.editTag, builder: (context, state) => EditTagView(tag: state.extra as TagModel)),
    ],
  );
}
