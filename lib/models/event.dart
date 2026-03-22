import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime? end;
  final String? location;
  final int color;
  final int? textColor;
  final bool isAllDay;
  final String calendarId;
  final String createdBy;
  /// Solo el creador puede editar si es true; cualquier miembro del calendario si es false.
  final bool isPrivate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> flyerUrls;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    this.end,
    this.location,
    required this.color,
    this.textColor,
    this.isAllDay = false,
    required this.calendarId,
    required this.createdBy,
    this.isPrivate = false,
    this.createdAt,
    this.updatedAt,
    this.flyerUrls = const [],
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      start: (data['start'] as Timestamp).toDate(),
      end: data['end'] != null ? (data['end'] as Timestamp).toDate() : null,
      location: data['location'] as String?,
      color: data['color'] as int? ?? 0xFF2196F3,
      textColor: data['textColor'] as int?,
      isAllDay: data['isAllDay'] as bool? ?? false,
      calendarId: data['calendarId'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      isPrivate: data['isPrivate'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      flyerUrls: List<String>.from(data['flyerUrls'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'start': Timestamp.fromDate(start),
      'end': end != null ? Timestamp.fromDate(end!) : null,
      'location': location,
      'color': color,
      'textColor': textColor,
      'isAllDay': isAllDay,
      'calendarId': calendarId,
      'createdBy': createdBy,
      'isPrivate': isPrivate,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'flyerUrls': flyerUrls,
    };
  }

  /// Cualquier miembro del calendario puede editar salvo [isPrivate] (solo [createdBy]).
  bool canBeEditedBy(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    if (!isPrivate) return true;
    return createdBy.isNotEmpty && createdBy == uid;
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    String? location,
    int? color,
    int? textColor,
    bool? isAllDay,
    String? calendarId,
    String? createdBy,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? flyerUrls,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
      isAllDay: isAllDay ?? this.isAllDay,
      calendarId: calendarId ?? this.calendarId,
      createdBy: createdBy ?? this.createdBy,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      flyerUrls: flyerUrls ?? this.flyerUrls,
    );
  }
}
