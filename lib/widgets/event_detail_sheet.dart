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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EventDetailPage(
          event: event,
          canEdit: canEdit,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class _EventDetailPage extends StatelessWidget {
  final Event event;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EventDetailPage({
    required this.event,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.primary;
    final df = event.isAllDay
        ? DateFormat('EEEE d MMMM yyyy', 'es_AR')
        : DateFormat('EEEE d MMMM • HH:mm', 'es_AR');

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('Detalle'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.black87,
        elevation: 0,
        actions: [
          if (canEdit && onDelete != null)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete?.call();
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              color: AppColors.error,
            ),
          if (canEdit && onEdit != null)
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
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
            const SizedBox(height: 16),

            // Date/time
            _buildInfoRow(
              Icons.schedule,
              event.isAllDay
                  ? 'Todo el día - ${df.format(event.start)}'
                  : df.format(event.start),
              accent,
            ),

            // Location
            if (event.location?.isNotEmpty == true)
              _buildInfoRow(Icons.place, event.location!, accent),

            // Flyer gallery
            if (event.flyerUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              FlyerGalleryWidget(flyerUrls: event.flyerUrls),
            ],

            const SizedBox(height: 24),

            // Compartir — siempre visible
            SizedBox(
              width: double.infinity,
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
            // Recordar — solo eventos futuros
            if (_isEventInFuture()) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
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
