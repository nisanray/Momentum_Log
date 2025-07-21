import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For MaterialLocalizations & SnackBar
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/activity_controller.dart';
import 'controllers/connectivity_controller.dart';
import 'views/auth_gate.dart';
import 'firebase_options.dart';
import 'models/task_entry.dart';
import 'models/daily_log.dart';
import 'models/user_prefs.dart';

// --- Global Constants for Hive Box Names ---
const String dailyLogsBoxName = 'dailyLogsBox_v1_secure';
const String userPrefsBoxName = 'userPrefsBox_v1_secure';

// --- App Theme Colors (Light Mode Focused) ---
const Color kAppPrimaryColor = Color(0xFF007AFF);
const Color kAppSecondaryColor = Color(0xFF5856D6);
const Color kAppAccentColor = Color(0xFFFF9500);

const Color kTextColorLight = Color(0xFF1C1C1E);
const Color kSecondaryTextColorLight = Color(0xFF8A8A8E);
const Color kSubtleTextColorLight = Color(0xFFC7C7CC);
const Color kSubtleBorderColorLight = Color(0xFFD1D1D6);
const Color kCardBackgroundLight = CupertinoColors.white;
const Color kSystemBackgroundLight = Color(0xFFF2F2F7);
const Color kTextFieldBackgroundLight = Color(0xFFF2F2F7);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(TaskEntryAdapter());
  Hive.registerAdapter(DailyLogAdapter());
  Hive.registerAdapter(UserPrefsAdapter());

  await Hive.openBox<DailyLog>(dailyLogsBoxName);
  await Hive.openBox<UserPrefs>(userPrefsBoxName);

  runApp(const MomentumLogApp());
}

class MomentumLogApp extends StatelessWidget {
  const MomentumLogApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cupertinoTextTheme = CupertinoTextThemeData(
      primaryColor: kAppPrimaryColor,
      textStyle: const TextStyle(
          fontFamily: '.SF Pro Text',
          color: kTextColorLight,
          fontSize: 17,
          letterSpacing: -0.41,
          fontWeight: FontWeight.w400,
          height: 1.25),
      actionTextStyle: const TextStyle(
          fontFamily: '.SF Pro Text',
          color: kAppPrimaryColor,
          fontSize: 17,
          letterSpacing: -0.41,
          fontWeight: FontWeight.w400),
      tabLabelTextStyle: const TextStyle(
          fontFamily: '.SF Pro Text',
          color: kSecondaryTextColorLight,
          fontSize: 10,
          letterSpacing: -0.08,
          fontWeight: FontWeight.w400),
      navTitleTextStyle: const TextStyle(
          fontFamily: '.SF Pro Display',
          color: kTextColorLight,
          fontSize: 17,
          letterSpacing: -0.41,
          fontWeight: FontWeight.w600),
      navLargeTitleTextStyle: const TextStyle(
          fontFamily: '.SF Pro Display',
          color: kTextColorLight,
          fontSize: 34,
          letterSpacing: 0.37,
          fontWeight: FontWeight.w700),
      pickerTextStyle: const TextStyle(
          fontFamily: '.SF Pro Display',
          color: kTextColorLight,
          fontSize: 21,
          letterSpacing: -0.6),
      dateTimePickerTextStyle: const TextStyle(
          fontFamily: '.SF Pro Display',
          color: kTextColorLight,
          fontSize: 21,
          letterSpacing: -0.6),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ConnectivityController()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProxyProvider2<AuthController, ConnectivityController,
            ActivityController>(
          create: (context) => ActivityController(
            authController: Provider.of<AuthController>(context, listen: false),
            connectivityController:
                Provider.of<ConnectivityController>(context, listen: false),
          ),
          update: (context, auth, connectivity, previousActivityController) {
            previousActivityController?.authControllerUpdated(auth.userId);
            return previousActivityController ??
                ActivityController(
                    authController: auth, connectivityController: connectivity);
          },
        ),
      ],
      child: CupertinoApp(
        title: 'Momentum Log',
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: kAppPrimaryColor,
          primaryContrastingColor: CupertinoColors.white,
          scaffoldBackgroundColor: kSystemBackgroundLight,
          barBackgroundColor: kSystemBackgroundLight.withOpacity(0.85),
          textTheme: cupertinoTextTheme,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        home: const AuthGate(),
      ),
    );
  }
}
