import 'package:flutter/material.dart';

import '../constants/app_categories.dart';

/// Icono circular de una categoría de pago.
class CategoryIcon extends StatelessWidget {
  final PaymentCategory category;
  final double size;

  const CategoryIcon({super.key, required this.category, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(category.icon, color: scheme.primary, size: size * 0.5),
    );
  }
}
