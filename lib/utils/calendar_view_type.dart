enum CalendarViewType {
  day,
  week,
  month,
  year;

  String get displayName {
    switch (this) {
      case CalendarViewType.day:
        return 'D';
      case CalendarViewType.week:
        return 'S';
      case CalendarViewType.month:
        return 'M';
      case CalendarViewType.year:
        return 'A';
    }
  }
}

