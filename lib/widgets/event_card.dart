import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    final TextStyle titleStyle =
        Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.black87,
            );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: lightBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: eventColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flyer poster header
            if (e.flyerUrls.isNotEmpty)
              CachedNetworkImage(
                imageUrl: e.flyerUrls.first,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: eventColor.withOpacity(0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text(
                          e.title,
                          style: titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoChips(eventColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChips(Color eventColor) {
    if (e.isAllDay) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildChip(Icons.event_outlined, 'Todo el día', eventColor),
          if (e.location != null && e.location!.isNotEmpty)
            _buildChip(Icons.location_on_outlined, e.location!, eventColor),
        ],
      );
    }

    final time = DateFormat('HH:mm').format(e.start);
    final end =
        e.end != null ? ' - ${DateFormat('HH:mm').format(e.end!)}' : '';

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
