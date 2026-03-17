import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/calendar_service.dart';
import '../config/app_config.dart';
import '../utils/globals.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  int _selectedColor = 0xFF2196F3;
  bool _isCreating = false;
  bool _isJoining = false;

  static const List<int> _colorOptions = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF009688, // Teal
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFFFFEB3B, // Yellow
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicators
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => _buildDot(i)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) =>
                    setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildSetupPage(),
                  _buildReadyPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.soka
            : AppColors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('web/icons/Icon-192.png', height: 100, width: 100),
          const SizedBox(height: 32),
          Text(
            'Bienvenido a ${AppConfig.appName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.soka,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Organizá actividades con calendarios compartidos. '
            'Creá un calendario o unite con un código de invitación.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.black54,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.soka,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Crear calendario',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre del calendario',
              hintText: 'Ej: Actividades del grupo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((c) {
              final isSelected = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.black87, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isCreating ? null : _createCalendar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.soka,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear calendario'),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          Text(
            'O unite con un código',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: AppConfig.inviteCodeLength,
            decoration: InputDecoration(
              labelText: 'Código de invitación',
              hintText: 'Ej: ABC123',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isJoining ? null : _joinCalendar,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.soka),
                foregroundColor: AppColors.soka,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unirme'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: AppColors.soka),
          const SizedBox(height: 24),
          Text(
            '¡Listo, ya estás adentro!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.soka,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tu calendario está configurado. Empezá a organizar tus actividades.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.black54,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: () {
              // CalendarProvider will auto-detect the new calendar
              // and the main router will redirect to HomePage
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.soka,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Ir al calendario'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCalendar() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un nombre para el calendario')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final uid = context.read<AuthProvider>().uid!;
      await CalendarService.createCalendar(
        name: name,
        ownerId: uid,
        color: _selectedColor,
      );

      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear calendario: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _joinCalendar() async {
    final code = _codeController.text.trim();
    if (code.length != AppConfig.inviteCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código debe tener 6 caracteres'),
        ),
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
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al unirse: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }
}
