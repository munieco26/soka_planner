import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import 'reminder_service.dart';

class FirestoreReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'reminders';
  static const String _deviceIdKey = 'firestore_device_id';
  static const _uuid = Uuid();

  /// Get deviceId - FCM token for mobile, stored UUID for web
  static Future<String?> _getDeviceId() async {
    try {
      if (kIsWeb) {
        // WEB: usar UUID persistido
        final prefs = await SharedPreferences.getInstance();
        String? deviceId = prefs.getString(_deviceIdKey);

        if (deviceId == null) {
          deviceId = _uuid.v4();
          await prefs.setString(_deviceIdKey, deviceId);
          print('✅ Generated new deviceId for web: $deviceId');
        }

        return deviceId;
      } else {
        // MOBILE: SOLO FCM token real
        final token = await FirebaseMessaging.instance.getToken();
        print('🔥 FCM token obtenido: $token');
        return token; // si es null devolvemos null
      }
    } catch (e) {
      print('❌ Error getting deviceId / FCM token: $e');
      // En móvil NO inventamos UUID, porque rompería FCM
      return null;
    }
  }

  /// Save a reminder to Firestore
  static Future<void> saveReminder({
    required Event event,
    required ReminderType type,
    required ReminderTiming timing,
    required DateTime reminderTime,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) {
        print('⚠️ Cannot save reminder: No deviceId');
        return;
      }

      // Calculate reminder time
      final calculatedReminderTime = _calculateReminderTime(
        event.start,
        timing,
      );

      // Create reminder document
      final reminderData = {
        'deviceId': deviceId,
        'eventId': event.id,
        'eventTitle': event.title,
        'eventDescription': event.description,
        'eventStart': Timestamp.fromDate(event.start),
        'eventEnd': event.end != null ? Timestamp.fromDate(event.end!) : null,
        'eventLocation': event.location,
        'eventIsAllDay': event.isAllDay,
        'reminderType': type.name, // 'push'
        'reminderTiming':
            timing.name, // 'thirtyMinutes', 'oneHour', 'twoHours', etc.
        'reminderTime': Timestamp.fromDate(calculatedReminderTime),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'notificationSent': false,
      };

      // Save to Firestore
      await _firestore.collection(_collection).add(reminderData);
      print('✅ Reminder saved to Firestore for event: ${event.id}');
    } catch (e) {
      print('❌ Error saving reminder to Firestore: $e');
      rethrow;
    }
  }

  /// Calculate reminder time based on event time and timing
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

  /// Update deviceId for all active reminders (when FCM token changes)
  static Future<void> updateDeviceIdForActiveReminders({
    required String oldDeviceId,
    required String newDeviceId,
  }) async {
    try {
      print('🔄 Updating deviceId from $oldDeviceId to $newDeviceId');

      // Find all active reminders with old deviceId
      final snapshot = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: oldDeviceId)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ No active reminders found with old deviceId');
        return;
      }

      // Update all reminders to use new deviceId
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'deviceId': newDeviceId});
      }
      await batch.commit();

      print('✅ Updated ${snapshot.docs.length} reminders with new deviceId');
    } catch (e) {
      print('❌ Error updating deviceId for reminders: $e');
    }
  }

  /// Get all active reminders for current device
  static Future<List<Map<String, dynamic>>> getActiveReminders() async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) {
        print('⚠️ Cannot get reminders: No deviceId');
        return [];
      }

      // Query without orderBy to avoid needing a composite index
      // We'll sort in memory instead
      final snapshot = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: deviceId)
          .where('isActive', isEqualTo: true)
          .get();

      // Convert to list and sort by reminderTime in memory
      final reminders = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by reminderTime (ascending - earliest first)
      reminders.sort((a, b) {
        final aTime = a['reminderTime'] as Timestamp?;
        final bTime = b['reminderTime'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

      return reminders;
    } catch (e) {
      print('❌ Error getting reminders from Firestore: $e');
      return [];
    }
  }

  /// Cancel a reminder (mark as inactive)
  static Future<void> cancelReminder({required String eventId}) async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) {
        print('⚠️ Cannot cancel reminder: No deviceId');
        return;
      }

      // Find and deactivate all reminders for this event on this device
      final snapshot = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: deviceId)
          .where('eventId', isEqualTo: eventId)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();

      print('✅ Cancelled reminders for event: $eventId');
    } catch (e) {
      print('❌ Error cancelling reminder in Firestore: $e');
      rethrow;
    }
  }

  /// Delete old/inactive reminders (cleanup)
  static Future<void> deleteOldReminders({int daysOld = 30}) async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: deviceId)
          .where('isActive', isEqualTo: false)
          .where('reminderTime', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Deleted ${snapshot.docs.length} old reminders');
    } catch (e) {
      print('❌ Error deleting old reminders: $e');
    }
  }

  /// Get current FCM token (for manual refresh)
  static Future<String?> getCurrentFCMToken() async {
    try {
      if (kIsWeb) return null;
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Manually refresh deviceId for all active reminders
  /// This updates reminders that belong to the current device to use the current FCM token
  /// Strategy: Get reminders with current token OR get all and update those that need it
  static Future<void> refreshDeviceIdForReminders() async {
    try {
      // Always get a fresh token
      final currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken == null) {
        print('⚠️ Cannot refresh: No FCM token available');
        return;
      }

      print(
        '🔄 Refreshing deviceId for reminders with current token: ${currentToken.substring(0, 20)}...',
      );

      // Strategy 1: Get reminders that already have current token (these are fine)
      final currentTokenSnapshot = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: currentToken)
          .where('isActive', isEqualTo: true)
          .get();

      print(
        'ℹ️ Found ${currentTokenSnapshot.docs.length} reminders with current token',
      );

      // Strategy 2: Get all active reminders and check which ones need updating
      // We'll update any that don't match current token
      // Note: This might include reminders from other devices, but we'll be conservative
      final allActiveSnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      if (allActiveSnapshot.docs.isEmpty) {
        print('ℹ️ No active reminders to refresh');
        return;
      }

      // Update reminders that don't have current token
      // Only update if they look like they might be from this device (similar format)
      final batch = _firestore.batch();
      int updatedCount = 0;

      for (var doc in allActiveSnapshot.docs) {
        final data = doc.data();
        final deviceId = data['deviceId'] as String?;

        // Update if token is different
        // FCM tokens are long strings, so we update any that don't match
        if (deviceId != null && deviceId != currentToken) {
          // Check if it looks like an FCM token (long string with colons)
          // This helps avoid updating reminders from other devices that use UUIDs
          if (deviceId.length > 50 && deviceId.contains(':')) {
            batch.update(doc.reference, {'deviceId': currentToken});
            updatedCount++;
            print(
              '🔄 Updating reminder ${doc.id} (old token: ${deviceId.substring(0, 20)}...)',
            );
          }
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
        print('✅ Refreshed deviceId for $updatedCount reminders');
      } else {
        print('ℹ️ All reminders already have current deviceId');
      }
    } catch (e) {
      print('❌ Error refreshing deviceId: $e');
    }
  }

  /// Clean up reminders with invalid tokens by marking them inactive
  /// This is a safety measure if tokens can't be updated
  static Future<void> deactivateRemindersWithInvalidTokens() async {
    try {
      final currentToken = await getCurrentFCMToken();
      if (currentToken == null) {
        print('⚠️ Cannot check invalid tokens: No FCM token available');
        return;
      }

      // Get all active reminders
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      // Find reminders with tokens that look invalid (too short, wrong format, etc.)
      final batch = _firestore.batch();
      int deactivatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final deviceId = data['deviceId'] as String?;

        // Check if token looks invalid (FCM tokens are typically long strings)
        // If it's not the current token and looks suspicious, deactivate
        if (deviceId != null &&
            deviceId != currentToken &&
            (deviceId.length < 50 || !deviceId.contains(':'))) {
          // Token looks invalid - deactivate reminder
          batch.update(doc.reference, {'isActive': false});
          deactivatedCount++;
          print('⚠️ Deactivating reminder ${doc.id} with suspicious token');
        }
      }

      if (deactivatedCount > 0) {
        await batch.commit();
        print('⚠️ Deactivated $deactivatedCount reminders with invalid tokens');
      }
    } catch (e) {
      print('❌ Error deactivating reminders with invalid tokens: $e');
    }
  }

  /// Sync reminders from Firestore and schedule local notifications
  static Future<void> syncAndScheduleReminders() async {
    try {
      final reminders = await getActiveReminders();
      print('📥 Syncing ${reminders.length} reminders from Firestore');

      for (var reminderData in reminders) {
        final reminderTime = (reminderData['reminderTime'] as Timestamp)
            .toDate();
        final eventStart = (reminderData['eventStart'] as Timestamp).toDate();

        // Only schedule if reminder time is in the future
        if (reminderTime.isAfter(DateTime.now())) {
          // Reconstruct event from reminder data
          final event = Event(
            id: reminderData['eventId'] as String,
            title: reminderData['eventTitle'] as String,
            description: reminderData['eventDescription'] as String?,
            start: eventStart,
            end: reminderData['eventEnd'] != null
                ? (reminderData['eventEnd'] as Timestamp).toDate()
                : null,
            location: reminderData['eventLocation'] as String?,
            color: 0xFF2196F3,
            calendarId: reminderData['calendarId'] as String? ?? '',
            createdBy: '',
            isAllDay: reminderData['eventIsAllDay'] as bool? ?? false,
          );

          // Schedule local notification
          await ReminderService.schedulePushNotification(event, reminderTime);
          print('✅ Synced reminder for event: ${event.id}');
        } 
      }
    } catch (e) {
      print('❌ Error syncing reminders: $e');
    }
  }
}
