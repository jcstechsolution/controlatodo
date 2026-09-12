import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/plan_limits.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/settings_provider.dart';

/// Pantalla "Mi cuenta": datos del usuario, plan, configuración y datos
/// de demostración.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final user = auth.userModel;
    final hasDemoData = paymentProvider.allPayments.any((p) => p.isDemo);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    child: Icon(Icons.person_rounded, size: 44, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: Icon(
                  user?.isPremium ?? false ? Icons.workspace_premium_rounded : Icons.star_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('Plan ${user?.planEnum.label ?? UserPlan.free.label}'),
                subtitle: Text(
                  user?.isPremium ?? false
                      ? 'Disfruta de todas las funciones Premium.'
                      : 'Hasta ${PlanLimits.freeMaxPayments} pagos • ${paymentProvider.totalCount}/${PlanLimits.freeMaxPayments} usados',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.premium),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Configuración',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.attach_money_rounded),
                    title: const Text('Moneda principal'),
                    trailing: DropdownButton<String>(
                      value: settings.settings.currency,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'CRC', child: Text('CRC (₡)')),
                        DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                      ],
                      onChanged: (value) {
                        if (value != null) settings.updateCurrency(value);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Notificaciones'),
                    value: settings.settings.notificationsEnabled,
                    onChanged: settings.updateNotificationsEnabled,
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.brightness_6_outlined),
                            SizedBox(width: 16),
                            Text('Tema'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'light', label: Text('Claro')),
                            ButtonSegment(value: 'dark', label: Text('Oscuro')),
                            ButtonSegment(value: 'system', label: Text('Sistema')),
                          ],
                          selected: {settings.settings.themeMode},
                          onSelectionChanged: (selection) {
                            settings.updateThemeMode(selection.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Datos de demostración',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dataset_outlined),
                    title: const Text('Cargar datos de prueba'),
                    subtitle: const Text('Agrega pagos de ejemplo para explorar la app.'),
                    onTap: () async {
                      final uid = auth.firebaseUser?.uid;
                      if (uid != null) await paymentProvider.seedDemoData(uid);
                    },
                  ),
                  if (hasDemoData) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined),
                      title: const Text('Eliminar datos de prueba'),
                      subtitle: const Text('Quita todos los pagos marcados como demostración.'),
                      onTap: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Eliminar datos de prueba',
                          message: '¿Deseas eliminar todos los pagos de demostración?',
                          confirmLabel: 'Eliminar',
                          isDestructive: true,
                        );
                        final uid = auth.firebaseUser?.uid;
                        if (confirmed && uid != null) {
                          await paymentProvider.removeDemoData(uid);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Cerrar sesión',
                  message: '¿Seguro que deseas cerrar tu sesión?',
                  confirmLabel: 'Cerrar sesión',
                  isDestructive: true,
                );
                if (confirmed) {
                  await auth.logout();
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
