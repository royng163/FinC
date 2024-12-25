import 'package:finc/src/components/app_router.dart';
import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'components/settings_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  final SettingsController settingsController;

  const MyApp({super.key, required this.settingsController});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final AuthenticationService authService = AuthenticationService();
  late Future<AppRouter> appRouter;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    appRouter = initializeAppRouter();
  }

  Future<AppRouter> initializeAppRouter() async {
    User? user = authService.auth.currentUser;
    if (user != null) {
      // Fetch user data from Firestore
      final doc = await authService.db.collection('Users').doc(user.uid).get();
      if (doc.exists) {
        currentUser = UserModel.fromDocument(doc);
      } else {
        // User document does not exist, sign out the user
        await authService.auth.signOut();
        currentUser = null;
      }
    } else {
      currentUser = null;
    }
    return AppRouter(
        currentUser: currentUser,
        settingsController: widget.settingsController);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppRouter>(
      future: appRouter,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: const CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            ),
          );
        } else {
          final appRouter = snapshot.data!;
          return ListenableBuilder(
            listenable: widget.settingsController,
            builder: (BuildContext context, Widget? child) {
              return MaterialApp.router(
                // Providing a restorationScopeId allows the Navigator built by the
                // MaterialApp to restore the navigation stack when a user leaves and
                // returns to the app after it has been killed while running in the
                // background.
                restorationScopeId: 'app',

                // Provide the generated AppLocalizations to the MaterialApp. This
                // allows descendant Widgets to display the correct translations
                // depending on the user's locale.
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''), // English, no country code
                ],

                // Use AppLocalizations to configure the correct application title
                // depending on the user's locale.
                //
                // The appTitle is defined in .arb files found in the localization
                // directory.
                onGenerateTitle: (BuildContext context) =>
                    AppLocalizations.of(context)!.appTitle,

                // Define a light and dark color theme. Then, read the user's
                // preferred ThemeMode (light, dark, or system default) from the
                // SettingsController to display the correct theme.
                theme: ThemeData(),
                darkTheme: ThemeData.dark(),
                themeMode: widget.settingsController.themeMode,

                routerConfig: appRouter.router,
              );
            },
          );
        }
      },
    );
  }
}
