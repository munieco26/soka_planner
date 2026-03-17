import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'notification_storage_service.dart';
import 'firestore_reminder_service.dart';
import '../models/notification_item.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _lastTokenKey = 'last_fcm_token';

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional notification permission');
      } else {
        print('❌ User declined notification permission');
        return;
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        
        // Check if token has changed
        final prefs = await SharedPreferences.getInstance();
        final lastToken = prefs.getString(_lastTokenKey);
        
        if (lastToken != null && lastToken != token) {
          // Token has changed - update all active reminders
          print('🔄 FCM token changed, updating reminders in Firestore');
          await FirestoreReminderService.updateDeviceIdForActiveReminders(
            oldDeviceId: lastToken,
            newDeviceId: token,
          );
        }
        
        // Save current token
        await prefs.setString(_lastTokenKey, token);
        
        // Save token to backend (for admin to send notifications)
        await _saveTokenToBackend(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        print('🔄 New FCM Token received: $newToken');
        
        // Get old token
        final prefs = await SharedPreferences.getInstance();
        final oldToken = prefs.getString(_lastTokenKey);
        
        // Update reminders in Firestore if token changed
        if (oldToken != null && oldToken != newToken) {
          print('🔄 Updating reminders with new FCM token');
          await FirestoreReminderService.updateDeviceIdForActiveReminders(
            oldDeviceId: oldToken,
            newDeviceId: newToken,
          );
        }
        
        // Save new token
        await prefs.setString(_lastTokenKey, newToken);
        
        // Save token to backend
        await _saveTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Check if app was opened from a notification (when app was terminated)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
    }
  }

  static Future<void> _saveTokenToBackend(String? token) async {
    if (token == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save token under user's fcmTokens subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📬 Foreground message: ${message.messageId}');

    // Show local notification
    await NotificationService.showNotification(
      title: message.notification?.title ?? 'Nueva notificación',
      body: message.notification?.body ?? '',
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      eventId: message.data['eventId'] != null
          ? int.tryParse(message.data['eventId'].toString())
          : null,
    );

    // Save to storage
    final notification = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Nueva notificación',
      body: message.notification?.body ?? '',
      receivedAt: DateTime.now(),
      isRead: false,
      eventId: message.data['eventId'] != null
          ? int.tryParse(message.data['eventId'].toString())
          : null,
    );
    await NotificationStorageService.addNotification(notification);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📬 Background message opened app: ${message.messageId}');

    // Save notification to storage
    final notification = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Nueva notificación',
      body: message.notification?.body ?? '',
      receivedAt: DateTime.now(),
      isRead: false,
      eventId: message.data['eventId'] != null
          ? int.tryParse(message.data['eventId'].toString())
          : null,
    );
    await NotificationStorageService.addNotification(notification);

    // Handle navigation or other actions when notification is tapped
    // You can navigate to a specific page based on message.data
  }

  /// Background message handler (must be top-level function)
  /// This runs when app is in background and receives a notification
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('📬 Handling background message: ${message.messageId}');

    // Save notification to storage
    // Note: This runs in an isolate, so we need to ensure SharedPreferences is initialized
    try {
      final notification = NotificationItem(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Nueva notificación',
        body: message.notification?.body ?? '',
        receivedAt: DateTime.now(),
        isRead: false,
        eventId: message.data['eventId'] != null
            ? int.tryParse(message.data['eventId'].toString())
            : null,
      );
      await NotificationStorageService.addNotification(notification);
      print('✅ Background notification saved to storage');
    } catch (e) {
      print('❌ Error saving background notification: $e');
    }
  }
}
