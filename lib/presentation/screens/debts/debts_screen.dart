import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/debt.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _debts = [];
  bool _isLoading = true;
  String _statusFilter = 'todas';

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    List<Debt> debts;
    switch (_statusFilter) {
      case 'pendientes':
        debts = await DatabaseHelper.getPendingDebts();
        break;
      case 'pagadas':
        debts = await DatabaseHelper.getDebtsByStatus('paid');
        break;
      default:
        debts = await DatabaseHelper.getAllDebts();
    }
    setState(() {
      _debts = debts;
      _isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.errorColor;
      case 'partial':
        return AppTheme.warningColor;
      case 'paid':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'partial':
        return 'Parcial';
      case 'paid':
        return 'Pagada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _statusFilter = value);
              _loadDebts();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todas', child: Text('Todas')),
              const PopupMenuItem(value: 'pendientes', child: Text('Pendientes')),
              const PopupMenuItem(value: 'pagadas', child: Text('Pagadas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDebts,
              child: _debts.isEmpty
                  ? EmptyState(
                      icon: Icons.money_off,
                      title: 'No hay deudas registradas',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _debts.length,
                      itemBuilder: (context, index) {
                        final debt = _debts[index];
                        final isOverdue = debt.status != 'paid' && debt.dueDate.isBefore(DateTime.now());
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () => context.push('/debts/${debt.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _statusColor(debt.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      debt.status == 'paid' ? Icons.check_circle : Icons.pending_actions,
                                      color: _statusColor(debt.status),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          debt.customerName,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              'Monto: ${Formatters.formatCurrency(debt.amount)}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            if (debt.paidAmount > 0) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                'Pagado: ${Formatters.formatCurrency(debt.paidAmount)}',
                                                style: TextStyle(fontSize: 12, color: AppTheme.successColor),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          'Vence: ${Formatters.formatDate(debt.dueDate)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isOverdue ? AppTheme.errorColor : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(debt.status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _statusLabel(debt.status),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _statusColor(debt.status),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isOverdue)
                                        Text(
                                          'VENCIDA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.errorColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/debts/add');
          if (result == true) _loadDebts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
