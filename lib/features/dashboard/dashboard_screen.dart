import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/payment_card.dart';
import '../../core/widgets/summary_card.dart';
import '../../models/monthly_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/settings_provider.dart';

/// Pantalla principal: saludo, resumen mensual y próximos vencimientos.
class DashboardScreen extends StatelessWidget {
  final VoidCallback? onSeeAllPayments;

  const DashboardScreen({super.key, this.onSeeAllPayments});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días 👋';
    if (hour < 19) return 'Buenas tardes 👋';
    return 'Buenas noches 👋';
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(feature),
        content: const Text('Esta función estará disponible en Premium próximamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final settings = context.watch<SettingsProvider>();
    final userName = auth.userModel?.name.split(' ').first ?? '';
    final currency = settings.settings.currency;
    final summary = paymentProvider.monthlySummaryFor(currency);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: paymentProvider.isLoading
              ? const LoadingWidget()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    Text(
                      _greeting(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      userName.isEmpty ? 'Bienvenido' : userName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _MonthlyTotalCard(summary: summary),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Pagado',
                            value: CurrencyFormatter.format(summary.paid, currency),
                            valueColor: Theme.of(context).colorScheme.secondary,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            label: 'Pendiente',
                            value: CurrencyFormatter.format(summary.pending, currency),
                            valueColor: Theme.of(context).colorScheme.error,
                            icon: Icons.hourglass_empty_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showComingSoon(context, 'Escanear factura'),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text('Escanear factura'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Próximos vencimientos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (onSeeAllPayments != null)
                          TextButton(
                            onPressed: onSeeAllPayments,
                            child: const Text('Ver todos'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (paymentProvider.upcomingPayments.isEmpty)
                      const EmptyState(
                        icon: Icons.event_available_outlined,
                        title: 'No tienes vencimientos próximos',
                        message: 'Agrega tu primer pago con el botón "+ Agregar".',
                      )
                    else
                      ...paymentProvider.upcomingPayments.map(
                        (payment) => PaymentCard(
                          payment: payment,
                          onTap: () =>
                              context.push(AppRoutes.paymentDetailPath(payment.id)),
                          onMarkAsPaid: () {
                            final uid = auth.firebaseUser?.uid;
                            if (uid != null) {
                              paymentProvider.markAsPaid(uid, payment);
                            }
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MonthlyTotalCard extends StatelessWidget {
  final MonthlySummary summary;

  const _MonthlyTotalCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Este mes',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(summary.total, summary.currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
