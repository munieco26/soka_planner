import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../utils/globals.dart';

class DayCellBuilder {
  static Widget buildDayCell({
    required BuildContext context,
    required DateTime day,
    required List<Event> events,
    required bool isSelected,
    required bool isToday,
    required Function(DateTime selected, DateTime focused) onDaySelected,
    required Function(Event) onEventTap,
    bool isOutside = false,
    AnimationController? pulseController,
  }) {
    final bool mobile = isMobile(context);

    Widget cellContent = _buildCellContent(
      context: context,
      day: day,
      events: events,
      isSelected: isSelected,
      isToday: isToday,
      isOutside: isOutside,
      mobile: mobile,
      onDaySelected: onDaySelected,
      onEventTap: onEventTap,
    );

    // Wrap with animation if controller provided
    if (pulseController != null) {
      return AnimatedBuilder(
        animation: pulseController,
        builder: (context, _) {
          final double pulse = 0.5 + (0.5 * pulseController.value);
          final Color animatedBorderColor = AppColors.amber.withOpacity(
            isSelected ? pulse : 0.0,
          );

          return Container(
            margin: mobile
                ? const EdgeInsets.all(1)
                : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isOutside
                  ? AppColors.backgroundOutsideDay
                  : AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: animatedBorderColor, width: 3)
                  : null,
            ),
            child: cellContent,
          );
        },
      );
    }

    return Container(
      margin: mobile
          ? const EdgeInsets.all(1)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isOutside ? AppColors.backgroundOutsideDay : AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppColors.amber, width: 3)
            : null,
      ),
      child: cellContent,
    );
  }

  static Widget _buildCellContent({
    required BuildContext context,
    required DateTime day,
    required List<Event> events,
    required bool isSelected,
    required bool isToday,
    required bool isOutside,
    required bool mobile,
    required Function(DateTime selected, DateTime focused) onDaySelected,
    required Function(Event) onEventTap,
  }) {
    return InkWell(
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
        padding: EdgeInsets.all(mobile ? 4 : 10),
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
          mainAxisSize: MainAxisSize.max,
          children: [
            // Day number
            Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: mobile ? 12 : 16,
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
              SizedBox(height: mobile ? 2 : 4),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: mobile
                      ? (events.length > 2 ? 2 : events.length)
                      : (events.length > 4 ? 4 : events.length),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final maxEvents = mobile ? 2 : 4;
                    final displayMaxLines = events.length >= maxEvents
                        ? 1
                        : (events.length == 2
                              ? 2
                              : (events.length == 1 ? 2 : 1));
                    final bgColor = Color(event.color);
                    final bool darkBg = bgColor.computeLuminance() < 0.5;
                    final Color fgColor = darkBg
                        ? AppColors.white
                        : AppColors.textDark;
                    return InkWell(
                      onTap: () => onEventTap(event),
                      child: Container(
                        margin: EdgeInsets.only(bottom: mobile ? 2 : 3),
                        padding: EdgeInsets.symmetric(
                          horizontal: mobile ? 3 : 6,
                          vertical: mobile ? 1 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (event.attachments.isNotEmpty) ...[
                              _SmallAttachmentIcon(event, fgColor),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: mobile ? 9 : 11,
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
              if ((mobile && events.length > 2) ||
                  (!mobile && events.length > 4))
                Padding(
                  padding: EdgeInsets.only(
                    left: mobile ? 3 : 6,
                    top: mobile ? 1 : 2,
                  ),
                  child: Text(
                    '+${events.length - (mobile ? 2 : 4)} más',
                    style: TextStyle(
                      fontSize: mobile ? 7 : 9,
                      color: AppColors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmallAttachmentIcon extends StatelessWidget {
  final Event event;
  final Color color;
  const _SmallAttachmentIcon(this.event, this.color);

  @override
  Widget build(BuildContext context) {
    // Check if there's an image attachment
    bool hasImage = false;
    for (final a in event.attachments) {
      if (a.mimeType?.startsWith('image/') ?? false) {
        hasImage = true;
        break;
      }
    }

    // Show appropriate icon based on attachment type
    // Note: We don't load iconLink from Google Drive due to CORS restrictions in web browsers
    if (hasImage) {
      return const Icon(Icons.image, size: 12, color: AppColors.textDark);
    }

    return Icon(Icons.attachment, size: 12, color: color);
  }
}
