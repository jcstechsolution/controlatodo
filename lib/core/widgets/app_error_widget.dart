import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Estado de error genérico y amigable (nunca se muestran mensajes técnicos).
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    this.message = 'Ha ocurrido un problema. Inténtalo nuevamente.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
