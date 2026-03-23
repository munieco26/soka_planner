import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_item.dart';
import 'firestore_notification_service.dart';

/// Bandeja de notificaciones: Firestore cuando hay sesión (misma fuente en todas las plataformas).
/// Las Cloud Functions crean los documentos; el cliente no puede hacer `create` en reglas.
class NotificationStorageService {
  static User? get _user => FirebaseAuth.instance.currentUser;

  static Future<List<NotificationItem>> getNotifications() async {
    if (_user != null) {
      return FirestoreNotificationService.getNotifications();
    }
    return [];
  }

  /// Reservado para pruebas locales; con sesión activa la bandeja viene del servidor.
  static Future<void> addNotification(NotificationItem notification) async {
    if (_user == null) return;
    // No escribimos en Firestore: `notifications` solo Admin SDK.
  }

  static Future<void> markAsRead(String notificationId) async {
    if (_user != null) {
      await FirestoreNotificationService.markAsRead(notificationId);
    }
  }

  static Future<void> markAllAsRead() async {
    if (_user != null) {
      await FirestoreNotificationService.markAllAsRead();
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    if (_user != null) {
      await FirestoreNotificationService.deleteNotification(notificationId);
    }
  }

  static Future<void> clearAll() async {
    if (_user != null) {
      await FirestoreNotificationService.clearAll();
    }
  }

  static Future<int> getUnreadCount() async {
    if (_user != null) {
      return FirestoreNotificationService.getUnreadCount();
    }
    return 0;
  }
}
