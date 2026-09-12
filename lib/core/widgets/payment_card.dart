import 'package:flutter/material.dart';

import '../constants/app_categories.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/payment_utils.dart';
import '../../models/payment_model.dart';
import 'category_icon.dart';
import 'payment_status_badge.dart';

/// Tarjeta que representa un pago dentro de una lista (Dashboard, Mis pagos,
/// Calendario). Muestra el emoji/color de urgencia, nombre, monto y fecha.
class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsPaid;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onTap,
    this.onMarkAsPaid,
    this.onEdit,
    this.onDelete,
  });

  bool get _hasMenu => onEdit != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgencyColor = PaymentUtils.urgencyColor(payment.dueDate, payment.statusEnum);
    final emoji = PaymentUtils.urgencyEmoji(payment.dueDate, payment.statusEnum);
    final relative = DateFormatter.relativeLabel(payment.dueDate);
    final amountLabel = CurrencyFormatter.format(payment.amount, payment.currency);
    final effectiveStatus = PaymentUtils.effectiveStatus(payment.dueDate, payment.statusEnum);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CategoryIcon(category: payment.categoryEnum),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            relative,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: urgencyColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (payment.provider != null && payment.provider!.isNotEmpty)
                        Text(
                          payment.provider!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        payment.categoryEnum.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          amountLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_hasMenu)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.more_vert_rounded,
                                size: 18, color: theme.colorScheme.outline),
                            onSelected: (value) {
                              if (value == 'edit') onEdit?.call();
                              if (value == 'delete') onDelete?.call();
                            },
                            itemBuilder: (context) => [
                              if (onEdit != null)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                              if (onDelete != null)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar'),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    PaymentStatusBadge(status: effectiveStatus),
                    if (onMarkAsPaid != null) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onMarkAsPaid,
                        child: const Text('Marcar pagado', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
