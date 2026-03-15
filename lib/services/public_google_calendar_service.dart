import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/event.dart';
import '../models/event_attachment.dart';
import 'calendar_repository.dart';

/// Service to fetch public Google Calendar events without CORS issues
class PublicGoogleCalendarService implements CalendarRepository {
  final String _calendarId;
  final String _apiKey;

  PublicGoogleCalendarService({
    String? calendarId,
    String? apiKey,
  })  : _calendarId = calendarId ?? AppConfig.defaultCalendarId,
        _apiKey = apiKey ?? AppConfig.googleCalendarApiKey;

  @override
  Future<List<Event>> fetchEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    print('📅 Cargando eventos del calendario...');

    // Fetch calendar events
    final calendarEvents = await _fetchCalendarEvents(from: from, to: to);
    print('✅ Eventos del calendario: ${calendarEvents.length}');

    // Sort by start date
    calendarEvents.sort((a, b) => a.start.compareTo(b.start));

    print('📊 Total de eventos a mostrar: ${calendarEvents.length}');
    return calendarEvents;
  }

  /// Fetch calendar events
  Future<List<Event>> _fetchCalendarEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    final timeMin = Uri.encodeQueryComponent(from.toUtc().toIso8601String());
    final timeMax = Uri.encodeQueryComponent(to.toUtc().toIso8601String());

    final url = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/$_calendarId/events'
      '?key=$_apiKey'
      '&singleEvents=true'
      '&orderBy=startTime'
      '&timeMin=$timeMin'
      '&timeMax=$timeMax'
      '&maxResults=250',
    );

    try {
      final res = await http.get(url);

      if (res.statusCode != 200) {
        throw Exception('Calendar API error: ${res.statusCode}\n${res.body}');
      }

      final data = json.decode(res.body);
      final items = (data['items'] as List?) ?? [];
      final events = items.map((item) => _mapToEvent(item)).toList();
      return events;
    } catch (e) {
      // Return empty list if calendar fetch fails, but log the error
      print('Error fetching calendar events: $e');
      return [];
    }
  }

  Event _mapToEvent(Map<String, dynamic> item) {
    // Parse start and end times
    final startData = item['start'];
    final endData = item['end'];

    DateTime startTime;
    DateTime? endTime;

    if (startData['dateTime'] != null) {
      // Timed event
      startTime = DateTime.parse(startData['dateTime']).toLocal();
      endTime = endData != null && endData['dateTime'] != null
          ? DateTime.parse(endData['dateTime']).toLocal()
          : null;
    } else if (startData['date'] != null) {
      // All-day event
      startTime = DateTime.parse(startData['date']);
      endTime = endData != null && endData['date'] != null
          ? DateTime.parse(endData['date'])
          : null;
    } else {
      startTime = DateTime.now();
      endTime = null;
    }

    // Get event summary
    final summary = item['summary'] as String?;

    // Get event color from description or colorId
    final description = item['description'] as String?;
    int color = _getColorFromId(item['colorId']);

    // Try to extract color from description (format: {color:green})
    if (description != null && description.contains('color:')) {
      final colorMatch = RegExp(r'color:\s*(\w+)').firstMatch(description);
      if (colorMatch != null) {
        final colorName = colorMatch.group(1)?.toLowerCase();
        color = _getColorFromName(colorName) ?? color;
      }
    }

    // Extract tag from extended properties or leave empty
    String tag = '';
    if (item['extendedProperties'] != null) {
      final shared = item['extendedProperties']['shared'];
      if (shared != null && shared['tag'] != null) {
        tag = shared['tag'] as String;
      }
    }

    // Parse attachments if any
    final List<EventAttachment> attachments =
        ((item['attachments'] as List?)
            ?.map((a) => EventAttachment.fromJson(a as Map<String, dynamic>))
            .toList()) ??
        const [];

    return Event(
      id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: summary ?? 'Sin título',
      description: item['description'] as String?,
      start: startTime,
      end: endTime,
      location: item['location'] as String?,
      tag: tag,
      color: color,
      attachments: attachments,
    );
  }

  /// Map Google Calendar color IDs to actual colors
  /// Reference: https://developers.google.com/calendar/api/v3/reference/colors
  int _getColorFromId(String? colorId) {
    switch (colorId) {
      case '1':
        return 0xFFC5CAE9; // Lavender → Azul lavanda suave
      case '2':
        return 0xFFA5D6A7; // Sage → Verde menta pastel
      case '3':
        return 0xFFCE93D8; // Grape → Violeta claro
      case '4':
        return 0xFFF8BBD0; // Flamingo → Rosa suave
      case '5':
        return 0xFFFFF59D; // Banana → Amarillo pastel
      case '6':
        return 0xFFFFCC80; // Tangerine → Naranja cálido claro
      case '7':
        return 0xFF90CAF9; // Peacock → Azul celeste institucional
      case '8':
        return 0xFFBDBDBD; // Graphite → Gris neutro
      case '9':
        return 0xFF9FA8DA; // Blueberry → Azul índigo claro
      case '10':
        return 0xFF80CBC4; // Basil → Verde agua suave
      case '11':
        return 0xFFEF9A9A; // Tomato → Rojo rosado tenue
      default:
        return 0xFF90CAF9; // Default Peacock soft blue
    }
  }

  /// Map color names from description to actual colors
  int? _getColorFromName(String? colorName) {
    if (colorName == null) return null;

    switch (colorName.toLowerCase()) {
      case 'green':
        return 0xFFA5D6A7; // Pastel Green — armonía, esperanza
      case 'blue':
        return 0xFF90CAF9; // Pastel Blue — serenidad, institucional
      case 'red':
        return 0xFFEF9A9A; // Soft Red — energía positiva, pasión
      case 'yellow':
        return 0xFFFFF59D; // Light Yellow — alegría, conmemoraciones
      case 'orange':
        return 0xFFFFCC80; // Warm Orange — dinamismo, eventos especiales
      case 'purple':
        return 0xFFCE93D8; // Light Purple — cooperación, unidad
      case 'pink':
        return 0xFFF8BBD0; // Soft Pink — amabilidad, gratitud
      case 'cyan':
        return 0xFF80DEEA; // Aqua Light — frescura, apertura
      case 'teal':
        return 0xFF80CBC4; // Calm Teal — equilibrio, serenidad interior
      case 'lime':
        return 0xFFE6EE9C; // Lime Pastel — renovación, crecimiento
      case 'indigo':
        return 0xFF9FA8DA; // Indigo Soft — confianza, inspiración
      case 'brown':
        return 0xFFBCAAA4; // Warm Brown — raíz, memoria, conexión humana
      case 'gray':
        return 0xFFBDBDBD; // Neutral Grey — soporte / sin categoría
      default:
        return null;
    }
  }
}
