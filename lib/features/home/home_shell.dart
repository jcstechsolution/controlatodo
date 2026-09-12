import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../calendar/calendar_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../payments/payments_list_screen.dart';
import '../profile/profile_screen.dart';
import '../statistics/statistics_screen.dart';

/// Contenedor principal con navegación inferior entre las 5 secciones de
/// ControlaTodo, mostrado una vez que el usuario inició sesión.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final showFab = _index == 0 || _index == 1;
    final screens = [
      DashboardScreen(onSeeAllPayments: () => setState(() => _index = 1)),
      const PaymentsListScreen(),
      const CalendarScreen(),
      const StatisticsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _index, children: screens),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.newPayment),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Mis pagos',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
