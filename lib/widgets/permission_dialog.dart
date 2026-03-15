import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import '../utils/globals.dart';

class PermissionDialog extends StatefulWidget {
  const PermissionDialog({super.key});

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _requesting = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  /// Check current permission status
  Future<void> _checkCurrentPermissions() async {
    final notificationGranted =
        await PermissionService.isNotificationPermissionGranted();
    final locationGranted =
        await PermissionService.isLocationPermissionGranted();

    setState(() {
      _notificationGranted = notificationGranted;
      _locationGranted = locationGranted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Image.asset('web/icons/Icon-192.png', height: 32, width: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bienvenido a Agenda Soka',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para brindarte una mejor experiencia, necesitamos tu permiso para:',
            style: TextStyle(fontSize: 14, color: AppColors.black87),
          ),
          const SizedBox(height: 20),
          _buildPermissionItem(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            description: 'Te avisaremos sobre próximos eventos y actividades',
            granted: _notificationGranted,
          ),
          const SizedBox(height: 16),
          _buildPermissionItem(
            icon: Icons.location_on_outlined,
            title: 'Ubicación',
            description: 'Para mostrarte eventos cercanos a ti',
            granted: _locationGranted,
          ),
        ],
      ),
      actions: [
        if (!_loading) ...[
          TextButton(
            onPressed: _requesting
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: Text('Ahora no', style: TextStyle(color: AppColors.black87)),
          ),
          FilledButton.icon(
            onPressed: _requesting || (_notificationGranted && _locationGranted)
                ? null
                : _requestPermissions,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            icon: _requesting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                : (_notificationGranted && _locationGranted)
                ? const Icon(Icons.check_circle)
                : const Icon(Icons.check),
            label: Text(
              _requesting
                  ? 'Solicitando...'
                  : (_notificationGranted && _locationGranted)
                  ? 'Completado'
                  : 'Permitir',
            ),
          ),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: granted
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            granted ? Icons.check_circle : icon,
            color: granted
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.7),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: AppColors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);

    // Only request notification permission if not already granted
    if (!_notificationGranted) {
      final notificationGranted =
          await PermissionService.requestNotificationPermission();
      setState(() => _notificationGranted = notificationGranted);

      // Request exact alarms permission (Android 13+) - this is optional
      // Don't block notification permission if exact alarms are denied
      await PermissionService.requestExactAlarmPermission();

      // Initialize notification service if granted
      if (notificationGranted) {
        await NotificationService.initialize();
      }

      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Only request location permission if not already granted
    if (!_locationGranted) {
      final locationGranted =
          await PermissionService.requestLocationPermission();
      setState(() => _locationGranted = locationGranted);
    }

    setState(() => _requesting = false);

    // Small delay before closing to show final state
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pop({
        'notifications': _notificationGranted,
        'location': _locationGranted,
      });
    }
  }
}
