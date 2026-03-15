import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PermissionService {
  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    // Check if already granted
    final currentStatus = await Permission.notification.status;
    if (currentStatus.isGranted) {
      return true;
    }

    // 1. Request the normal permission
    final status = await Permission.notification.request();

    // 2. Request explicit permission from the plugin (Android)
    final plugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await plugin?.requestNotificationsPermission();

    return status.isGranted;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    // Check if already granted
    final currentPermission = await Geolocator.checkPermission();
    if (currentPermission == LocationPermission.always ||
        currentPermission == LocationPermission.whileInUse) {
      return true;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, return false
      return false;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request exact alarms permission (Android 13+)
  static Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await androidPlugin?.requestExactAlarmsPermission() ?? false;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Open app settings
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
