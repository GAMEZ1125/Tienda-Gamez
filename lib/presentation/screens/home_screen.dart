import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  int _currentIndex(String location) {
    if (location.startsWith('/pos')) return 0;
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/expenses')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/suppliers')) return 2;
    if (location.startsWith('/debts')) return 3;
    if (location.startsWith('/stats')) return 4;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Builder(
        builder: (context) {
          final location = GoRouterState.of(context).uri.toString();
          return NavigationBar(
            selectedIndex: _currentIndex(location),
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/pos');
                  break;
                case 1:
                  context.go('/inventory');
                  break;
                case 2:
                  context.go('/customers');
                  break;
                case 3:
                  context.go('/debts');
                  break;
                case 4:
                  context.go('/stats');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: 'POS',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Inventario',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Clientes',
              ),
              NavigationDestination(
                icon: Icon(Icons.money_off_outlined),
                selectedIcon: Icon(Icons.money_off),
                label: 'Deudas',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Estadísticas',
              ),
            ],
          );
        },
      ),
    );
  }
}
