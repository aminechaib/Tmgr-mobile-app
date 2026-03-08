// lib/main.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ruko_mobile_app/api/firebase_api.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:ruko_mobile_app/services/navigation_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ ADD THIS IMPORT
import 'dart:io'; // ✅ ADD THIS IMPORT

// --- AppColors Class ---
// (This class is unchanged)
final StreamController<void> notificationStream = StreamController.broadcast();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF0D5D6E);
  static const Color secondary = Color(0xFF25A4A6);
  static const Color background = Color(0xFFF5F5F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color urgentPriority = Color(0xFFD32F2F);
  static const Color highPriority = Color(0xFFFFA000);
  static const Color mediumPriority = Color(0xFF388E3C);
  static const Color statusOpen = Color(0xFF1976D2);
  static const Color statusDone = Color(0xFF388E3C);
}

// ✅ --- THIS IS THE CORRECTED main() FUNCTION ---
Future<void> main() async {
  // This object will hold a potential startup error.
  Object? startupError;

  try {
    // Ensure Flutter bindings are initialized before any other Flutter code.
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase. This is a common point of failure in release mode.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize push notifications for all platforms (Android, iOS, and Web)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await FirebaseApi().initNotifications();
    } else if (kIsWeb) {
      await FirebaseApi().initNotifications();
    }
  } catch (e) {
    // If any of the above steps fail, we catch the error.
    print("!!! FAILED TO INITIALIZE APP: $e");
    startupError = e;
  }

  // Now, run the app. We pass the potential error to the MyApp widget.
  runApp(MyApp(startupError: startupError));
}

// ✅ --- MyApp WIDGET IS UPDATED TO HANDLE THE ERROR ---
class MyApp extends StatelessWidget {
  final Object? startupError;

  const MyApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Ruko Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardBackground,
          foregroundColor: AppColors.textPrimary,
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: AppColors.cardBackground,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // If there was a startup error, show an error screen.
      // Otherwise, show the normal SplashScreen.
      home: startupError != null
          ? ErrorScreen(error: startupError!)
          : const SplashScreen(),
    );
  }
}

// ✅ --- A NEW, SIMPLE WIDGET TO DISPLAY THE STARTUP ERROR ---
class ErrorScreen extends StatelessWidget {
  final Object error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to start the application.\nPlease contact support.\n\nError: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
