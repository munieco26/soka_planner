import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import '../utils/globals.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('web/icons/Icon-192.png', height: 120, width: 120),
              const SizedBox(height: 24),
              Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.soka,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Calendarios colaborativos',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.black54,
                    ),
              ),
              const SizedBox(height: 48),
              if (authProvider.isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: 280,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _signIn(context),
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 24,
                      width: 24,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.login, size: 24),
                    ),
                    label: const Text('Iniciar sesión con Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.black87,
                      side: const BorderSide(color: AppColors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn(BuildContext context) async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
