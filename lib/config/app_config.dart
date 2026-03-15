/// Centralized application configuration
/// Contains API keys, IDs, and other configuration values
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // Google API Keys
  static const String googleApiKey = 'AIzaSyAQg6Kc-nVDg1ueYRuqX1V7b5QW6OpSgc0';
  static const String googleCalendarApiKey =
      'AIzaSyBJn86gIPzamEW3MQUrVQOh3bqJ0SJ8q_I';

  // Google Calendar Configuration
  static const String defaultCalendarId = 'desarrollo.sgiar@gmail.com';
  static const String developmentCalendarId = 'desarrollo.sgiar@gmail.com';

  // Google Sheets Configuration
  static const String spreadsheetId =
      '1teLs8FZKQgTjmrrMo-nGFw7oxoop3f67UdMjJaQPQ4U';
  static const String sheetName = 'semanas';
}
