import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/payment_enums.dart';

/// Etiqueta compacta con el estado de un pago (Pendiente / Pagado / Vencido).
class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const PaymentStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.overdue:
        return AppColors.error;
      case PaymentStatus.pending:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
