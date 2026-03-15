import 'package:flutter/material.dart';
import '../../models/event.dart';
import 'agenda_view_base.dart';

class WeekView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<Event> events;
  final Function(DateTime selected, DateTime focused) onDaySelected;
  final Function(DateTime focused) onPageChanged;
  final Function(Event) onEventTap;

  const WeekView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    // Week view - get the week containing focusedDay
    final weekStart = focusedDay.subtract(
      Duration(days: focusedDay.weekday % 7),
    );
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return AgendaViewBase(
      days: days,
      events: events,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onEventTap: onEventTap,
    );
  }
}

