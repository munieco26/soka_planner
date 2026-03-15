import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';
import '../models/notification_item.dart';
import 'notification_storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('ic_stat_icagenda');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    _initialized = true;
  }

  /// Show a simple notification
  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    int? eventId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'agenda_soka_channel',
      'Agenda Soka',
      channelDescription: 'Notificaciones de eventos y actividades',
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

    await _notifications.show(id, title, body, details);

    // Save notification to storage
    final notification = NotificationItem(
      id: 'notification_$id',
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      isRead: false,
      eventId: eventId,
    );
    await NotificationStorageService.addNotification(notification);
  }

  /// Schedule a notification for an event
  static Future<void> scheduleEventNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Only schedule if the time is in the future
    if (scheduledTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'agenda_soka_events',
      'Eventos Soka',
      channelDescription: 'Recordatorios de eventos próximos',
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

    // Note: For scheduling, you'd need to use a scheduling plugin
    // For now, we'll just show immediate notifications
    await _notifications.show(id, title, body, details);
  }
}
