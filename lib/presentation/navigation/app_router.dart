import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/inventory/product_form_screen.dart';
import '../screens/inventory/inventory_movements_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/expenses/expense_form_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/customers/customer_form_screen.dart';
import '../screens/customers/customer_profile_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/suppliers/supplier_form_screen.dart';
import '../screens/suppliers/supplier_profile_screen.dart';
import '../screens/suppliers/supplier_payments_screen.dart';
import '../screens/debts/debts_screen.dart';
import '../screens/debts/debt_form_screen.dart';
import '../screens/debts/debt_detail_screen.dart';
import '../screens/debts/credit_report_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/configuracion/configuracion_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/categories/category_form_screen.dart';
import '../screens/purchase_orders/purchase_orders_screen.dart';
import '../screens/purchase_orders/purchase_order_form_screen.dart';
import '../screens/subscription/premium_screen.dart';
import '../../services/app_state.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  redirect: (context, state) {
    final loggedIn = preferencesService.userLoggedIn;
    final onLoginRoute = state.matchedLocation == '/login';

    if (!loggedIn && !onLoginRoute) return '/login';
    if (loggedIn && onLoginRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPageWithTransition(context, state, const LoginScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const DashboardScreen()),
        ),
        GoRoute(
          path: '/pos',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const POSScreen()),
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const InventoryScreen()),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const ProductFormScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => ProductFormScreen(
                productId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
            GoRoute(
              path: 'movements',
              pageBuilder: (context, state) => _buildPageWithTransition(context, state, const InventoryMovementsScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/expenses',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const ExpensesScreen()),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const ExpenseFormScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => ExpenseFormScreen(
                expenseId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/customers',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const CustomersScreen()),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const CustomerFormScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => CustomerFormScreen(
                customerId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          GoRoute(
              path: ':id',
              builder: (context, state) => CustomerProfileScreen(
                customerId: int.parse(state.pathParameters['id'] ?? '0'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/suppliers',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const SuppliersScreen()),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const SupplierFormScreen(),
            ),
            GoRoute(
              path: 'payments',
              builder: (context, state) => const SupplierPaymentsScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => SupplierProfileScreen(
                supplierId: int.parse(state.pathParameters['id'] ?? '0'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/debts',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const DebtsScreen()),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const DebtFormScreen(),
            ),
            GoRoute(
              path: 'report',
              builder: (context, state) => const CreditReportScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => DebtDetailScreen(
                debtId: int.parse(state.pathParameters['id'] ?? '0'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const CategoriesScreen()),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const CategoryFormScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => CategoryFormScreen(
                categoryId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/purchase-orders',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const PurchaseOrdersScreen()),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const PurchaseOrderFormScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) => PurchaseOrderFormScreen(
                orderId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const StatsScreen()),
        ),
        GoRoute(
          path: '/configuracion',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const ConfiguracionScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const SettingsScreen()),
        ),
        GoRoute(
          path: '/subscription',
          pageBuilder: (context, state) => _buildPageWithTransition(context, state, const PremiumScreen()),
        ),
      ],
    ),
  ],
);
