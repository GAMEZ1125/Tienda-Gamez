import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/expense.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  double _totalMonth = 0;
  Map<String, double> _categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final expenses = await DatabaseHelper.getExpensesByDateRange(start, end);
    final total = await DatabaseHelper.getTotalExpensesByDateRange(start, end);
    final categories = await DatabaseHelper.getExpensesGroupedByCategory(start, end);

    setState(() {
      _expenses = expenses;
      _totalMonth = total;
      _categoryTotals = categories;
      _isLoading = false;
    });
  }

  Color _categoryColor(String category) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
      AppTheme.successColor,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.brown,
    ];
    final index = AppConstants.expenseCategories.indexOf(category);
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              child: CustomScrollView(
                slivers: [
                  // Summary card
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gastos del Mes',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatCurrency(_totalMonth),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Category chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categoryTotals.entries.map((entry) {
                              return Chip(
                                label: Text(
                                  '${entry.key}: ${Formatters.formatCurrency(entry.value)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                ),
                                backgroundColor: _categoryColor(entry.key).withValues(alpha: 0.3),
                                side: BorderSide.none,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expenses list
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Historial de Gastos',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),

                  if (_expenses.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.money_off,
                        title: 'Sin gastos registrados',
                        subtitle: 'Registra tus gastos mensuales',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final expense = _expenses[index];
                          final catColor = _categoryColor(expense.category);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.receipt, color: catColor),
                              ),
                              title: Text(expense.concept),
                              subtitle: Text(
                                '${expense.category} - ${Formatters.formatDate(expense.date)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(expense.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: catColor,
                                    ),
                                  ),
                                  if (expense.supplierName != null)
                                    Text(
                                      expense.supplierName!,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                ],
                              ),
                              onTap: () => _showEditDialog(expense),
                            ),
                          );
                        },
                        childCount: _expenses.length,
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/expenses/add');
          if (result == true) _loadExpenses();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(Expense expense) {
    // Simplified - just show details
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(expense.concept),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Categoría', expense.category),
            _detailRow('Monto', Formatters.formatCurrency(expense.amount)),
            _detailRow('Fecha', Formatters.formatDate(expense.date)),
            if (expense.supplierName != null)
              _detailRow('Proveedor', expense.supplierName!),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              _detailRow('Notas', expense.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
