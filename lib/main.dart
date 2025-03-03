import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/models/tag_model.dart';
import 'package:finc/src/models/timestamp_adapter.dart';
import 'package:finc/src/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/helpers/settings_service.dart';
import 'src/models/account_model.dart';

Future<void> main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive and register the adapters
  await Hive.initFlutter();
  Hive.registerAdapter(AccountModelAdapter());
  Hive.registerAdapter(AccountTypeAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(TagModelAdapter());
  Hive.registerAdapter(TagTypeAdapter());
  Hive.registerAdapter(TimestampAdapter());

  // Initialize the HiveService
  final hiveService = HiveService();
  await hiveService.init();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  // Initialize the SettingsService
  final settingsService = SettingsService();
  await settingsService.loadSettings();

  // Run the app and pass in the SettingsController for changes.
  runApp(MyApp(settingsService: settingsService));
}
