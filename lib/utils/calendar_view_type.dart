enum CalendarViewType {
  day,
  week,
  month,
  year;

  String get displayName {
    switch (this) {
      case CalendarViewType.day:
        return 'Día';
      case CalendarViewType.week:
        return 'Semana';
      case CalendarViewType.month:
        return 'Mes';
      case CalendarViewType.year:
        return 'Año';
    }
  }
}

