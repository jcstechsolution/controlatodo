import 'package:flutter/material.dart';

/// Tarjeta de resumen usada en el Dashboard ("Este mes", "Pagado", "Pendiente").
class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.colorScheme.outline),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
