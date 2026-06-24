import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  int _currentIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/pos')) return 1;
    if (location.startsWith('/inventory')) return 2;
    if (location.startsWith('/expenses')) return 2;
    if (location.startsWith('/customers')) return 3;
    if (location.startsWith('/suppliers')) return 3;
    if (location.startsWith('/debts')) return 4;
    if (location.startsWith('/purchase-orders')) return 4;
    if (location.startsWith('/categories')) return 2;
    if (location.startsWith('/stats')) return 0;
    if (location.startsWith('/configuracion')) return 0;
    if (location.startsWith('/settings')) return 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              final location = GoRouterState.of(context).uri.toString();
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedIndex: _currentIndex(location),
                onDestinationSelected: (index) {
                  switch (index) {
                    case 0:
                      context.go('/home');
                      break;
                    case 1:
                      context.go('/pos');
                      break;
                    case 2:
                      context.go('/inventory');
                      break;
                    case 3:
                      context.go('/customers');
                      break;
                    case 4:
                      context.go('/debts');
                      break;
                  }
                },
                indicatorColor: AppTheme.brandRed.withValues(alpha: isDark ? 0.25 : 0.12),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Inicio',
                  ),
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
                    icon: Icon(Icons.credit_card_outlined),
                    selectedIcon: Icon(Icons.credit_card),
                    label: 'Deudas',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
