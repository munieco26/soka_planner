import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event.dart';
import '../../utils/globals.dart';
import 'day_cell_builder.dart';

class MonthView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<Event> events;
  final Function(DateTime selected, DateTime focused) onDaySelected;
  final Function(DateTime focused) onPageChanged;
  final Function(Event) onEventTap;

  const MonthView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onEventTap,
  });

  List<Event> _eventsForDay(DateTime day) {
    return events
        .where(
          (e) =>
              e.start.year == day.year &&
              e.start.month == day.month &&
              e.start.day == day.day,
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = isMobile(context);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(),
      child: TableCalendar<Event>(
        locale: 'es_AR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2032, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(day, selectedDay),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        eventLoader: _eventsForDay,
        calendarFormat: CalendarFormat.month,
        calendarBuilders: CalendarBuilders<Event>(
          // Days-of-week header tiles with background and uppercase labels
          dowBuilder: (context, day) {
            final weekday = [
              'DOM',
              'LUN',
              'MAR',
              'MIE',
              'JUE',
              'VIE',
              'SÁB',
            ][day.weekday % 7];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              margin: mobile
                  ? EdgeInsets.symmetric(horizontal: 2)
                  : EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Text(
                weekday,
                style: GoogleFonts.bebasNeue(
                  color: AppColors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: 1.0,
                ),
              ),
            );
          },
          outsideBuilder: (context, day, focusedDay) {
            final events = _eventsForDay(day);
            return DayCellBuilder.buildDayCell(
              context: context,
              day: day,
              events: events,
              isSelected: false,
              isToday: false,
              isOutside: true,
              onDaySelected: onDaySelected,
              onEventTap: onEventTap,
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            final events = _eventsForDay(day);
            return DayCellBuilder.buildDayCell(
              context: context,
              day: day,
              events: events,
              isSelected: false,
              isToday: false,
              onDaySelected: onDaySelected,
              onEventTap: onEventTap,
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            final events = _eventsForDay(day);
            return DayCellBuilder.buildDayCell(
              context: context,
              day: day,
              events: events,
              isSelected: true,
              isToday: false,
              onDaySelected: onDaySelected,
              onEventTap: onEventTap,
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final events = _eventsForDay(day);
            return DayCellBuilder.buildDayCell(
              context: context,
              day: day,
              events: events,
              isSelected: false,
              isToday: true,
              onDaySelected: onDaySelected,
              onEventTap: onEventTap,
            );
          },
        ),
        headerStyle: HeaderStyle(
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: AppColors.white,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: AppColors.white,
          ),
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.bebasNeue(
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: 1.0,
            fontSize: 24,
          ),
          titleTextFormatter: (date, locale) =>
              DateFormat.yMMMM(locale).format(date).toUpperCase(),
          headerPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          headerMargin: mobile
              ? const EdgeInsets.only(top: 0, bottom: 6, left: 0, right: 0)
              : const EdgeInsets.only(top: 0, bottom: 6, left: 5, right: 5),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        calendarStyle: CalendarStyle(
          cellPadding: const EdgeInsets.all(0),
          // Remove default decorations since we're using custom builders
          todayDecoration: const BoxDecoration(),
          selectedDecoration: const BoxDecoration(),
          defaultDecoration: const BoxDecoration(),
          // Remove event markers (dots/circles)
          markersMaxCount: 0,
          canMarkersOverflow: false,
        ),
        daysOfWeekHeight: mobile ? 30 : 40,
        rowHeight: mobile
            ? 80
            : 140, // Responsive height: mobile compact, desktop expanded
      ),
    );
  }
}
