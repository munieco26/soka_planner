class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  final int? eventId; // Optional: link to an event

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.eventId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? receivedAt,
    bool? isRead,
    int? eventId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
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
      eventId: json['eventId'] as int?,
    );
  }
}
