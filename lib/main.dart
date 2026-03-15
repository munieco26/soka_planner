import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'services/public_google_calendar_service.dart';
import 'services/calendar_repository.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/firestore_reminder_service.dart';
import 'services/reminder_checker_service.dart';
import 'pages/agenda_page.dart';
import 'theme/app_theme.dart';
import 'widgets/permission_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR', null);

  // Set background message handler BEFORE initializing Firebase
  // This must be registered before runApp() is called
  FirebaseMessaging.onBackgroundMessage(
    FirebaseMessagingService.firebaseMessagingBackgroundHandler,
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print('⚠️ Firebase initialization error: $e');
  }

  // Initialize Reminder Service (timezone)
  await ReminderService.initialize();

  // Initialize Firebase Messaging
  try {
    await FirebaseMessagingService.initialize();

    // Refresh deviceId for reminders in case token changed (fixes invalid token issues)
    // This is critical - ensures all reminders use the current valid token
    try {
      print('🔄 Refreshing deviceId for all reminders on startup...');
      await FirestoreReminderService.refreshDeviceIdForReminders();

      // Also clean up any reminders with clearly invalid tokens
      await FirestoreReminderService.deactivateRemindersWithInvalidTokens();
    } catch (e) {
      print('⚠️ Error refreshing deviceId for reminders: $e');
    }

    // Sync reminders from Firestore after messaging is initialized (to get FCM token)
    try {
      await FirestoreReminderService.syncAndScheduleReminders();
    } catch (e) {
      print('⚠️ Error syncing reminders from Firestore: $e');
    }
  } catch (e) {
    print('⚠️ Firebase Messaging initialization error: $e');
  }

  // Initialize Reminder Checker Service (for periodic checking)
  try {
    await ReminderCheckerService().initialize();
  } catch (e) {
    print('⚠️ Error initializing ReminderCheckerService: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<CalendarRepository>(
      create: (_) => PublicGoogleCalendarService(
        apiKey: AppConfig.googleApiKey,
        calendarId: AppConfig.developmentCalendarId,
      ),
      child: MaterialApp(
        title: 'Agenda Soka',
        theme: AppTheme.light,
        home: const AppStartup(),
        debugShowCheckedModeBanner: false,
        // Configuración de idioma español
        locale: const Locale('es', 'AR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'AR'), // Español Argentina
          Locale('es', ''), // Español general
        ],
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAskedPermissions = prefs.getBool('has_asked_permissions') ?? false;

    if (!hasAskedPermissions && mounted) {
      // Wait a bit before showing the dialog
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        final result = await showDialog<Map<String, bool>>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PermissionDialog(),
        );

        // Mark that we've asked for permissions
        await prefs.setBool('has_asked_permissions', true);

        // Initialize notifications if granted
        if (result?['notifications'] == true) {
          await NotificationService.initialize();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AgendaPage();
  }
}
