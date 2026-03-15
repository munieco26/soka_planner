import 'event_attachment.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime? end;
  final String? location;
  final String tag;
  final int color;
  final int? textColor;
  final bool isTask;
  final bool completed;
  final DateTime? due;
  // Optional month/year coming from Google Sheets rows
  final int? sheetMonth;
  final int? sheetYear;
  // Optional date range for week-type events from Google Sheets
  final DateTime? from;
  final DateTime? to;
  final List<EventAttachment> attachments;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    this.end,
    this.location,
    required this.tag,
    required this.color,
    this.textColor,
    this.isTask = false,
    this.completed = false,
    this.due,
    this.sheetMonth,
    this.sheetYear,
    this.from,
    this.to,
    this.attachments = const [],
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    String? location,
    String? tag,
    int? color,
    int? textColor,
    bool? isTask,
    bool? completed,
    DateTime? due,
    int? sheetMonth,
    int? sheetYear,
    DateTime? from,
    DateTime? to,
    List<EventAttachment>? attachments,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      tag: tag ?? this.tag,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
      isTask: isTask ?? this.isTask,
      completed: completed ?? this.completed,
      due: due ?? this.due,
      sheetMonth: sheetMonth ?? this.sheetMonth,
      sheetYear: sheetYear ?? this.sheetYear,
      from: from ?? this.from,
      to: to ?? this.to,
      attachments: attachments ?? this.attachments,
    );
  }
}
