/// Entrada de bandeja (Firestore `notifications` + datos en FCM).
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  /// Tipo lógico: `member_joined`, `event_created`, etc.
  final String? type;
  final String? calendarId;
  /// ID del documento del evento en Firestore (string).
  final String? eventId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.type,
    this.calendarId,
    this.eventId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? receivedAt,
    bool? isRead,
    String? type,
    String? calendarId,
    String? eventId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      calendarId: calendarId ?? this.calendarId,
      eventId: eventId ?? this.eventId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'receivedAt': receivedAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'calendarId': calendarId,
      'eventId': eventId,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] as String?,
      calendarId: json['calendarId'] as String?,
      eventId: _parseEventId(json['eventId']),
    );
  }

  static String? _parseEventId(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is int) return v.toString();
    return v.toString();
  }
}
