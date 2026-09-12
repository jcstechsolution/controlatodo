import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/payment_card.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

/// Pantalla "Calendario": muestra visualmente los días con pagos,
/// vencimientos, renovaciones y mantenimientos.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);

  Map<DateTime, List<Payment>> _groupByDay(List<Payment> payments) {
    final map = <DateTime, List<Payment>>{};
    for (final payment in payments) {
      final day = _stripTime(payment.dueDate);
      map.putIfAbsent(day, () => []).add(payment);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final grouped = _groupByDay(paymentProvider.allPayments);
    final selectedPayments = grouped[_stripTime(_selectedDay)] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar<Payment>(
              locale: 'es_ES',
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              calendarFormat: _format,
              onFormatChanged: (format) => setState(() => _format = format),
              eventLoader: (day) => grouped[_stripTime(day)] ?? [],
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) => _focusedDay = focused,
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonShowsNext: false,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: selectedPayments.isEmpty
                  ? const EmptyState(
                      icon: Icons.event_note_outlined,
                      title: 'Sin eventos este día',
                      message: 'No hay pagos ni vencimientos programados.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: selectedPayments.length,
                      itemBuilder: (context, index) {
                        final payment = selectedPayments[index];
                        return PaymentCard(
                          payment: payment,
                          onTap: () => context.push(
                            AppRoutes.paymentDetailPath(payment.id),
                          ),
                          onMarkAsPaid: auth.firebaseUser == null
                              ? null
                              : () => paymentProvider.markAsPaid(
                                    auth.firebaseUser!.uid,
                                    payment,
                                  ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
