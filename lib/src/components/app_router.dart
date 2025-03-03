import 'package:finc/src/components/app_routes.dart';
import 'package:finc/src/components/app_wrapper.dart';
import 'package:finc/src/models/account_model.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:finc/src/pages/accounts/edit_account_view.dart';
import 'package:finc/src/pages/home/edit_transaction_view.dart';
import 'package:finc/src/pages/home/home_page.dart';
import 'package:finc/src/pages/profile/register_page.dart';
import 'package:finc/src/pages/tags/edit_tag_view.dart';
import 'package:finc/src/pages/tags/tags_page.dart';
import 'package:flutter/material.dart';
import 'package:finc/src/pages/accounts/add_account_view.dart';
import 'package:finc/src/pages/home/add_tag_view.dart';
import 'package:go_router/go_router.dart';
import 'package:finc/src/pages/profile/signin_page.dart';
import 'package:finc/src/models/user_model.dart';
import 'package:finc/src/pages/accounts/accounts_page.dart';
import 'package:finc/src/pages/profile/settings_page.dart';
import 'package:finc/src/pages/home/add_transaction_view.dart';
import 'package:finc/src/helpers/settings_service.dart';

class AppRouter {
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final UserModel? currentUser;
  final SettingsService settingsService;

  AppRouter({
    this.currentUser,
    required this.settingsService,
  });

  late final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: currentUser == null ? AppRoutes.signin : AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppWrapper(settingsService: settingsService, navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => HomePage(settingsService: settingsService),
              )
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.accounts,
                builder: (context, state) => AccountsPage(settingsService: settingsService),
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
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => SettingsPage(controller: settingsService),
      ),
      GoRoute(
        path: AppRoutes.addTransaction,
        builder: (context, state) =>
            AddTransactionView(settingsService: settingsService, transactionClone: state.extra as TransactionModel?),
      ),
      GoRoute(
          path: AppRoutes.editTransaction,
          builder: (context, state) => EditTransactionView(transaction: state.extra as TransactionModel)),
      GoRoute(
        path: AppRoutes.addAccount,
        builder: (context, state) => AddAccountView(settingsService: settingsService),
      ),
      GoRoute(
          path: AppRoutes.editAccount,
          builder: (context, state) => EditAccountView(account: state.extra as AccountModel)),
      GoRoute(
        path: AppRoutes.addTag,
        builder: (context, state) => AddTagView(),
      ),
      GoRoute(path: AppRoutes.editTag, builder: (context, state) => EditTagView(tag: state.extra as TagModel)),
    ],
  );
}
