import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/calendar_model.dart';
import '../models/member_model.dart';
import '../providers/auth_provider.dart';
import '../services/calendar_service.dart';
import '../utils/globals.dart';
import '../widgets/member_list_widget.dart';
import '../widgets/invite_code_widget.dart';
import '../widgets/color_picker_widget.dart';

class CalendarSettingsPage extends StatefulWidget {
  final CalendarModel calendar;

  const CalendarSettingsPage({super.key, required this.calendar});

  @override
  State<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late int _color;
  late String _code;
  bool _isSaving = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.calendar.name);
    _descriptionController =
        TextEditingController(text: widget.calendar.description ?? '');
    _color = widget.calendar.color;
    _code = widget.calendar.code;

    final uid = context.read<AuthProvider>().uid;
    _isOwner = uid == widget.calendar.ownerId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          if (_isOwner)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isOwner) ...[
            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Color
            const Text('Color',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ColorPickerWidget(
              selectedColor: _color,
              onColorSelected: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 24),
          ],

          // Invite code
          InviteCodeWidget(
            code: _code,
            isOwner: _isOwner,
            onRegenerate: _regenerateCode,
          ),
          const SizedBox(height: 24),

          // QR Code
          Center(
            child: QrImageView(
              data: _code,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Members
          const Text(
            'Miembros',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<MemberModel>>(
            stream:
                CalendarService.getMembersStream(widget.calendar.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return MemberListWidget(
                members: snapshot.data!,
                ownerId: widget.calendar.ownerId,
                isOwner: _isOwner,
                calendarId: widget.calendar.id,
              );
            },
          ),

          if (_isOwner) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _deleteCalendar,
              icon: const Icon(Icons.delete_forever, color: AppColors.error),
              label: const Text('Eliminar calendario',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await CalendarService.updateCalendar(
        calendarId: widget.calendar.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _color,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _regenerateCode() async {
    try {
      final newCode =
          await CalendarService.regenerateCode(widget.calendar.id);
      setState(() => _code = newCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteCalendar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar calendario'),
        content: const Text(
          '¿Estás seguro? Se eliminarán todos los eventos y miembros. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CalendarService.deleteCalendar(widget.calendar.id);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
