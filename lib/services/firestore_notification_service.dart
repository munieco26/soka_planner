import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/notification_item.dart';

class FirestoreNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Get deviceId - FCM token for mobile, stored UUID for web
  static Future<String?> _getDeviceId() async {
    try {
      if (kIsWeb) {
        // For web, we'd need to get the stored UUID
        // This should match the logic in FirestoreReminderService
        return null; // Web uses local storage
      } else {
        // For mobile, use FCM token
        final token = await FirebaseMessaging.instance.getToken();
        return token;
      }
    } catch (e) {
      print('❌ Error getting deviceId for notifications: $e');
      return null;
    }
  }

  /// Get all notifications for current device from Firestore
  static Future<List<NotificationItem>> getNotifications() async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) return [];

      QuerySnapshot snapshot;
      try {
        // Try with orderBy first (requires composite index)
        snapshot = await _firestore
            .collection(_collection)
            .where('deviceId', isEqualTo: deviceId)
            .orderBy('receivedAt', descending: true)
            .get();
      } catch (e) {
        // If index doesn't exist, get without orderBy and sort in memory
        print('⚠️ Firestore index not found, sorting in memory: $e');
        snapshot = await _firestore
            .collection(_collection)
            .where('deviceId', isEqualTo: deviceId)
            .get();
      }

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NotificationItem(
          id: doc.id,
          title: data['title'] as String,
          body: data['body'] as String,
          receivedAt: (data['receivedAt'] as Timestamp).toDate(),
          isRead: data['isRead'] as bool? ?? false,
          eventId: data['eventId'] as int?,
        );
      }).toList();

      // Sort by receivedAt descending (most recent first)
      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      return notifications;
    } catch (e) {
      print('❌ Error getting notifications from Firestore: $e');
      return [];
    }
  }

  /// Add a notification to Firestore
  static Future<void> addNotification(NotificationItem notification) async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) {
        print('⚠️ Cannot save notification: No deviceId');
        return;
      }

      await _firestore.collection(_collection).doc(notification.id).set({
        'deviceId': deviceId,
        'title': notification.title,
        'body': notification.body,
        'receivedAt': Timestamp.fromDate(notification.receivedAt),
        'isRead': notification.isRead,
        'eventId': notification.eventId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification saved to Firestore: ${notification.id}');
    } catch (e) {
      print('❌ Error saving notification to Firestore: $e');
    }
  }

  /// Mark notification as read in Firestore
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read in Firestore
  static Future<void> markAllAsRead() async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) return;

      final snapshot = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: deviceId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification from Firestore
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Clear all notifications for current device
  static Future<void> clearAll() async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) return;

      final snapshot = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: deviceId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// Get unread count from Firestore
  static Future<int> getUnreadCount() async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) return 0;

      final snapshot = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: deviceId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }
}

