import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of events for a calendar within a date range
  static Stream<List<Event>> getEvents(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  }) {
    return _firestore
        .collection('calendars')
        .doc(calendarId)
        .collection('events')
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('start')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  /// Get events as a one-time fetch
  static Future<List<Event>> fetchEvents(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _firestore
        .collection('calendars')
        .doc(calendarId)
        .collection('events')
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('start')
        .get();

    return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
  }

  /// Create a new event
  static Future<Event> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required String createdBy,
    String? description,
    DateTime? end,
    String? location,
    int color = 0xFF2196F3,
    bool isAllDay = false,
    bool isPrivate = false,
    List<String> flyerUrls = const [],
  }) async {
    final docRef = await _firestore
        .collection('calendars')
        .doc(calendarId)
        .collection('events')
        .add({
      'title': title,
      'description': description,
      'start': Timestamp.fromDate(start),
      'end': end != null ? Timestamp.fromDate(end) : null,
      'location': location,
      'color': color,
      'isAllDay': isAllDay,
      'calendarId': calendarId,
      'createdBy': createdBy,
      'isPrivate': isPrivate,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'flyerUrls': flyerUrls,
    });

    final doc = await docRef.get();
    return Event.fromFirestore(doc);
  }

  /// Update an existing event
  static Future<void> updateEvent({
    required String calendarId,
    required String eventId,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    String? location,
    int? color,
    bool? isAllDay,
    bool? isPrivate,
    List<String>? flyerUrls,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (start != null) updates['start'] = Timestamp.fromDate(start);
    if (end != null) updates['end'] = Timestamp.fromDate(end);
    if (location != null) updates['location'] = location;
    if (color != null) updates['color'] = color;
    if (isAllDay != null) updates['isAllDay'] = isAllDay;
    if (isPrivate != null) updates['isPrivate'] = isPrivate;
    if (flyerUrls != null) updates['flyerUrls'] = flyerUrls;

    await _firestore
        .collection('calendars')
        .doc(calendarId)
        .collection('events')
        .doc(eventId)
        .update(updates);
  }

  /// Delete an event
  static Future<void> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    await _firestore
        .collection('calendars')
        .doc(calendarId)
        .collection('events')
        .doc(eventId)
        .delete();
  }
}
