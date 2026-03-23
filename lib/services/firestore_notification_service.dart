import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_item.dart';

/// Lectura/escritura de la colección `notifications` (solo servidor crea docs;
/// el cliente marca leído / borra).
class FirestoreNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static NotificationItem _fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final received = data['receivedAt'];
    DateTime at;
    if (received is Timestamp) {
      at = received.toDate();
    } else {
      at = DateTime.now();
    }
    final rawEvent = data['eventId'];
    String? eventIdStr;
    if (rawEvent != null) {
      eventIdStr = rawEvent is String ? rawEvent : rawEvent.toString();
    }
    return NotificationItem(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      receivedAt: at,
      isRead: data['isRead'] as bool? ?? false,
      type: data['type'] as String?,
      calendarId: data['calendarId'] as String?,
      eventId: eventIdStr,
    );
  }

  /// Notificaciones del usuario actual (`userId` en el documento).
  static Future<List<NotificationItem>> getNotifications() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: uid)
            .orderBy('receivedAt', descending: true)
            .limit(100)
            .get();
      } catch (_) {
        snapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: uid)
            .limit(100)
            .get();
      }

      final list = snapshot.docs.map(_fromDoc).toList();
      list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (_) {}
  }

  static Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .limit(500)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: uid)
          .limit(500)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  static Future<int> getUnreadCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .limit(200)
          .get();

      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }
}
