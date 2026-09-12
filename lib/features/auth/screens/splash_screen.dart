import 'package:flutter/material.dart';

/// Pantalla mostrada muy brevemente mientras se determina si el usuario
/// tiene una sesión activa (persistencia de sesión de Firebase Auth).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'ControlaTodo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
