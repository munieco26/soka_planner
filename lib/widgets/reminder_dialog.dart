import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/reminder_service.dart';
import '../services/reminder_preferences_service.dart';
import '../utils/globals.dart';

class ReminderDialog extends StatefulWidget {
  final Event event;

  const ReminderDialog({super.key, required this.event});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  ReminderType _selectedType = ReminderType.push;
  ReminderTiming _selectedTiming = ReminderTiming.oneHour;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  /// Load saved reminder settings for this event
  Future<void> _loadSavedSettings() async {
    final saved = await ReminderPreferencesService.loadReminderSettings(
      widget.event.id,
    );

    if (saved != null && mounted) {
      setState(() {
        _selectedType = saved['type'] as ReminderType;
        _selectedTiming = saved['timing'] as ReminderTiming;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurar Recordatorio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),

            // Reminder type selection
            Text(
              'Tipo de recordatorio',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ReminderType>(
              segments: const [
                ButtonSegment(
                  value: ReminderType.push,
                  label: Text('Notificación'),
                  icon: Icon(Icons.notifications),
                ),
                ButtonSegment(
                  value: ReminderType.email,
                  label: Text('Email'),
                  icon: Icon(Icons.email),
                  enabled: false, // Disabled for now
                ),
                ButtonSegment(
                  value: ReminderType.sms,
                  label: Text('SMS'),
                  icon: Icon(Icons.message),
                  enabled: false, // Disabled for now
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<ReminderType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),

            const SizedBox(height: 20),

            // Timing selection
            Text(
              'Cuándo recordar',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReminderTiming>(
              initialValue: _selectedTiming,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                  value: ReminderTiming.thirtyMinutes,
                  child: Text('30 minutos antes'),
                ),
                DropdownMenuItem(
                  value: ReminderTiming.oneHour,
                  child: Text('1 hora antes'),
                ),
                DropdownMenuItem(
                  value: ReminderTiming.twoHours,
                  child: Text('2 horas antes'),
                ),
                DropdownMenuItem(
                  value: ReminderTiming.fourHours,
                  child: Text('4 horas antes'),
                ),
                DropdownMenuItem(
                  value: ReminderTiming.eightHours,
                  child: Text('8 horas antes'),
                ),
                DropdownMenuItem(
                  value: ReminderTiming.twelveHours,
                  child: Text('12 horas antes'),
                ),
                DropdownMenuItem(
                  value: ReminderTiming.oneDay,
                  child: Text('1 día antes'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTiming = value;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'type': _selectedType,
                        'timing': _selectedTiming,
                        'email': null,
                        'phone': null,
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
