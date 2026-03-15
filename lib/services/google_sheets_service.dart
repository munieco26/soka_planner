import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/event.dart';

class GoogleSheetsService {
  static const String _apiKey = AppConfig.googleApiKey;
  static const String _spreadsheetId = AppConfig.spreadsheetId;
  static const String _sheetName = AppConfig.sheetName;

  /// Fetches events from Google Sheets
  Future<List<Event>> fetchEvents() async {
    try {
      // Construct the Google Sheets API URL
      // This fetches all data from the specified range
      final url = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId/values/$_sheetName?key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rows = data['values'] ?? [];

        print('📊 Google Sheets Response: ${rows.length} total rows');

        // Skip the header row (first row)
        if (rows.isEmpty || rows.length <= 1) {
          print('⚠️ No data rows found (only header or empty)');
          return [];
        }

        print('🔍 Processing ${rows.length - 1} data rows...');
        final events = _parseRows(rows.sublist(1));
        print('✅ Successfully parsed ${events.length} events');
        return events;
      } else {
        throw Exception(
          'Failed to load events: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching events from Google Sheets: $e');
      rethrow;
    }
  }

  /// Parses rows from the spreadsheet into Event objects
  List<Event> _parseRows(List<dynamic> rows) {
    final List<Event> events = [];
    int skippedRows = 0;

    for (var i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        // Skip empty rows
        if (row.isEmpty) {
          skippedRows++;
          continue;
        }

        // Parse row data
        // Columns: id, event_type, content, footer, color (typography), background (card color), file, month, year
        final id = row.length > 0 ? row[0].toString() : '';
        final eventType = row.length > 1 ? row[1].toString() : 'week';
        final content = row.length > 2 ? row[2].toString() : '';
        final footer = row.length > 3 ? row[3].toString() : '';
        final typographyColor = row.length > 4
            ? row[4].toString()
            : '#FFFFFF'; // E column - text color
        final background = row.length > 5
            ? row[5].toString()
            : '#E0E0E0'; // F column - card background
        // row[6] is an optional file/link we don't currently use
        final monthStr = row.length > 7 ? row[7].toString() : '';
        final yearStr = row.length > 8 ? row[8].toString() : '';
        final fromStr = row.length > 9
            ? row[9].toString()
            : ''; // Column J - from date (DD/MM/YYYY)
        final toStr = row.length > 10
            ? row[10].toString()
            : ''; // Column K - to date (DD/MM/YYYY)

        int? sheetMonth;
        int? sheetYear;
        try {
          if (monthStr.isNotEmpty) {
            sheetMonth = int.tryParse(monthStr);
          }
          if (yearStr.isNotEmpty) {
            sheetYear = int.tryParse(yearStr);
          }
        } catch (_) {}

        // Parse from and to dates (only for week-type events)
        DateTime? fromDate;
        DateTime? toDate;
        if (eventType.toLowerCase() == 'week') {
          try {
            if (fromStr.isNotEmpty) {
              // Parse DD/MM/YYYY format
              final fromParts = fromStr.split('/');
              if (fromParts.length == 3) {
                final day = int.parse(fromParts[0]);
                final month = int.parse(fromParts[1]);
                final year = int.parse(fromParts[2]);
                fromDate = DateTime(year, month, day);
              }
            }
            if (toStr.isNotEmpty) {
              // Parse DD/MM/YYYY format
              final toParts = toStr.split('/');
              if (toParts.length == 3) {
                final day = int.parse(toParts[0]);
                final month = int.parse(toParts[1]);
                final year = int.parse(toParts[2]);
                toDate = DateTime(year, month, day);
              }
            }
          } catch (e) {
            print('Error parsing from/to dates: $e');
          }
        }

        // Skip if essential data is missing
        if (id.isEmpty) {
          print('⚠️ Row ${i + 2} skipped: id is empty');
          skippedRows++;
          continue;
        }

        print(
          '✓ Row ${i + 2}: id=$id, type=$eventType, bg=$background, text=$typographyColor',
        );

        // For week events without specific dates, use the current date
        // This ensures they always show up
        final DateTime startDate = DateTime.now();

        // Parse the background color from hex string (card color)
        int color = 0xFFE0E0E0; // Default gray
        if (background.isNotEmpty) {
          try {
            String colorStr = background.replaceAll('#', '');
            if (colorStr.length == 6) {
              color = int.parse('FF$colorStr', radix: 16);
            }
          } catch (e) {
            print('Error parsing background color: $e');
          }
        }

        // Parse the typography color from hex string (text color)
        int? textColor;
        if (typographyColor.isNotEmpty && typographyColor != '#ffffff') {
          try {
            String colorStr = typographyColor.replaceAll('#', '');
            if (colorStr.length == 6) {
              textColor = int.parse('FF$colorStr', radix: 16);
            }
          } catch (e) {
            print('Error parsing text color: $e');
          }
        }

        // Extract title from content (first h2 tag)
        String title = _extractTitle(content);

        // Build description with all content
        String description = _buildDescription(content, footer);

        final event = Event(
          id: id,
          title: title,
          description: description,
          start: startDate,
          end: null,
          location: null,
          tag: eventType,
          color: color,
          textColor: textColor,
          sheetMonth: sheetMonth,
          sheetYear: sheetYear,
          from: fromDate,
          to: toDate,
        );

        events.add(event);
      } catch (e) {
        print('❌ Error parsing row ${i + 2}: $e');
        skippedRows++;
        continue;
      }
    }

    print(
      '📋 Parse complete: ${events.length} events created, $skippedRows rows skipped',
    );
    return events;
  }

  /// Extracts the title from HTML content (first h2 tag)
  String _extractTitle(String content) {
    if (content.isEmpty) return 'Sin título';

    // Try to extract first h2 tag
    final h2Regex = RegExp(r'<h2>(.*?)</h2>', caseSensitive: false);
    final match = h2Regex.firstMatch(content);

    if (match != null && match.groupCount > 0) {
      return _stripHtmlTags(match.group(1) ?? '');
    }

    // Fallback: strip all HTML and take first line
    final stripped = _stripHtmlTags(content);
    final firstLine = stripped.split('\n').first.trim();
    return firstLine.isEmpty ? 'Sin título' : firstLine;
  }

  /// Builds a complete description from content and footer (keeps HTML)
  String _buildDescription(String content, String footer) {
    final parts = <String>[];

    if (content.isNotEmpty) {
      parts.add(content); // Keep HTML tags for rendering
    }

    if (footer.isNotEmpty) {
      parts.add(
        '<p style="margin-top:8px; font-size:10px; opacity:0.8;">$footer</p>',
      );
    }

    return parts.join('\n');
  }

  /// Removes HTML tags from a string
  String _stripHtmlTags(String html) {
    if (html.isEmpty) return '';

    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
