import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/payment_enums.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/payment_utils.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/payment_status_badge.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

/// Detalle completo de un pago, con su historial y acciones.
class PaymentDetailScreen extends StatelessWidget {
  final String paymentId;

  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final auth = context.watch<AuthProvider>();
    final uid = auth.firebaseUser?.uid;

    Payment? payment;
    for (final p in paymentProvider.allPayments) {
      if (p.id == paymentId) {
        payment = p;
        break;
      }
    }

    if (payment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pago')),
        body: const Center(child: Text('Este pago ya no está disponible.')),
      );
    }

    final effectiveStatus = PaymentUtils.effectiveStatus(payment.dueDate, payment.statusEnum);

    return Scaffold(
      appBar: AppBar(
        title: Text(payment.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(payment.amount, payment.currency),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                PaymentStatusBadge(status: effectiveStatus),
              ],
            ),
            const SizedBox(height: 20),
            if (payment.provider != null && payment.provider!.isNotEmpty)
              _DetailRow(label: 'Proveedor', value: payment.provider!),
            _DetailRow(label: 'Categoría', value: payment.categoryEnum.label),
            _DetailRow(label: 'Fecha de vencimiento', value: DateFormatter.toShort(payment.dueDate)),
            _DetailRow(
              label: 'Frecuencia',
              value: payment.isRecurring ? payment.frequencyEnum.label : 'Una vez',
            ),
            _DetailRow(label: 'Recordatorio', value: ReminderOptionX.fromDays(payment.reminderDays).label),
            if (payment.invoiceNumber != null && payment.invoiceNumber!.isNotEmpty)
              _DetailRow(label: 'Número de factura', value: payment.invoiceNumber!),
            if (payment.notes != null && payment.notes!.isNotEmpty)
              _DetailRow(label: 'Notas', value: payment.notes!),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Próximamente aquí: documento/factura adjunto, variación '
                      'del monto y promedio histórico de este pago.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Historial',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (uid != null)
              StreamBuilder(
                stream: paymentProvider.watchHistory(uid, payment.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final entries = snapshot.data!;
                  if (entries.isEmpty) {
                    return Text(
                      'Todavía no hay pagos registrados en el historial.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    );
                  }
                  return Column(
                    children: entries
                        .map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle_outline_rounded),
                            title: Text(DateFormatter.toShort(entry.paidAt)),
                            trailing: Text(
                              CurrencyFormatter.format(entry.amount, entry.currency),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            const SizedBox(height: 28),
            if (payment.statusEnum != PaymentStatus.paid)
              PrimaryButton(
                label: 'Marcar como pagado',
                onPressed: () {
                  if (uid != null) {
                    paymentProvider.markAsPaid(uid, payment!);
                  }
                },
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(
                AppRoutes.editPaymentPath(payment!.id),
                extra: payment,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Eliminar pago',
                  message: '¿Seguro que deseas eliminar "${payment!.name}"? Esta acción no se puede deshacer.',
                  confirmLabel: 'Eliminar',
                  isDestructive: true,
                );
                if (confirmed && uid != null && context.mounted) {
                  await paymentProvider.deletePayment(uid, payment!.id);
                  if (context.mounted) context.pop();
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
