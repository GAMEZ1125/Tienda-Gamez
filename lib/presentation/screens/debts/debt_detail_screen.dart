import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/payment.dart';

class DebtDetailScreen extends StatefulWidget {
  final int debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  Debt? _debt;
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final debt = await DatabaseHelper.getDebtById(widget.debtId);
    final payments = debt?.payments ?? [];
    setState(() {
      _debt = debt;
      _payments = payments;
      _isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppTheme.errorColor;
      case 'partial': return AppTheme.warningColor;
      case 'paid': return AppTheme.successColor;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'partial': return 'Parcial';
      case 'paid': return 'Pagada';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_debt == null) return Scaffold(
      appBar: AppBar(title: const Text('Deuda')),
      body: const Center(child: Text('Deuda no encontrada')),
    );

    final debt = _debt!;
    final isOverdue = debt.status != 'paid' && debt.dueDate.isBefore(DateTime.now());
    final progress = debt.amount > 0 ? debt.paidAmount / debt.amount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Deuda'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor(debt.status),
                      _statusColor(debt.status).withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        debt.customerName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 28,
                          color: _statusColor(debt.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(debt.customerName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(debt.status).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monto Total'),
                            Text(Formatters.formatCurrency(debt.amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pagado'),
                            Text(Formatters.formatCurrency(debt.paidAmount), style: TextStyle(fontSize: 16, color: AppTheme.successColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Saldo Pendiente'),
                            Text(Formatters.formatCurrency(debt.remainingAmount), style: TextStyle(fontSize: 16, color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            color: progress >= 1.0 ? AppTheme.successColor : AppTheme.warningColor,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Vence: ${Formatters.formatDate(debt.dueDate)}', style: TextStyle(
                              color: isOverdue ? AppTheme.errorColor : Colors.grey,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                            )),
                            if (isOverdue)
                              const Text('VENCIDA', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Payment history
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Historial de Pagos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    if (debt.status != 'paid')
                      FilledButton.tonalIcon(
                        onPressed: () => _registerPayment(debt),
                        icon: const Icon(Icons.payments, size: 18),
                        label: const Text('Registrar Pago'),
                      ),
                  ],
                ),
              ),

              if (_payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyState(icon: Icons.payments_outlined, title: 'Sin pagos registrados'),
                )
              else
                ...(_payments.map((payment) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                    ),
                    title: Text(Formatters.formatCurrency(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Formatters.formatDate(payment.date)),
                    trailing: Text(payment.method, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerPayment(Debt debt) async {
    final amountCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Deuda total: ${Formatters.formatCurrency(debt.amount)}'),
            Text('Saldo pendiente: ${Formatters.formatCurrency(debt.remainingAmount)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto a pagar',
                prefixText: r'$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (amountCtrl.text.isEmpty) return;
            Navigator.pop(ctx, true);
          }, child: const Text('Pagar')),
        ],
      ),
    );

    if (result == true && amountCtrl.text.isNotEmpty) {
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      if (amount > 0) {
        await DatabaseHelper.insertPayment(Payment(
          debtId: widget.debtId,
          amount: amount,
        ));
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago registrado'), backgroundColor: AppTheme.successColor),
          );
        }
      }
    }
  }
}
