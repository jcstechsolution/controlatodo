import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/billing_constants.dart';
import '../../core/constants/plan_limits.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';

/// Pantalla "ControlaTodo Premium". Muestra el catálogo de suscripción y,
/// si el usuario ya es Premium, un estado distinto en vez del flujo de
/// compra. La compra real se dispara vía `BillingProvider` (Google Play
/// Billing / App Store a través de `in_app_purchase`), que verifica cada
/// compra contra la Cloud Function `verifyPlayPurchase` antes de darla por
/// buena — esta pantalla nunca activa Premium por sí misma.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedProductId = BillingConstants.premiumAnnualProductId;
  bool _busy = false;

  static const _features = [
    ('Pagos ilimitados', Icons.all_inclusive_rounded),
    ('Estadísticas avanzadas', Icons.insights_rounded),
    ('Escaneo de facturas (OCR)', Icons.document_scanner_rounded),
    ('Inteligencia artificial', Icons.auto_awesome_rounded),
    ('Categorías personalizadas', Icons.category_rounded),
    ('Funciones familiares', Icons.groups_rounded),
    ('Copias de seguridad avanzadas', Icons.cloud_done_rounded),
  ];

  Future<void> _buy() async {
    final billing = context.read<BillingProvider>();
    setState(() => _busy = true);
    final ok = await billing.buy(_selectedProductId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      // AuthProvider.userModel se obtiene con un fetch único (no es un
      // stream), así que hay que refrescarlo a mano para que la pantalla
      // refleje el cambio a Premium sin reiniciar la app.
      await context.read<AuthProvider>().refreshUserModel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Listo! Ya eres Premium.')),
      );
    } else if (billing.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(billing.errorMessage!)),
      );
    }
  }

  Future<void> _restore() async {
    final billing = context.read<BillingProvider>();
    setState(() => _busy = true);
    final ok = await billing.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      await context.read<AuthProvider>().refreshUserModel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Tu compra Premium fue restaurada!')),
      );
    } else if (billing.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(billing.errorMessage!)),
      );
    }
  }

  String _priceLabel(BillingProvider billing, String productId, double fallbackUsd) {
    final product = billing.productById(productId);
    if (product != null) return product.price;
    return '\$${fallbackUsd.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final billing = context.watch<BillingProvider>();
    final isPremium = auth.userModel?.isPremium ?? false;
    final expiryTime = auth.userModel?.premiumExpiryTime;

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
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    isPremium ? 'Ya eres Premium' : 'Lleva ControlaTodo al siguiente nivel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (isPremium && expiryTime != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Renueva el ${_formatDate(expiryTime)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
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
            if (isPremium) ...[
              Center(
                child: TextButton.icon(
                  onPressed: _busy ? null : _restore,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restaurar compras'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _PriceCard(
                      label: 'Mensual',
                      price: _priceLabel(
                        billing,
                        BillingConstants.premiumMonthlyProductId,
                        PlanLimits.premiumMonthlyPriceUsd,
                      ),
                      suffix: '/ mes',
                      selected: _selectedProductId == BillingConstants.premiumMonthlyProductId,
                      onTap: () => setState(
                        () => _selectedProductId = BillingConstants.premiumMonthlyProductId,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PriceCard(
                      label: 'Anual',
                      price: _priceLabel(
                        billing,
                        BillingConstants.premiumAnnualProductId,
                        PlanLimits.premiumYearlyPriceUsd,
                      ),
                      suffix: '/ año',
                      highlight: true,
                      selected: _selectedProductId == BillingConstants.premiumAnnualProductId,
                      onTap: () => setState(
                        () => _selectedProductId = BillingConstants.premiumAnnualProductId,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (!billing.storeAvailable)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'La tienda de aplicaciones no está disponible en este dispositivo ahora mismo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              PrimaryButton(
                label: 'Actualizar a Premium',
                isLoading: _busy,
                onPressed: (_busy || !billing.storeAvailable) ? null : _buy,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _restore,
                  child: const Text('Restaurar compras'),
                ),
              ),
            ],
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
  final bool selected;
  final VoidCallback? onTap;

  const _PriceCard({
    required this.label,
    required this.price,
    required this.suffix,
    this.highlight = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.08) : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
                ),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ahorra más',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(suffix, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
