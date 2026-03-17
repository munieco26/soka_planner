import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/globals.dart';

class InviteCodeWidget extends StatelessWidget {
  final String code;
  final bool isOwner;
  final VoidCallback? onRegenerate;

  const InviteCodeWidget({
    super.key,
    required this.code,
    this.isOwner = false,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Código de invitación',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: AppColors.soka,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copiar código',
                ),
              ],
            ),
            if (isOwner && onRegenerate != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Regenerar código'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
