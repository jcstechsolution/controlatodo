import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/services/ocr_service.dart';
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

  /// Toma una foto con la cámara, la analiza con OCR en el dispositivo
  /// (Google ML Kit, sin costo ni conexión a internet) y, si logra
  /// detectar un monto o un nombre probable, abre el formulario de "Agregar
  /// pago" con esos datos precargados para que el usuario los revise y
  /// corrija antes de guardar.
  Future<void> _scanInvoice(BuildContext context) async {
    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la cámara. Revisa el permiso de cámara de la app.',
          ),
        ),
      );
      return;
    }

    if (photo == null) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Leyendo la factura...')),
          ],
        ),
      ),
    );

    ScanResult? result;
    try {
      result = await OcrService.instance.scanImage(photo.path);
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[OCR] texto reconocido (${result.rawText.length} caracteres): '
          '"${result.rawText}" | nombre=${result.name} | monto=${result.amount}',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[OCR] error al escanear la imagen: $e\n$st');
      }
      result = null;
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (result == null || (result.name == null && result.amount == null)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se detectó texto claro en la foto. Puedes ingresar los datos manualmente.',
          ),
        ),
      );
    }

    if (!context.mounted) return;
    context.push(
      AppRoutes.newPayment,
      extra: {
        if (result?.name != null) 'name': result!.name,
        if (result?.amount != null) 'amount': result!.amount,
      },
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
                      onPressed: () => _scanInvoice(context),
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
                    const SizedBox(height: 28),
                    _RecurringObligationsCard(
                      monthlyTotal: paymentProvider.recurringMonthlyTotalFor(currency),
                      annualTotal: paymentProvider.recurringAnnualTotalFor(currency),
                      currency: currency,
                    ),
                    const SizedBox(height: 16),
                    const _InsightsPlaceholderCard(),
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

/// Muestra el total mensualizado y anualizado de las obligaciones
/// recurrentes activas (ej. "₡98.400 / mes ≈ ₡1.180.800 / año"). Ver
/// `PaymentUtils.monthlyEquivalent`/`annualEquivalent`.
class _RecurringObligationsCard extends StatelessWidget {
  final double monthlyTotal;
  final double annualTotal;
  final String currency;

  const _RecurringObligationsCard({
    required this.monthlyTotal,
    required this.annualTotal,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.autorenew_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Obligaciones recurrentes',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (monthlyTotal <= 0)
            Text(
              'No tienes obligaciones recurrentes activas todavía.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            )
          else
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: CurrencyFormatter.format(monthlyTotal, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' / mes  ≈  '),
                  TextSpan(
                    text: CurrencyFormatter.format(annualTotal, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' / año'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Espacio preparado para futuros análisis inteligentes (detección de
/// aumentos de precio, patrones de gasto, etc.) — sin inventar ningún
/// insight real todavía, solo el mensaje de que hace falta más historial.
class _InsightsPlaceholderCard extends StatelessWidget {
  const _InsightsPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cuando tengas más historial podremos detectar cambios en tus gastos.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
