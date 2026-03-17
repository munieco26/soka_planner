import 'package:flutter/material.dart';
import '../../../models/event.dart';
import '../../../utils/globals.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final List<Event> events;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;
  final AnimationController pulseController;
  final Function(DateTime selected, DateTime focused) onDaySelected;
  final Function(Event) onEventTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.events,
    required this.isSelected,
    required this.isToday,
    required this.isOutside,
    required this.pulseController,
    required this.onDaySelected,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool mobile = isMobile(context);

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final double pulse = 0.5 + (0.5 * pulseController.value); // 0.5..1.0
        final Color animatedBorderColor = AppColors.amber.withOpacity(
          isSelected ? pulse : 0.0,
        );

        return Container(
          margin: mobile ? const EdgeInsets.all(2) : const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isOutside
                ? AppColors.backgroundOutsideDay
                : AppColors.secondary, // background
            borderRadius: BorderRadius.circular(8), // 0.5rem ≈ 8px
            border: isSelected
                ? Border.all(color: animatedBorderColor, width: 3)
                : null,
          ),
          child: InkWell(
            onTap: events.isNotEmpty
                ? () {
                    onDaySelected(day, day);
                    // If there's only one event, show it directly
                    if (events.length == 1) {
                      onEventTap(events.first);
                    }
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.blue, width: 2),
                    )
                  : isToday
                  ? BoxDecoration(
                      color: AppColors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.amber, width: 2),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day number
                  Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.blue
                            : isToday
                            ? AppColors.black87
                            : AppColors.black87,
                      ),
                    ),
                  ),
                  // Event titles (from Google Calendar only)
                  if (events.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: events.length > 3 ? 3 : events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final displayMaxLines = events.length >= 3
                              ? 1
                              : (events.length == 2 ? 2 : 3);
                          final bgColor = Color(event.color);
                          final bool darkBg = bgColor.computeLuminance() < 0.5;
                          final Color fgColor = darkBg
                              ? AppColors.white
                              : AppColors.textDark;
                          return InkWell(
                            onTap: () => onEventTap(event),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (event.flyerUrls.isNotEmpty) ...[
                                    Icon(Icons.image, size: 12, color: fgColor),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: fgColor,
                                      ),
                                      maxLines: displayMaxLines,
                                      softWrap: displayMaxLines > 1,
                                      overflow: displayMaxLines > 1
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (events.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 2),
                        child: Text(
                          '+${events.length - 3} más',
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


