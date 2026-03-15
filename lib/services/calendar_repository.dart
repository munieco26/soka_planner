import '../models/event.dart';

abstract class CalendarRepository {
  Future<List<Event>> fetchEvents({
    required DateTime from,
    required DateTime to,
  });
}
