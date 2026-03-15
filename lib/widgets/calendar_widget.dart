import 'package:flutter/material.dart';
import '../models/event.dart';
import '../utils/calendar_view_type.dart';
import 'views/day_view.dart';
import 'views/week_view.dart';
import 'views/month_view.dart';
import 'views/year_view.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<Event> events;
  final Function(DateTime selected, DateTime focused) onDaySelected;
  final Function(DateTime focused) onPageChanged;
  final Function(Event) onEventTap;
  final CalendarViewType viewType;

  const CalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onEventTap,
    required this.viewType,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  @override
  Widget build(BuildContext context) {
    switch (widget.viewType) {
      case CalendarViewType.day:
        return DayView(
          focusedDay: widget.focusedDay,
          selectedDay: widget.selectedDay,
          events: widget.events,
          onDaySelected: widget.onDaySelected,
          onPageChanged: widget.onPageChanged,
          onEventTap: widget.onEventTap,
        );
      case CalendarViewType.week:
        return WeekView(
          focusedDay: widget.focusedDay,
          selectedDay: widget.selectedDay,
          events: widget.events,
          onDaySelected: widget.onDaySelected,
          onPageChanged: widget.onPageChanged,
          onEventTap: widget.onEventTap,
        );
      case CalendarViewType.month:
        return MonthView(
          focusedDay: widget.focusedDay,
          selectedDay: widget.selectedDay,
          events: widget.events,
          onDaySelected: widget.onDaySelected,
          onPageChanged: widget.onPageChanged,
          onEventTap: widget.onEventTap,
        );
      case CalendarViewType.year:
        return YearView(
          focusedDay: widget.focusedDay,
          events: widget.events,
          onPageChanged: widget.onPageChanged,
        );
    }
  }
}
