import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';
import '../utils/globals.dart';

class EventCard extends StatelessWidget {
  final Event e;
  final VoidCallback? onTap;
  const EventCard({super.key, required this.e, this.onTap});

  @override
  Widget build(BuildContext context) {
    final eventColor = Color(e.color);

    // Create a light version of the event color for background
    final HSLColor hslColor = HSLColor.fromColor(eventColor);
    final Color lightBackground = hslColor
        .withLightness(0.95)
        .withSaturation((hslColor.saturation * 0.3).clamp(0.0, 1.0))
        .toColor();

    // For tasks, apply strikethrough if completed
    final TextStyle
    titleStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: e.isTask && e.completed ? AppColors.black54 : AppColors.black87,
      decoration: e.isTask && e.completed ? TextDecoration.lineThrough : null,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: lightBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: eventColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show checkbox for tasks, color indicator for events
              if (e.isTask)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: Icon(
                    e.completed
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: eventColor,
                    size: 24,
                  ),
                )
              else
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: eventColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: eventColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: titleStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (e.isTask)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: eventColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'TAREA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoChips(eventColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChips(Color eventColor) {
    if (e.isTask) {
      // For tasks, show due date and completion status
      final dueText = e.due != null
          ? DateFormat('d MMM yyyy', 'es_AR').format(e.due!)
          : DateFormat('d MMM yyyy', 'es_AR').format(e.start);

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildChip(Icons.event_outlined, dueText, eventColor),
          if (e.completed)
            _buildChip(Icons.check_circle_outline, 'Completada', eventColor),
        ],
      );
    } else {
      // For events, show time and location
      final time = DateFormat('HH:mm').format(e.start);
      final end = e.end != null
          ? ' - ${DateFormat('HH:mm').format(e.end!)}'
          : '';

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildChip(Icons.access_time, '$time$end', eventColor),
          if (e.location != null && e.location!.isNotEmpty)
            _buildChip(Icons.location_on_outlined, e.location!, eventColor),
        ],
      );
    }
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
