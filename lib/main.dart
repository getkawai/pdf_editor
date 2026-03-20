import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _initializeCrashlytics();

  runApp(const PdfEditorApp());
}

Future<void> _initializeCrashlytics() async {
  final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

  FlutterError.onError = crashlytics.recordFlutterError;

  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };

  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
}

class PdfEditorApp extends StatelessWidget {
  const PdfEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Editor',
      debugShowCheckedModeBanner: false,
      navigatorObservers: _buildNavigatorObservers(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: Colors.blue.withOpacity(0.15),
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
            (states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(fontWeight: FontWeight.w600);
              }
              return null;
            },
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: Colors.blue.withOpacity(0.25),
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
            (states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(fontWeight: FontWeight.w600);
              }
              return null;
            },
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }

  List<NavigatorObserver> _buildNavigatorObservers() {
    if (Firebase.apps.isEmpty) {
      return const <NavigatorObserver>[];
    }
    try {
      final analytics = FirebaseAnalytics.instance;
      return <NavigatorObserver>[
        FirebaseAnalyticsObserver(analytics: analytics),
      ];
    } catch (_) {
      return const <NavigatorObserver>[];
    }
  }
}
