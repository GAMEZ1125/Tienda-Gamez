import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/inventory/product_form_screen.dart';
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

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => HomeScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/pos',
          pageBuilder: (context, state) => const NoTransitionPage(child: POSScreen()),
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) => const NoTransitionPage(child: InventoryScreen()),
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
          ],
        ),
        GoRoute(
          path: '/expenses',
          pageBuilder: (context, state) => const NoTransitionPage(child: ExpensesScreen()),
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
          pageBuilder: (context, state) => const NoTransitionPage(child: CustomersScreen()),
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
          pageBuilder: (context, state) => const NoTransitionPage(child: SuppliersScreen()),
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
          pageBuilder: (context, state) => const NoTransitionPage(child: DebtsScreen()),
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
          pageBuilder: (context, state) => const NoTransitionPage(child: CategoriesScreen()),
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
          pageBuilder: (context, state) => const NoTransitionPage(child: PurchaseOrdersScreen()),
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
          pageBuilder: (context, state) => const NoTransitionPage(child: StatsScreen()),
        ),
        GoRoute(
          path: '/configuracion',
          pageBuilder: (context, state) => const NoTransitionPage(child: ConfiguracionScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
);
