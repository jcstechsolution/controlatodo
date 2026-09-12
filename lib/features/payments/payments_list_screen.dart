import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/payment_enums.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/payment_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

/// Pantalla "Mis pagos": listado completo con búsqueda, filtros, orden y
/// acciones de editar / eliminar / marcar como pagado.
class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _filterLabel(PaymentFilter filter) {
    switch (filter) {
      case PaymentFilter.all:
        return 'Todos';
      case PaymentFilter.pending:
        return 'Pendientes';
      case PaymentFilter.paid:
        return 'Pagados';
      case PaymentFilter.overdue:
        return 'Vencidos';
    }
  }

  String _sortLabel(PaymentSort sort) {
    switch (sort) {
      case PaymentSort.dueDateAsc:
        return 'Próximo vencimiento';
      case PaymentSort.amountDesc:
        return 'Mayor monto';
      case PaymentSort.amountAsc:
        return 'Menor monto';
      case PaymentSort.name:
        return 'Nombre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final uid = auth.firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pagos'),
        actions: [
          PopupMenuButton<PaymentSort>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: paymentProvider.setSort,
            itemBuilder: (context) => PaymentSort.values
                .map((s) => PopupMenuItem(value: s, child: Text(_sortLabel(s))))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: paymentProvider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Buscar pago...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          paymentProvider.setSearchQuery('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: PaymentFilter.values.map((filter) {
                final selected = paymentProvider.filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: selected,
                    onSelected: (_) => paymentProvider.setFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: paymentProvider.isLoading
                ? const LoadingWidget()
                : _buildList(context, paymentProvider, uid),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, PaymentProvider provider, String? uid) {
    final payments = provider.filteredPayments;
    if (payments.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No hay pagos que mostrar',
        message: 'Prueba con otro filtro o agrega un nuevo pago.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return PaymentCard(
          payment: payment,
          onTap: () => context.push(AppRoutes.paymentDetailPath(payment.id)),
          onMarkAsPaid: payment.statusEnum == PaymentStatus.paid || uid == null
              ? null
              : () => provider.markAsPaid(uid, payment),
          onEdit: () => context.push(
            AppRoutes.editPaymentPath(payment.id),
            extra: payment,
          ),
          onDelete: uid == null
              ? null
              : () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Eliminar pago',
                    message: '¿Seguro que deseas eliminar "${payment.name}"? Esta acción no se puede deshacer.',
                    confirmLabel: 'Eliminar',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    await provider.deletePayment(uid, payment.id);
                  }
                },
        );
      },
    );
  }
}
