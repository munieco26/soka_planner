import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/calendar_service.dart';
import '../config/app_config.dart';
import '../utils/globals.dart';

class JoinCalendarPage extends StatefulWidget {
  const JoinCalendarPage({super.key});

  @override
  State<JoinCalendarPage> createState() => _JoinCalendarPageState();
}

class _JoinCalendarPageState extends State<JoinCalendarPage> {
  final _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse a calendario')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Ingresá el código de invitación',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pedile el código de 6 caracteres al administrador del calendario.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.black54,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: AppConfig.inviteCodeLength,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '------',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isJoining ? null : _join,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.soka,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Unirme', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.length != AppConfig.inviteCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El código debe tener 6 caracteres')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final auth = context.read<AuthProvider>();
      final result = await CalendarService.joinCalendar(
        code: code,
        uid: auth.uid!,
        displayName: auth.user?.displayName,
        email: auth.user?.email,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código no encontrado')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Te uniste a "${result.name}"')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }
}
