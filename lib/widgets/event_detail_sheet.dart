import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event.dart';
import '../utils/globals.dart';
import '../services/reminder_service.dart';
import '../services/reminder_preferences_service.dart';
import 'reminder_dialog.dart';
import 'flyer_gallery_widget.dart';

class EventDetailSheet {
  static void show(BuildContext context, Event event,
      {bool canEdit = false, VoidCallback? onEdit, VoidCallback? onDelete}) {
    final df = event.isAllDay
        ? DateFormat('EEEE d MMMM yyyy', 'es_AR')
        : DateFormat('EEEE d MMMM • HH:mm', 'es_AR');

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailContent(
        event: event,
        dateFormat: df,
        canEdit: canEdit,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}

class _EventDetailContent extends StatelessWidget {
  final Event event;
  final DateFormat dateFormat;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EventDetailContent({
    required this.event,
    required this.dateFormat,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = AppColors.secondary;
    final accent = AppColors.primary;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.black54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title + edit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.black87,
                        ),
                      ),
                      if (event.isPrivate) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Evento privado · solo quien lo creó puede editarlo o borrarlo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canEdit)
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit?.call();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    color: accent,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Date/time
            _buildInfoRow(
              Icons.schedule,
              event.isAllDay
                  ? 'Todo el día - ${dateFormat.format(event.start)}'
                  : dateFormat.format(event.start),
              accent,
            ),

            // Location
            if (event.location?.isNotEmpty == true)
              _buildInfoRow(Icons.place, event.location!, accent),

            // Description
            if (event.description?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                event.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.black87,
                  height: 1.4,
                ),
              ),
            ],

            // Flyer gallery
            if (event.flyerUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              FlyerGalleryWidget(flyerUrls: event.flyerUrls),
            ],

            const SizedBox(height: 20),

            // Actions
            if (_isEventInFuture())
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _shareEvent(context),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Compartir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent.withOpacity(0.6)),
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showReminderDialog(context),
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('Recordar'),
                    ),
                  ),
                ],
              ),
            if (canEdit && onDelete != null) ...[
              if (_isEventInFuture()) const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar evento'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isEventInFuture() {
    return event.start.isAfter(DateTime.now());
  }

  Widget _buildInfoRow(IconData icon, String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent.withOpacity(0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareEvent(BuildContext context) async {
    if (!context.mounted) return;
    try {
      final df = DateFormat('EEEE d MMMM yyyy • HH:mm', 'es_AR');
      final text = '''
${event.title}

${df.format(event.start)}
${event.location != null && event.location!.isNotEmpty ? event.location! : ''}
${event.description ?? ''}

Soka Planner
''';
      await Share.share(text.trim(), subject: event.title);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e')),
        );
      }
    }
  }

  void _showReminderDialog(BuildContext context) async {
    if (!context.mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReminderDialog(event: event),
    );

    if (result != null && context.mounted) {
      final reminderType = result['type'] as ReminderType;
      final reminderTiming = result['timing'] as ReminderTiming;

      try {
        await ReminderService.scheduleReminder(
          event: event,
          type: reminderType,
          timing: reminderTiming,
        );

        await ReminderPreferencesService.saveReminderSettings(
          eventId: event.id,
          type: reminderType,
          timing: reminderTiming,
        );

        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Recordatorio guardado correctamente'),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
      } catch (e) {
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al configurar recordatorio: $e'),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
      }
    }
  }
}
