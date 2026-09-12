import 'package:flutter/material.dart';

import '../../core/constants/plan_limits.dart';
import '../../core/widgets/primary_button.dart';

/// Pantalla "ControlaTodo Premium". La compra real (Google Play Billing /
/// App Store) se integrará en una fase posterior; por ahora el botón solo
/// informa que estará disponible próximamente.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  static const _features = [
    ('Pagos ilimitados', Icons.all_inclusive_rounded),
    ('Estadísticas avanzadas', Icons.insights_rounded),
    ('Escaneo de facturas (OCR)', Icons.document_scanner_rounded),
    ('Inteligencia artificial', Icons.auto_awesome_rounded),
    ('Categorías personalizadas', Icons.category_rounded),
    ('Funciones familiares', Icons.groups_rounded),
    ('Copias de seguridad avanzadas', Icons.cloud_done_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ControlaTodo Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 44),
                  SizedBox(height: 12),
                  Text(
                    'Lleva ControlaTodo al siguiente nivel',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text('⭐', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Icon(feature.$2, color: scheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(feature.$1, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _PriceCard(
                    label: 'Mensual',
                    price: '\$${PlanLimits.premiumMonthlyPriceUsd.toStringAsFixed(2)}',
                    suffix: '/ mes',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceCard(
                    label: 'Anual',
                    price: '\$${PlanLimits.premiumYearlyPriceUsd.toStringAsFixed(2)}',
                    suffix: '/ año',
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Actualizar a Premium',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Próximamente'),
                    content: const Text(
                      'Los pagos Premium estarán disponibles próximamente.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final String price;
  final String suffix;
  final bool highlight;

  const _PriceCard({
    required this.label,
    required this.price,
    required this.suffix,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? scheme.primary.withOpacity(0.08) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? scheme.primary : scheme.outlineVariant,
          width: highlight ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            price,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(suffix, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
