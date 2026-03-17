import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/calendar_provider.dart';
import 'services/reminder_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/firestore_reminder_service.dart';
import 'services/reminder_checker_service.dart';
import 'pages/login_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR', null);

  // Set background message handler BEFORE initializing Firebase
  FirebaseMessaging.onBackgroundMessage(
    FirebaseMessagingService.firebaseMessagingBackgroundHandler,
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize Reminder Service (timezone)
  await ReminderService.initialize();

  // Initialize Firebase Messaging
  try {
    await FirebaseMessagingService.initialize();

    try {
      await FirestoreReminderService.refreshDeviceIdForReminders();
      await FirestoreReminderService.deactivateRemindersWithInvalidTokens();
    } catch (e) {
      debugPrint('Error refreshing deviceId for reminders: $e');
    }

    try {
      await FirestoreReminderService.syncAndScheduleReminders();
    } catch (e) {
      debugPrint('Error syncing reminders from Firestore: $e');
    }
  } catch (e) {
    debugPrint('Firebase Messaging initialization error: $e');
  }

  // Initialize Reminder Checker Service
  try {
    await ReminderCheckerService().initialize();
  } catch (e) {
    debugPrint('Error initializing ReminderCheckerService: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.light,
        home: const AppRouter(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'AR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'AR'),
          Locale('es', ''),
        ],
      ),
    );
  }
}

/// Main router: decides which screen to show based on auth + calendar state
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Loading auth state
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not authenticated → Login
    if (!authProvider.isAuthenticated) {
      return const LoginPage();
    }

    // Authenticated → init calendar provider and check calendars
    final calendarProvider = context.watch<CalendarProvider>();
    calendarProvider.init(authProvider.uid!);

    // Has calendars → Home
    if (calendarProvider.hasCalendars) {
      return const HomePage();
    }

    // No calendars → Onboarding
    return const OnboardingPage();
  }
}
