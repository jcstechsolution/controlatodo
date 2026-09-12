import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_categories.dart';
import '../../core/constants/payment_enums.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/payment_utils.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/summary_card.dart';
import '../../providers/payment_provider.dart';
import '../../providers/settings_provider.dart';

/// Pantalla "Estadísticas": totales, distribución por categoría y un primer
/// bosquejo de la futura función "Analizar mis gastos" (sin IA real todavía).
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  static const _chartColors = [
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
    Color(0xFF64748B),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.settings.currency;
    final payments = paymentProvider.allPayments
        .where((p) => p.currency == currency)
        .toList();

    if (paymentProvider.allPayments.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')),
        body: const EmptyState(
          icon: Icons.bar_chart_outlined,
          title: 'Aún no hay estadísticas',
          message: 'Agrega tus primeros pagos para ver tus totales y gráficos.',
        ),
      );
    }

    final now = DateTime.now();
    final monthlyTotal = payments
        .where((p) => p.dueDate.year == now.year && p.dueDate.month == now.month)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final yearlyTotal = payments
        .where((p) => p.dueDate.year == now.year)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final pendingCount = payments
        .where((p) => PaymentUtils.effectiveStatus(p.dueDate, p.statusEnum) == PaymentStatus.pending)
        .length;
    final paidCount = payments.where((p) => p.statusEnum == PaymentStatus.paid).length;
    final overdueCount = payments
        .where((p) => PaymentUtils.effectiveStatus(p.dueDate, p.statusEnum) == PaymentStatus.overdue)
        .length;

    final byCategory = <PaymentCategory, double>{};
    for (final p in payments) {
      byCategory.update(p.categoryEnum, (v) => v + p.amount, ifAbsent: () => p.amount);
    }
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recurringCount = paymentProvider.allPayments.where((p) => p.isRecurring).length;
    final paidThisMonth = payments
        .where((p) =>
            p.statusEnum == PaymentStatus.paid &&
            p.dueDate.year == now.year &&
            p.dueDate.month == now.month)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final topCategory = sortedCategories.isEmpty ? null : sortedCategories.first.key;

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    label: 'Total mensual',
                    value: CurrencyFormatter.format(monthlyTotal, currency),
                    icon: Icons.calendar_view_month_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: 'Total anual',
                    value: CurrencyFormatter.format(yearlyTotal, currency),
                    icon: Icons.event_note_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    label: 'Pendientes',
                    value: '$pendingCount',
                    valueColor: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: 'Pagados',
                    value: '$paidCount',
                    valueColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: 'Vencidos',
                    value: '$overdueCount',
                    valueColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Gastos por categoría',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (sortedCategories.isEmpty)
              const Text('Sin datos suficientes todavía.')
            else ...[
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      for (var i = 0; i < sortedCategories.length; i++)
                        PieChartSectionData(
                          value: sortedCategories[i].value,
                          color: _chartColors[i % _chartColors.length],
                          title: '',
                          radius: 46,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(sortedCategories.length, (i) {
                final entry = sortedCategories[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _chartColors[i % _chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.key.label)),
                      Text(
                        CurrencyFormatter.format(entry.value, currency),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tu análisis',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Tienes $recurringCount pagos recurrentes activos.'),
                  const SizedBox(height: 4),
                  Text('Este mes has pagado ${CurrencyFormatter.format(paidThisMonth, currency)}.'),
                  if (topCategory != null) ...[
                    const SizedBox(height: 4),
                    Text('Tu categoría con mayor gasto es ${topCategory.label}.'),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Análisis avanzado con inteligencia artificial disponible próximamente en Premium.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
