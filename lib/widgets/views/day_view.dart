import 'package:flutter/material.dart';
import '../../models/event.dart';
import 'agenda_view_base.dart';

class DayView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<Event> events;
  final Function(DateTime selected, DateTime focused) onDaySelected;
  final Function(DateTime focused) onPageChanged;
  final Function(Event) onEventTap;

  const DayView({
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
    // Single day view
    final day = selectedDay ?? focusedDay;
    final days = [day];

    return AgendaViewBase(
      days: days,
      events: events,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onEventTap: onEventTap,
    );
  }
}

