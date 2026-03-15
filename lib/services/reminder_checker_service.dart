import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_reminder_service.dart';
import 'reminder_service.dart';
import 'notification_service.dart';
import '../models/event.dart';

/// Service that periodically checks for reminders and syncs them
/// This ensures reminders are checked even when the app is active
/// Background notifications are handled by Android's AlarmManager via zonedSchedule
class ReminderCheckerService with WidgetsBindingObserver {
  static final ReminderCheckerService _instance =
      ReminderCheckerService._internal();
  factory ReminderCheckerService() => _instance;
  ReminderCheckerService._internal();

  Timer? _periodicTimer;
  Timer? _syncTimer;
  bool _isInitialized = false;

  /// Initialize the reminder checker service
  /// Should be called when app starts
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Sync reminders immediately on initialization
    await _syncReminders();

    // Check for due reminders every minute when app is active
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkForDueReminders(),
    );

    // Sync reminders from Firestore every 5 minutes when app is active
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _syncReminders(),
    );

    _isInitialized = true;
    print('✅ ReminderCheckerService initialized');
  }

  /// Dispose the service
  void dispose() {
    _periodicTimer?.cancel();
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    print('🛑 ReminderCheckerService disposed');
  }

  /// Called when app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - refresh tokens and sync reminders immediately
        print('📱 App resumed - refreshing tokens and syncing reminders');
        // Refresh deviceId first to ensure all reminders have current token
        FirestoreReminderService.refreshDeviceIdForReminders();
        _syncReminders();
        _checkForDueReminders();
        break;
      case AppLifecycleState.paused:
        // App went to background - scheduled notifications via AlarmManager will still work
        print('📱 App paused');
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call)
        break;
      case AppLifecycleState.detached:
        // App is detached
        break;
      case AppLifecycleState.hidden:
        // App is hidden (Android 14+)
        break;
    }
  }

  /// Check for reminders that should be shown now
  /// This handles cases where scheduled notifications might have been missed
  Future<void> _checkForDueReminders() async {
    try {
      final reminders = await FirestoreReminderService.getActiveReminders();
      final now = DateTime.now();

      for (var reminderData in reminders) {
        final reminderTime = (reminderData['reminderTime'] as Timestamp)
            .toDate();
        final eventStart = (reminderData['eventStart'] as Timestamp).toDate();

        // Check if reminder time has passed but event hasn't started yet
        // This handles cases where the scheduled notification might have been missed
        if (reminderTime.isBefore(now) && eventStart.isAfter(now)) {
          // Reminder time has passed but event hasn't started - show notification now
          final event = Event(
            id: reminderData['eventId'] as String,
            title: reminderData['eventTitle'] as String,
            description: reminderData['eventDescription'] as String?,
            start: eventStart,
            end: reminderData['eventEnd'] != null
                ? (reminderData['eventEnd'] as Timestamp).toDate()
                : null,
            location: reminderData['eventLocation'] as String?,
            tag: '',
            color: 0xFF2196F3,
            isTask: reminderData['eventIsTask'] as bool? ?? false,
          );

          // Show notification immediately (not schedule, since time has passed)
          await NotificationService.showNotification(
            title: 'Recordatorio: ${event.title}',
            body: ReminderService.buildReminderBody(event),
            id: event.id.hashCode,
            eventId: event.id.hashCode,
          );
          print('⏰ Showing missed reminder for event: ${event.id}');

          // Mark reminder as inactive since we've shown it
          await FirestoreReminderService.cancelReminder(eventId: event.id);
        } else if (eventStart.isBefore(now)) {
          // Event has already started - mark reminder as inactive
          await FirestoreReminderService.cancelReminder(
            eventId: reminderData['eventId'] as String,
          );
        }
      }
    } catch (e) {
      print('❌ Error checking for due reminders: $e');
    }
  }

  /// Sync reminders from Firestore and reschedule them
  Future<void> _syncReminders() async {
    try {
      // First, refresh deviceId for all reminders to ensure they have current token
      await FirestoreReminderService.refreshDeviceIdForReminders();

      // Then sync and schedule
      await FirestoreReminderService.syncAndScheduleReminders();
    } catch (e) {
      print('❌ Error syncing reminders: $e');
    }
  }

  /// Manually trigger a sync (can be called from UI)
  Future<void> syncNow() async {
    await _syncReminders();
    await _checkForDueReminders();
  }
}
