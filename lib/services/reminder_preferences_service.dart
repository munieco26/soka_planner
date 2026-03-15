import 'package:shared_preferences/shared_preferences.dart';
import 'reminder_service.dart';

class ReminderPreferencesService {
  static const String _prefix = 'reminder_pref_';

  /// Get reminder settings key for an event
  static String _getKey(String eventId) => '$_prefix$eventId';

  /// Save reminder settings for an event
  static Future<void> saveReminderSettings({
    required String eventId,
    required ReminderType type,
    required ReminderTiming timing,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(eventId);
      
      await prefs.setString('${key}_type', type.name);
      await prefs.setString('${key}_timing', timing.name);
      
      print('✅ Saved reminder preferences for event: $eventId');
    } catch (e) {
      print('❌ Error saving reminder preferences: $e');
    }
  }

  /// Load reminder settings for an event
  static Future<Map<String, dynamic>?> loadReminderSettings(
    String eventId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(eventId);
      
      final typeString = prefs.getString('${key}_type');
      final timingString = prefs.getString('${key}_timing');
      
      if (typeString == null || timingString == null) {
        return null;
      }

      // Parse ReminderType
      ReminderType? type;
      try {
        type = ReminderType.values.firstWhere(
          (e) => e.name == typeString,
        );
      } catch (e) {
        print('⚠️ Invalid reminder type: $typeString');
        return null;
      }

      // Parse ReminderTiming
      ReminderTiming? timing;
      try {
        timing = ReminderTiming.values.firstWhere(
          (e) => e.name == timingString,
        );
      } catch (e) {
        print('⚠️ Invalid reminder timing: $timingString');
        return null;
      }

      return {
        'type': type,
        'timing': timing,
      };
    } catch (e) {
      print('❌ Error loading reminder preferences: $e');
      return null;
    }
  }

  /// Delete reminder settings for an event
  static Future<void> deleteReminderSettings(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(eventId);
      
      await prefs.remove('${key}_type');
      await prefs.remove('${key}_timing');
      
      print('✅ Deleted reminder preferences for event: $eventId');
    } catch (e) {
      print('❌ Error deleting reminder preferences: $e');
    }
  }
}

