import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import 'firestore_notification_service.dart';

class NotificationStorageService {
  static const String _key = 'notifications_list';

  /// Get all notifications - Firestore for mobile, local storage for web
  static Future<List<NotificationItem>> getNotifications() async {
    if (kIsWeb) {
      // Web: use local storage
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) return [];

      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList
            .map(
              (json) => NotificationItem.fromJson(json as Map<String, dynamic>),
            )
            .toList()
          ..sort(
            (a, b) => b.receivedAt.compareTo(a.receivedAt),
          );
      } catch (e) {
        return [];
      }
    } else {
      // Mobile: use Firestore
      return await FirestoreNotificationService.getNotifications();
    }
  }

  /// Add a new notification
  static Future<void> addNotification(NotificationItem notification) async {
    if (kIsWeb) {
      // Web: use local storage
      final notifications = await getNotifications();
      notifications.insert(0, notification);
      await _saveNotifications(notifications);
    } else {
      // Mobile: use Firestore
      await FirestoreNotificationService.addNotification(notification);
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    if (kIsWeb) {
      // Web: use local storage
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _saveNotifications(notifications);
      }
    } else {
      // Mobile: use Firestore
      await FirestoreNotificationService.markAsRead(notificationId);
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    if (kIsWeb) {
      // Web: use local storage
      final notifications = await getNotifications();
      final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
      await _saveNotifications(updated);
    } else {
      // Mobile: use Firestore
      await FirestoreNotificationService.markAllAsRead();
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    if (kIsWeb) {
      // Web: use local storage
      final notifications = await getNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotifications(notifications);
    } else {
      // Mobile: use Firestore
      await FirestoreNotificationService.deleteNotification(notificationId);
    }
  }

  /// Clear all notifications
  static Future<void> clearAll() async {
    if (kIsWeb) {
      // Web: use local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } else {
      // Mobile: use Firestore
      await FirestoreNotificationService.clearAll();
    }
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    if (kIsWeb) {
      // Web: use local storage
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } else {
      // Mobile: use Firestore
      return await FirestoreNotificationService.getUnreadCount();
    }
  }

  /// Save notifications to storage (web only)
  static Future<void> _saveNotifications(
    List<NotificationItem> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }
}
