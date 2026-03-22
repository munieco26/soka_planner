import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/event_service.dart';
import '../services/storage_service.dart';
import '../widgets/color_picker_widget.dart';
import '../widgets/flyer_picker_widget.dart';
import 'package:image_picker/image_picker.dart';

class EventFormPage extends StatefulWidget {
  final String calendarId;
  final Event? event; // null = create, non-null = edit

  const EventFormPage({
    super.key,
    required this.calendarId,
    this.event,
  });

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  int _selectedColor = 0xFF2196F3;
  List<XFile> _newImages = [];
  List<String> _existingFlyerUrls = [];
  bool _isSaving = false;
  bool _isPrivate = false;

  bool get _isEditing => widget.event != null;

  bool _canChangePrivateFlag(String uid) =>
      !_isEditing || widget.event!.createdBy == uid;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.event!;
      _titleController.text = e.title;
      _descriptionController.text = e.description ?? '';
      _locationController.text = e.location ?? '';
      _startDate = e.start;
      _isAllDay = e.isAllDay;
      _selectedColor = e.color;
      _existingFlyerUrls = List.from(e.flyerUrls);
      _isPrivate = e.isPrivate;
      if (!e.isAllDay) {
        _startTime = TimeOfDay.fromDateTime(e.start);
        if (e.end != null) {
          _endTime = TimeOfDay.fromDateTime(e.end!);
        }
      }
    } else {
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar evento' : 'Nuevo evento'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresá un título' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // All day toggle
            SwitchListTile(
              title: const Text('Todo el día'),
              value: _isAllDay,
              onChanged: (v) => setState(() => _isAllDay = v),
              contentPadding: EdgeInsets.zero,
            ),

            // Private: solo el creador puede cambiar este valor al editar
            Builder(
              builder: (context) {
                final uid = context.read<AuthProvider>().uid ?? '';
                final canChange = _canChangePrivateFlag(uid);
                return SwitchListTile(
                  title: const Text('Evento privado'),
                  subtitle: Text(
                    canChange
                        ? 'Solo vos podés editarlo o borrarlo'
                        : 'Solo el creador puede cambiar esta opción',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _isPrivate,
                  onChanged: canChange
                      ? (v) => setState(() => _isPrivate = v)
                      : null,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                DateFormat('EEEE d MMMM yyyy', 'es_AR').format(_startDate),
              ),
              onTap: _pickDate,
            ),

            // Time
            if (!_isAllDay) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(
                  '${_startTime?.format(context) ?? 'Hora inicio'}'
                  '${_endTime != null ? ' - ${_endTime!.format(context)}' : ''}',
                ),
                onTap: _pickTime,
              ),
            ],

            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Ubicación (opcional)',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            const Text('Color',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ColorPickerWidget(
              selectedColor: _selectedColor,
              onColorSelected: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: 24),

            // Flyer images
            const Text('Imágenes / Flyers',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            FlyerPickerWidget(
              existingUrls: _existingFlyerUrls,
              newImages: _newImages,
              onImagesChanged: (images) =>
                  setState(() => _newImages = images),
              onExistingRemoved: (url) =>
                  setState(() => _existingFlyerUrls.remove(url)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'AR'),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (start == null || !mounted) return;
    setState(() => _startTime = start);

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (start.hour + 1) % 24,
        minute: start.minute,
      ),
    );
    if (end != null && mounted) setState(() => _endTime = end);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final uid = context.read<AuthProvider>().uid!;
      final startDateTime = _isAllDay
          ? DateTime(_startDate.year, _startDate.month, _startDate.day)
          : DateTime(
              _startDate.year,
              _startDate.month,
              _startDate.day,
              _startTime?.hour ?? 0,
              _startTime?.minute ?? 0,
            );

      DateTime? endDateTime;
      if (!_isAllDay && _endTime != null) {
        endDateTime = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      // Upload new images
      List<String> allFlyerUrls = List.from(_existingFlyerUrls);
      if (_newImages.isNotEmpty) {
        final eventId = _isEditing
            ? widget.event!.id
            : 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final newUrls = await StorageService.uploadMultipleFlyers(
          calendarId: widget.calendarId,
          eventId: eventId,
          files: _newImages,
        );
        allFlyerUrls.addAll(newUrls);
      }

      if (_isEditing) {
        await EventService.updateEvent(
          calendarId: widget.calendarId,
          eventId: widget.event!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          start: startDateTime,
          end: endDateTime,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          color: _selectedColor,
          isAllDay: _isAllDay,
          isPrivate: _canChangePrivateFlag(uid) ? _isPrivate : null,
          flyerUrls: allFlyerUrls,
        );
      } else {
        await EventService.createEvent(
          calendarId: widget.calendarId,
          title: _titleController.text.trim(),
          start: startDateTime,
          createdBy: uid,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          end: endDateTime,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          color: _selectedColor,
          isAllDay: _isAllDay,
          isPrivate: _isPrivate,
          flyerUrls: allFlyerUrls,
        );
      }

      if (mounted) Navigator.pop(context);
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
}
