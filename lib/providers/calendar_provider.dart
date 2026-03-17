import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/calendar_model.dart';
import '../models/event.dart';
import '../models/member_model.dart';
import '../services/calendar_service.dart';
import '../services/event_service.dart';

class CalendarProvider extends ChangeNotifier {
  List<CalendarModel> _calendars = [];
  CalendarModel? _selectedCalendar;
  List<Event> _events = [];
  MemberRole? _currentUserRole;
  bool _isLoading = false;
  String? _uid;
  StreamSubscription? _calendarsSub;
  StreamSubscription? _eventsSub;

  List<CalendarModel> get calendars => _calendars;
  CalendarModel? get selectedCalendar => _selectedCalendar;
  List<Event> get events => _events;
  MemberRole? get currentUserRole => _currentUserRole;
  bool get isLoading => _isLoading;
  bool get hasCalendars => _calendars.isNotEmpty;

  bool get canEdit =>
      _currentUserRole == MemberRole.owner ||
      _currentUserRole == MemberRole.editor;

  /// Initialize with user UID
  void init(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _calendarsSub?.cancel();

    _calendarsSub =
        CalendarService.getUserCalendars(uid).listen((calendars) {
      _calendars = calendars;

      // Auto-select first calendar if none selected
      if (_selectedCalendar == null && calendars.isNotEmpty) {
        selectCalendar(calendars.first);
      } else if (_selectedCalendar != null) {
        // Update selected calendar if it changed
        final updated = calendars
            .where((c) => c.id == _selectedCalendar!.id)
            .firstOrNull;
        if (updated != null) {
          _selectedCalendar = updated;
        } else if (calendars.isNotEmpty) {
          selectCalendar(calendars.first);
        } else {
          _selectedCalendar = null;
        }
      }

      notifyListeners();
    });
  }

  /// Select a calendar and load its events
  void selectCalendar(CalendarModel calendar) {
    _selectedCalendar = calendar;
    _loadUserRole(calendar.id);
    notifyListeners();
  }

  /// Load events for the selected calendar within a date range
  void loadEvents({required DateTime from, required DateTime to}) {
    if (_selectedCalendar == null) return;

    _eventsSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _eventsSub = EventService.getEvents(
      _selectedCalendar!.id,
      from: from,
      to: to,
    ).listen((events) {
      _events = events;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserRole(String calendarId) async {
    if (_uid == null) return;
    _currentUserRole =
        await CalendarService.getUserRole(calendarId, _uid!);
    notifyListeners();
  }

  /// Clear state on sign out
  void clear() {
    _calendarsSub?.cancel();
    _eventsSub?.cancel();
    _calendars = [];
    _selectedCalendar = null;
    _events = [];
    _currentUserRole = null;
    _uid = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _calendarsSub?.cancel();
    _eventsSub?.cancel();
    super.dispose();
  }
}
