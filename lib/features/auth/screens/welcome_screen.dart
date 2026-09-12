import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';

/// Primera pantalla que ve un usuario nuevo, con la propuesta de valor de
/// ControlaTodo.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_available_rounded, size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 28),
              Text(
                'Bienvenido a ControlaTodo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Organiza tus pagos y nunca olvides un vencimiento.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.outline,
                    ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Comenzar',
                onPressed: () => context.push(AppRoutes.register),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Ya tengo una cuenta',
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
