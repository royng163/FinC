// ignore_for_file: deprecated_member_use

import 'package:dynamic_color/dynamic_color.dart';
import 'package:finc/src/components/app_router.dart';
import 'package:finc/src/helpers/authentication_service.dart';
import 'package:finc/src/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'helpers/settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  final SettingsService settingsService;

  const MyApp({super.key, required this.settingsService});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final AuthenticationService authService = AuthenticationService();
  late Future<AppRouter> appRouter;
  UserModel? currentUser;

  // Define your seed colors
  static const _primarySeedColor = Color(0xFF1A73E8); // Blue color similar to Google apps

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
        currentUser = UserModel.fromFirestore(doc);
      } else {
        // User document does not exist, sign out the user
        await authService.auth.signOut();
        currentUser = null;
      }
    } else {
      currentUser = null;
    }
    return AppRouter(currentUser: currentUser, settingsService: widget.settingsService);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppRouter>(
      future: appRouter,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
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
            listenable: widget.settingsService,
            builder: (BuildContext context, Widget? child) {
              return DynamicColorBuilder(
                builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
                  // Create color schemes based on dynamic colors if available (Android 12+)
                  // or fall back to our seed color
                  ColorScheme lightColorScheme;
                  ColorScheme darkColorScheme;

                  if (lightDynamic != null && darkDynamic != null) {
                    // On Android 12+, use device color scheme
                    lightColorScheme = lightDynamic.harmonized();
                    darkColorScheme = darkDynamic.harmonized();
                  } else {
                    // Use our default color scheme
                    lightColorScheme = ColorScheme.fromSeed(
                      seedColor: _primarySeedColor,
                      brightness: Brightness.light,
                    );
                    darkColorScheme = ColorScheme.fromSeed(
                      seedColor: _primarySeedColor,
                      brightness: Brightness.dark,
                    );
                  }

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
                    onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,

                    // Define a light and dark color theme with Material 3
                    theme: ThemeData(
                      useMaterial3: true,
                      colorScheme: lightColorScheme,
                    ),
                    darkTheme: ThemeData(
                      useMaterial3: true,
                      colorScheme: darkColorScheme,
                    ),
                    themeMode: widget.settingsService.themeMode,
                    routerConfig: appRouter.router,
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
