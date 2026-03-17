import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_model.dart';
import '../models/member_model.dart';
import '../config/app_config.dart';

class CalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'calendars';

  /// Stream of calendars for a user
  static Stream<List<CalendarModel>> getUserCalendars(String uid) {
    return _firestore
        .collection(_collection)
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarModel.fromFirestore(doc))
            .toList());
  }

  /// Create a new calendar
  static Future<CalendarModel> createCalendar({
    required String name,
    required String ownerId,
    required int color,
    String? description,
  }) async {
    final code = _generateCode();

    final docRef = await _firestore.collection(_collection).add({
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'code': code,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
      'memberUids': [ownerId],
    });

    // Add owner as member
    await docRef.collection('members').doc(ownerId).set({
      'role': MemberRole.owner.name,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return CalendarModel.fromFirestore(doc);
  }

  /// Update calendar details
  static Future<void> updateCalendar({
    required String calendarId,
    String? name,
    String? description,
    int? color,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (color != null) updates['color'] = color;

    if (updates.isNotEmpty) {
      await _firestore.collection(_collection).doc(calendarId).update(updates);
    }
  }

  /// Delete a calendar
  static Future<void> deleteCalendar(String calendarId) async {
    // Delete all events
    final events = await _firestore
        .collection(_collection)
        .doc(calendarId)
        .collection('events')
        .get();
    for (final doc in events.docs) {
      await doc.reference.delete();
    }

    // Delete all members
    final members = await _firestore
        .collection(_collection)
        .doc(calendarId)
        .collection('members')
        .get();
    for (final doc in members.docs) {
      await doc.reference.delete();
    }

    // Delete calendar
    await _firestore.collection(_collection).doc(calendarId).delete();
  }

  /// Join a calendar by invite code
  static Future<CalendarModel?> joinCalendar({
    required String code,
    required String uid,
    String? displayName,
    String? email,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final calendarId = doc.id;

    // Add user to memberUids
    await _firestore.collection(_collection).doc(calendarId).update({
      'memberUids': FieldValue.arrayUnion([uid]),
    });

    // Add member doc
    await _firestore
        .collection(_collection)
        .doc(calendarId)
        .collection('members')
        .doc(uid)
        .set({
      'role': MemberRole.viewer.name,
      'joinedAt': FieldValue.serverTimestamp(),
      'displayName': displayName,
      'email': email,
    });

    final updatedDoc =
        await _firestore.collection(_collection).doc(calendarId).get();
    return CalendarModel.fromFirestore(updatedDoc);
  }

  /// Regenerate invite code
  static Future<String> regenerateCode(String calendarId) async {
    final newCode = _generateCode();
    await _firestore
        .collection(_collection)
        .doc(calendarId)
        .update({'code': newCode});
    return newCode;
  }

  /// Get members of a calendar
  static Future<List<MemberModel>> getMembers(String calendarId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(calendarId)
        .collection('members')
        .get();

    return snapshot.docs
        .map((doc) => MemberModel.fromFirestore(doc))
        .toList();
  }

  /// Stream members of a calendar
  static Stream<List<MemberModel>> getMembersStream(String calendarId) {
    return _firestore
        .collection(_collection)
        .doc(calendarId)
        .collection('members')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MemberModel.fromFirestore(doc)).toList());
  }

  /// Update member role
  static Future<void> updateMemberRole({
    required String calendarId,
    required String uid,
    required MemberRole role,
  }) async {
    await _firestore
        .collection(_collection)
        .doc(calendarId)
        .collection('members')
        .doc(uid)
        .update({'role': role.name});
  }

  /// Remove member from calendar
  static Future<void> removeMember({
    required String calendarId,
    required String uid,
  }) async {
    // Remove from members subcollection
    await _firestore
        .collection(_collection)
        .doc(calendarId)
        .collection('members')
        .doc(uid)
        .delete();

    // Remove from memberUids array
    await _firestore.collection(_collection).doc(calendarId).update({
      'memberUids': FieldValue.arrayRemove([uid]),
    });
  }

  /// Get user's role in a calendar
  static Future<MemberRole?> getUserRole(
      String calendarId, String uid) async {
    final doc = await _firestore
        .collection(_collection)
        .doc(calendarId)
        .collection('members')
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    final data = doc.data()!;
    return MemberRole.values.firstWhere(
      (r) => r.name == (data['role'] as String? ?? 'viewer'),
      orElse: () => MemberRole.viewer,
    );
  }

  /// Find calendar by code (for preview before joining)
  static Future<CalendarModel?> findByCode(String code) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CalendarModel.fromFirestore(snapshot.docs.first);
  }

  /// Generate a random 6-character invite code
  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      AppConfig.inviteCodeLength,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
