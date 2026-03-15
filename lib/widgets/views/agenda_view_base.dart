import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event.dart';
import '../../utils/globals.dart';

class AgendaViewBase extends StatelessWidget {
  final List<DateTime> days;
  final List<Event> events;
  final DateTime? selectedDay;
  final Function(DateTime selected, DateTime focused) onDaySelected;
  final Function(Event) onEventTap;

  const AgendaViewBase({
    super.key,
    required this.days,
    required this.events,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool mobile = isMobile(context);

    // Hours to display (6 AM to 11 PM)
    final hours = List.generate(18, (i) => 6 + i); // 6:00 to 23:00

    // Calculate hour height (adjust based on screen size)
    final hourHeight = mobile ? 60.0 : 80.0;
    final timeColumnWidth = mobile ? 50.0 : 60.0;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          // Day headers
          Container(
            margin: EdgeInsets.only(left: timeColumnWidth),
            child: Row(
              children: days.map((day) {
                final isSelected =
                    selectedDay != null && isSameDay(day, selectedDay);
                final isToday = isSameDay(day, DateTime.now());

                return Expanded(
                  child: InkWell(
                    onTap: () => onDaySelected(day, day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.secondary,
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : (isToday
                                      ? AppColors.amber
                                      : Colors.transparent),
                            width: isSelected ? 3 : (isToday ? 2 : 0),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            [
                              'DOM',
                              'LUN',
                              'MAR',
                              'MIE',
                              'JUE',
                              'VIE',
                              'SÁB',
                            ][day.weekday % 7],
                            style: TextStyle(
                              fontSize: mobile ? 12 : 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: mobile ? 16 : 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Time grid
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: hours.length * hourHeight,
              child: Stack(
                children: [
                  // Hour labels on the left
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: timeColumnWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        children: hours.map((hour) {
                          return Container(
                            height: hourHeight,
                            padding: const EdgeInsets.only(right: 8),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.black54.withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                fontSize: mobile ? 11 : 12,
                                color: AppColors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Day columns
                  Positioned(
                    left: timeColumnWidth,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      children: days.map((day) {
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border(
                                right: BorderSide(
                                  color: AppColors.black54.withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Hour dividers
                                ...hours.map((hour) {
                                  return Positioned(
                                    left: 0,
                                    right: 0,
                                    top: (hour - hours.first) * hourHeight,
                                    height: hourHeight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AppColors.black54
                                                .withOpacity(0.2),
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                // Events for this day
                                ..._buildEventsForDay(day, hours, hourHeight),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventsForDay(
    DateTime day,
    List<int> hours,
    double hourHeight,
  ) {
    // Get events for this day
    final dayEvents = events.where((e) {
      return e.start.year == day.year &&
          e.start.month == day.month &&
          e.start.day == day.day;
    }).toList()..sort((a, b) => a.start.compareTo(b.start));

    return dayEvents.map((event) {
      final startHour = event.start.hour + (event.start.minute / 60.0);
      final endHour = event.end != null
          ? event.end!.hour + (event.end!.minute / 60.0)
          : startHour + 1.0; // Default 1 hour if no end time

      // Calculate position and height
      final top = (startHour - hours.first) * hourHeight;
      final height = (endHour - startHour) * hourHeight;

      // Skip if event is outside visible hours
      if (startHour < hours.first || startHour > hours.last + 1) {
        return const SizedBox.shrink();
      }

      final bgColor = Color(event.color);
      final bool darkBg = bgColor.computeLuminance() < 0.5;
      final Color fgColor = darkBg ? AppColors.white : AppColors.textDark;

      return Positioned(
        left: 2,
        right: 2,
        top: top,
        height: height.clamp(20.0, double.infinity),
        child: InkWell(
          onTap: () => onEventTap(event),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: bgColor.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(event.start),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
