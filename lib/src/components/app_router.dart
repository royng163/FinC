import 'package:finc/src/components/navbar.dart';
import 'package:finc/src/pages/home/add_account_view.dart';
import 'package:finc/src/pages/home/add_tag_view.dart';
import 'package:go_router/go_router.dart';
import 'package:finc/src/pages/settings/signin_page.dart';
import 'package:finc/src/models/user_model.dart';
import 'package:finc/src/pages/accounts/accounts_page.dart';
import 'package:finc/src/pages/settings/settings_page.dart';
import 'package:finc/src/pages/home/add_transaction_view.dart';
import 'package:finc/src/components/settings_controller.dart';

class AppRouter {
  final UserModel? currentUser;
  final SettingsController settingsController;

  AppRouter({
    this.currentUser,
    required this.settingsController,
  });

  late final GoRouter router = GoRouter(
    initialLocation: currentUser == null ? '/signin' : '/home',
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => SignInPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            NavBar(settingsController: settingsController),
      ),
      GoRoute(
        path: '/add-account',
        builder: (context, state) =>
            AddAccountView(settingsController: settingsController),
      ),
      GoRoute(
        path: '/add-tag',
        builder: (context, state) => AddTagView(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) =>
            AddTransactionView(settingsController: settingsController),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => AccountsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            SettingsPage(controller: settingsController),
      ),
    ],
  );
}
