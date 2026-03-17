import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:ui';
import '../models/event.dart';
import 'notification_storage_service.dart';
import '../models/notification_item.dart';
import 'firestore_reminder_service.dart';

enum ReminderType {
  push, // In-app notification
  email, // Email reminder (disabled for now)
  sms, // SMS reminder (disabled for now)
}

enum ReminderTiming {
  thirtyMinutes, // 30 minutes before
  oneHour, // 1 hour before
  twoHours, // 2 hours before
  fourHours, // 4 hours before
  eightHours, // 8 hours before
  twelveHours, // 12 hours before
  oneDay, // 1 day before
}

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize timezone data
  static Future<void> initialize() async {
    try {
      // Initialize timezone database
      // Note: timezone package doesn't require explicit initialization in newer versions
      // Try to set Argentina timezone, fallback to system local
      try {
        tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
      } catch (e) {
        // If timezone data not available, use UTC
        print('Warning: Could not set Argentina timezone, using UTC: $e');
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      print('Warning: Timezone initialization error: $e');
      // Continue without timezone initialization
    }
  }

  /// Schedule a reminder for an event
  static Future<void> scheduleReminder({
    required Event event,
    required ReminderType type,
    required ReminderTiming timing,
    String? email,
    String? phoneNumber,
  }) async {
    final reminderTime = _calculateReminderTime(event.start, timing);

    switch (type) {
      case ReminderType.push:
        // Schedule local notification
        await schedulePushNotification(event, reminderTime);
        // Save to Firestore
        try {
          await FirestoreReminderService.saveReminder(
            event: event,
            type: type,
            timing: timing,
            reminderTime: reminderTime,
          );
        } catch (e) {
          print('⚠️ Failed to save reminder to Firestore: $e');
          // Continue even if Firestore save fails
        }
        break;
      case ReminderType.email:
        // Email reminders are disabled for now
        throw UnimplementedError('Email reminders are currently disabled');
      case ReminderType.sms:
        // SMS reminders are disabled for now
        throw UnimplementedError('SMS reminders are currently disabled');
    }
  }

  static DateTime _calculateReminderTime(
    DateTime eventTime,
    ReminderTiming timing,
  ) {
    switch (timing) {
      case ReminderTiming.thirtyMinutes:
        return eventTime.subtract(const Duration(minutes: 30));
      case ReminderTiming.oneHour:
        return eventTime.subtract(const Duration(hours: 1));
      case ReminderTiming.twoHours:
        return eventTime.subtract(const Duration(hours: 2));
      case ReminderTiming.fourHours:
        return eventTime.subtract(const Duration(hours: 4));
      case ReminderTiming.eightHours:
        return eventTime.subtract(const Duration(hours: 8));
      case ReminderTiming.twelveHours:
        return eventTime.subtract(const Duration(hours: 12));
      case ReminderTiming.oneDay:
        return eventTime.subtract(const Duration(days: 1));
    }
  }

  /// Schedule a push notification (public for FirestoreReminderService)
  static Future<void> schedulePushNotification(
    Event event,
    DateTime reminderTime,
  ) async {
    if (reminderTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Recordatorios de Eventos',
      channelDescription: 'Notificaciones de recordatorios de eventos',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_icagenda',
      color: const Color(0xFF0175C2), // Notification icon background color
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Convert DateTime to TZDateTime
      final tzDateTime = tz.TZDateTime.from(reminderTime, tz.local);

      // Try exact scheduling first, fallback to inexact if permission not granted
      try {
        await _notifications.zonedSchedule(
          event.id.hashCode,
          'Recordatorio: ${event.title}',
          buildReminderBody(event),
          tzDateTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        // If exact alarms not permitted, fallback to inexact scheduling
        if (e.toString().contains('exact_alarms_not_permitted')) {
          print('⚠️ Exact alarms not permitted, using inexact scheduling');
          await _notifications.zonedSchedule(
            event.id.hashCode,
            'Recordatorio: ${event.title}',
            buildReminderBody(event),
            tzDateTime,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } else {
          rethrow;
        }
      }

      // Save reminder notification to storage
      final notification = NotificationItem(
        id: 'reminder_${event.id}_${reminderTime.millisecondsSinceEpoch}',
        title: 'Recordatorio: ${event.title}',
        body: buildReminderBody(event),
        receivedAt: DateTime.now(),
        isRead: false,
        eventId: event.id.hashCode,
      );
      await NotificationStorageService.addNotification(notification);
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  static String buildReminderBody(Event event) {
    final location = event.location != null && event.location!.isNotEmpty
        ? '\n📍 ${event.location}'
        : '';
    final time = event.isAllDay
        ? ''
        : '\n${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}';
    return '${event.title}$time$location';
  }

  // Email and SMS reminder methods are disabled for now
  // Uncomment when ready to re-enable these features

  // static Future<void> _scheduleEmailReminder(
  //   Event event,
  //   DateTime reminderTime,
  //   String? email,
  // ) async {
  //   if (email == null || reminderTime.isBefore(DateTime.now())) return;

  //   // Store reminder request - this should be sent to your backend
  //   // The backend will send the email at the scheduled time
  //   await _sendReminderRequestToBackend(
  //     event: event,
  //     type: ReminderType.email,
  //     scheduledTime: reminderTime,
  //     contact: email,
  //   );
  // }

  // static Future<void> _scheduleSmsReminder(
  //   Event event,
  //   DateTime reminderTime,
  //   String? phoneNumber,
  // ) async {
  //   if (phoneNumber == null || reminderTime.isBefore(DateTime.now())) return;

  //   // Store reminder request - this should be sent to your backend
  //   await _sendReminderRequestToBackend(
  //     event: event,
  //     type: ReminderType.sms,
  //     scheduledTime: reminderTime,
  //     contact: phoneNumber,
  //   );
  // }

  // static Future<void> _sendReminderRequestToBackend({
  //   required Event event,
  //   required ReminderType type,
  //   required DateTime scheduledTime,
  //   required String contact,
  // }) async {
  //   // TODO: Implement API call to your backend
  //   // This should store the reminder request in your database
  //   // Your backend will handle sending email/SMS at the scheduled time
  //   print(
  //     'Reminder request: $type for event ${event.id} at $scheduledTime to $contact',
  //   );

  //   // For now, save locally as a notification item
  //   final notification = NotificationItem(
  //     id: 'reminder_${type.name}_${event.id}_${scheduledTime.millisecondsSinceEpoch}',
  //     title: 'Recordatorio programado: ${event.title}',
  //     body:
  //         'Se enviará un recordatorio por ${type.name} a $contact el ${scheduledTime.toString()}',
  //     receivedAt: DateTime.now(),
  //     isRead: false,
  //     eventId: event.id.hashCode,
  //   );
  //   await NotificationStorageService.addNotification(notification);
  // }

  /// Cancel a scheduled reminder
  static Future<void> cancelReminder(Event event) async {
    // Cancel local notification
    await _notifications.cancel(event.id.hashCode);

    // Cancel in Firestore
    try {
      await FirestoreReminderService.cancelReminder(eventId: event.id);
    } catch (e) {
      print('⚠️ Failed to cancel reminder in Firestore: $e');
      // Continue even if Firestore cancel fails
    }
  }
}
