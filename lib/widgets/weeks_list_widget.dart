import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event.dart';
import '../utils/globals.dart';

class WeeksListWidget extends StatelessWidget {
  final List<Event> sheetsEvents;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  // When embedded, render non-scrollable content suitable for SingleChildScrollView parents
  final bool embedded;

  const WeeksListWidget({
    super.key,
    required this.sheetsEvents,
    required this.isLoading,
    required this.onRefresh,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final listBuilder = ListView.builder(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 60),
      // +1 for header, +1 more when empty to show the empty message
      itemCount: 1 + (sheetsEvents.isEmpty ? 1 : sheetsEvents.length),
      shrinkWrap: embedded,
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (_, i) {
        // Header at index 0
        if (i == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            margin: const EdgeInsets.only(bottom: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 72, 84, 131),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SEMANA DE',
              style: GoogleFonts.bebasNeue(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: 1.2,
              ),
            ),
          );
        }

        // Empty state just after header
        if (sheetsEvents.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: Text('No hay eventos en Google Sheets')),
          );
        }

        final e = sheetsEvents[i - 1];
        // Use text color from event, default to white if not specified
        final textColor = e.textColor != null
            ? Color(e.textColor!)
            : Colors.white;
        final textColor70 = e.textColor != null
            ? Color(e.textColor!).withOpacity(0.7)
            : Colors.white70;
        final textColor30 = e.textColor != null
            ? Color(e.textColor!).withOpacity(0.3)
            : Colors.white30;

        // Check if this is the current week (today is between from and to dates)
        final bool isCurrentWeek =
            e.tag.toLowerCase() == 'week' &&
            e.from != null &&
            e.to != null &&
            _isDateInRange(DateTime.now(), e.from!, e.to!);

        // Extract footer from description
        String content = e.description ?? '<p>Sin descripción</p>';
        String footer = '';

        // Check if description contains footer pattern (text in parentheses)
        final footerRegex = RegExp(r'\(del\s+\d+.*?\)', caseSensitive: false);
        final footerMatch = footerRegex.firstMatch(content);
        if (footerMatch != null) {
          footer = footerMatch.group(0) ?? '';
          // Remove footer from content
          content = content.replaceAll(footerMatch.group(0) ?? '', '').trim();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isCurrentWeek ? AppColors.amberLight : Color(e.color),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: isCurrentWeek
                ? const BorderSide(color: AppColors.amber, width: 3)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date with footer on the right
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: textColor70, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        footer.isNotEmpty ? footer : '',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: textColor30, height: 16),
                // HTML Content (without footer)
                Html(
                  data: content,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      color: textColor,
                      fontSize: FontSize(12),
                    ),
                    "h2": Style(
                      color: textColor,
                      fontSize: FontSize(14),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 4),
                    ),
                    "h1": Style(
                      color: textColor,
                      fontSize: FontSize(16),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 4),
                    ),
                    "p": Style(
                      color: textColor70,
                      fontSize: FontSize(11),
                      margin: Margins.only(bottom: 4),
                    ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (embedded) {
      // Non-scrollable variant
      return sheetsEvents.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No hay eventos en Google Sheets')),
            )
          : listBuilder;
    }

    // Default: pull-to-refresh scrollable list
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: sheetsEvents.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay eventos en Google Sheets'),
              ),
            )
          : listBuilder,
    );
  }

  /// Check if a date falls within a date range (inclusive)
  bool _isDateInRange(DateTime date, DateTime from, DateTime to) {
    // Normalize dates to midnight for comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedFrom = DateTime(from.year, from.month, from.day);
    final normalizedTo = DateTime(to.year, to.month, to.day);

    return normalizedDate.isAfter(
          normalizedFrom.subtract(const Duration(days: 1)),
        ) &&
        normalizedDate.isBefore(normalizedTo.add(const Duration(days: 1)));
  }
}
