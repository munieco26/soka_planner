import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event.dart';
import '../../utils/globals.dart';

class YearView extends StatelessWidget {
  final DateTime focusedDay;
  final List<Event> events;
  final Function(DateTime focused) onPageChanged;

  const YearView({
    super.key,
    required this.focusedDay,
    required this.events,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool mobile = isMobile(context);
    final currentYear = focusedDay.year;
    final months = List.generate(12, (index) => index + 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: mobile ? 3 : 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: mobile ? 1.2 : 1.3,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = months[index];
        final monthDate = DateTime(currentYear, month, 1);
        final monthEvents = events.where((e) {
          return e.start.year == currentYear && e.start.month == month;
        }).toList();

        return InkWell(
          onTap: () {
            onPageChanged(monthDate);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: month == DateTime.now().month &&
                        currentYear == DateTime.now().year
                    ? AppColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM', 'es_AR').format(monthDate).toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: mobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${monthEvents.length}',
                  style: TextStyle(
                    fontSize: mobile ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: monthEvents.isNotEmpty
                        ? AppColors.primary
                        : AppColors.black54,
                  ),
                ),
                Text(
                  monthEvents.length == 1 ? 'evento' : 'eventos',
                  style: TextStyle(
                    fontSize: mobile ? 9 : 10,
                    color: AppColors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

