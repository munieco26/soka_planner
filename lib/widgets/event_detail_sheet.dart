import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event.dart';
import '../models/event_attachment.dart';
import '../utils/globals.dart';
import '../services/reminder_service.dart';
import '../services/reminder_preferences_service.dart';
import 'reminder_dialog.dart';

class EventDetailSheet {
  static void show(BuildContext context, Event event) {
    final df = event.isTask
        ? DateFormat('EEEE d MMMM yyyy', 'es_AR')
        : DateFormat('EEEE d MMMM • HH:mm', 'es_AR');

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailContent(event: event, dateFormat: df),
    );
  }
}

class _EventDetailContent extends StatelessWidget {
  final Event event;
  final DateFormat dateFormat;

  const _EventDetailContent({required this.event, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = AppColors.secondary; // fondo pastel neutro
    final accent = AppColors.primary; // azul institucional SGIAR
    final cleanedDescription = _getCleanDescription(event.description);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            // --- drag handle visual
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

            // --- título del evento
            Text(
              event.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // --- fecha y hora
            _buildInfoRow(
              Icons.schedule,
              event.isTask
                  ? 'Vencimiento: ${dateFormat.format(event.due ?? event.start)}'
                  : dateFormat.format(event.start),
              accent,
            ),

            // --- ubicación
            if (event.location?.isNotEmpty == true)
              _buildInfoRow(Icons.place, event.location!, accent),

            // --- descripción
            if (cleanedDescription?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                cleanedDescription!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.black87,
                  height: 1.4,
                ),
              ),
            ],

            if (event.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Adjuntos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: event.attachments
                    .map(
                      (a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          a.isImage ? Icons.image : Icons.attachment,
                          size: 22,
                        ),
                        title: Text(a.title ?? 'Archivo'),
                        onTap: () => _openAttachmentLink(context, a),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),

            // --- acciones
            Row(
              children: [
                // Only show action buttons if event is in the future
                if (_isEventInFuture()) ...[
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
                  if (!event.isTask && event.location?.isNotEmpty == true) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accent.withOpacity(0.6)),
                          foregroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _openMap(context, event.location!),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Mapa'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- helper: check if event is in the future
  bool _isEventInFuture() {
    final now = DateTime.now();
    // For tasks, check due date or start date
    // For events, check start date
    final eventTime = event.isTask ? (event.due ?? event.start) : event.start;

    return eventTime.isAfter(now);
  }

  // --- helper: limpiar descripción removiendo patrones como {color: green}
  String? _getCleanDescription(String? description) {
    if (description == null || description.isEmpty) return null;

    // Remove patterns like {color: green}, {color:blue}, {color: red}, etc.
    // Matches: {color: value} or {color:value} with optional spaces
    final cleaned = description
        .replaceAll(RegExp(r'\{color\s*:\s*\w+\}', caseSensitive: false), '')
        // Also remove any other {key: value} patterns that might exist
        .replaceAll(RegExp(r'\{[^}]+\}'), '')
        .trim();

    return cleaned.isEmpty ? null : cleaned;
  }

  // --- helper: fila de ícono + texto
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

  // --- compartir evento usando el sistema nativo de compartir
  void _shareEvent(BuildContext context) async {
    if (!context.mounted) return;

    try {
      // Prepare share text
      final shareText = _prepareShareText();

      // Use native share sheet on mobile (Android/iOS) and Web Share API on web
      await Share.share(shareText, subject: event.title);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _prepareShareText() {
    final df = DateFormat('EEEE d MMMM yyyy • HH:mm', 'es_AR');
    final dfTask = DateFormat('EEEE d MMMM yyyy', 'es_AR');

    if (event.isTask) {
      return '''
✅ ${event.title}${event.completed ? ' (Completada)' : ''}

📅 Vencimiento: ${dfTask.format(event.due ?? event.start)}
${_getCleanDescription(event.description) != null ? '\n${_getCleanDescription(event.description)}' : ''}

Agenda Soka
''';
    } else {
      return '''
📅 ${event.title}

🕐 ${df.format(event.start)}
${event.location != null && event.location!.isNotEmpty ? '📍 ${event.location}' : ''}
${_getCleanDescription(event.description) != null ? '\n${_getCleanDescription(event.description)}' : ''}

Agenda Soka
''';
    }
  }

  // --- abrir mapa
  void _openMap(BuildContext context, String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedLocation',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se puede abrir Google Maps')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al abrir el mapa')));
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
      final email = result['email'] as String?;
      final phone = result['phone'] as String?;

      try {
        // Schedule reminder
        await ReminderService.scheduleReminder(
          event: event,
          type: reminderType,
          timing: reminderTiming,
          email: email,
          phoneNumber: phone,
        );

        // Save reminder preferences
        await ReminderPreferencesService.saveReminderSettings(
          eventId: event.id,
          type: reminderType,
          timing: reminderTiming,
        );

        // Wait a frame to ensure modal is fully closed, then show success message
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Recordatorio guardado correctamente'),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
      } catch (e) {
        // Wait a frame to ensure modal is fully closed, then show error message
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

  void _openAttachmentLink(BuildContext context, EventAttachment a) async {
    final String? url =
        a.fileUrl ??
        (a.fileId != null
            ? 'https://drive.google.com/file/d/${a.fileId}/view'
            : null);
    if (url == null) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se puede abrir el adjunto')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir el adjunto')),
        );
      }
    }
  }
}
