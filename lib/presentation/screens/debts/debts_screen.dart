import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/supplier_debt.dart';
import '../../../domain/entities/supplier_debt_payment.dart';
import '../../../services/app_state.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _receivableDebts = [];
  List<SupplierDebt> _supplierDebts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final receivable = await DatabaseHelper.getAllDebts();
    final supplierDebts = await DatabaseHelper.getAllSupplierDebts();
    if (!mounted) return;
    setState(() {
      _receivableDebts = receivable;
      _supplierDebts = supplierDebts;
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
        return AppTheme.greyMedium;
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

  double get _totalReceivablePending =>
      _receivableDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);

  double get _totalReceivablePaid =>
      _receivableDebts.fold(0.0, (sum, debt) => sum + debt.paidAmount);

  double get _totalPayablePending =>
      _supplierDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);

  int get _overdueCount => _receivableDebts
      .where((debt) => debt.status != 'paid' && debt.dueDate.isBefore(DateTime.now()))
      .length;

  Future<void> _shareOverview() async {
    final buffer = StringBuffer()
      ..writeln('${preferencesService.businessName} - Resumen de deudas')
      ..writeln('Fecha: ${Formatters.formatDateTime(DateTime.now())}')
      ..writeln('')
      ..writeln('Por cobrar:')
      ..writeln('- Total pendiente: ${Formatters.formatCurrency(_totalReceivablePending)}')
      ..writeln('- Total pagado: ${Formatters.formatCurrency(_totalReceivablePaid)}')
      ..writeln('- Vencidas: $_overdueCount')
      ..writeln('')
      ..writeln('Por pagar:')
      ..writeln('- Total pendiente: ${Formatters.formatCurrency(_totalPayablePending)}')
      ..writeln('- Deudas pendientes: ${_supplierDebts.where((d) => d.status != 'paid').length}');

    await Share.share(buffer.toString(), subject: 'Resumen de deudas - ${preferencesService.businessName}');
  }

  Future<void> _shareReceivableDebt(Debt debt) async {
    final buffer = StringBuffer()
      ..writeln('${preferencesService.businessName} - Estado de deuda')
      ..writeln('Cliente: ${debt.customerName}')
      ..writeln('Monto total: ${Formatters.formatCurrency(debt.amount)}')
      ..writeln('Pagado: ${Formatters.formatCurrency(debt.paidAmount)}')
      ..writeln('Pendiente: ${Formatters.formatCurrency(debt.remainingAmount)}')
      ..writeln('Vencimiento: ${Formatters.formatDate(debt.dueDate)}')
      ..writeln('Estado: ${_statusLabel(debt.status)}');

    await Share.share(buffer.toString(), subject: 'Estado de deuda - ${debt.customerName}');
  }

  Future<void> _paySupplierDebt(SupplierDebt debt) async {
    final amountCtrl = TextEditingController(text: debt.remainingAmount.toStringAsFixed(0));
    final methodCtrl = TextEditingController(text: 'Efectivo');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pagar a ${debt.supplierName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brandRed.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Deuda total:'),
                    Text(Formatters.formatCurrency(debt.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ya pagado:', style: TextStyle(color: Colors.grey[600])),
                  Text(Formatters.formatCurrency(debt.paidAmount)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pendiente:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(Formatters.formatCurrency(debt.remainingAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandRed)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar',
                  prefixText: r'$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: methodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  prefixIcon: Icon(Icons.payments),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  amountCtrl.text = debt.remainingAmount.toStringAsFixed(0);
                },
                child: const Text('Pagar todo el saldo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(ctx, {
                'amount': amount,
                'method': methodCtrl.text.isEmpty ? 'Efectivo' : methodCtrl.text,
              });
            },
            child: const Text('Registrar Pago'),
          ),
        ],
      ),
    );

    if (result != null) {
      final amount = result['amount'] as double;
      final method = result['method'] as String;

      await DatabaseHelper.insertSupplierDebtPayment(SupplierDebtPayment(
        supplierDebtId: debt.id!,
        amount: amount,
        method: method,
      ));

      await _loadData();

      if (mounted) {
        final msg = amount >= debt.remainingAmount
            ? 'Deuda pagada completamente'
            : 'Abono de ${Formatters.formatCurrency(amount)} registrado';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $msg'),
          backgroundColor: AppTheme.successColor,
        ));
      }
    }
  }

  Future<void> _payMultipleSupplierDebts(List<SupplierDebt> debts) async {
    if (debts.isEmpty) return;

    final totalPending = debts.fold(0.0, (sum, d) => sum + d.remainingAmount);
    final amountCtrl = TextEditingController(text: totalPending.toStringAsFixed(0));
    final methodCtrl = TextEditingController(text: 'Efectivo');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pagar a ${debts.first.supplierName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${debts.length} deuda(s) seleccionada(s)', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              ...debts.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Pedido #${d.purchaseOrderId ?? "?"}', style: const TextStyle(fontSize: 12))),
                    Text(Formatters.formatCurrency(d.remainingAmount), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total pendiente:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(Formatters.formatCurrency(totalPending), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandRed)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar',
                  prefixText: r'$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: methodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  prefixIcon: Icon(Icons.payments),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(ctx, {
                'amount': amount,
                'method': methodCtrl.text.isEmpty ? 'Efectivo' : methodCtrl.text,
              });
            },
            child: const Text('Registrar Pago'),
          ),
        ],
      ),
    );

    if (result != null) {
      final amount = result['amount'] as double;
      final method = result['method'] as String;

      // Distribute payment across debts (oldest first)
      double remaining = amount;
      for (final debt in debts) {
        if (remaining <= 0) break;
        final debtAmount = debt.remainingAmount;
        final payAmount = remaining >= debtAmount ? debtAmount : remaining;

        await DatabaseHelper.insertSupplierDebtPayment(SupplierDebtPayment(
          supplierDebtId: debt.id!,
          amount: payAmount,
          method: method,
        ));

        remaining -= payAmount;
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Pago de ${Formatters.formatCurrency(amount)} registrado'),
          backgroundColor: AppTheme.successColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deudas'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Por Cobrar', icon: Icon(Icons.call_received_rounded)),
              Tab(text: 'Por Pagar', icon: Icon(Icons.call_made_rounded)),
            ],
            labelColor: AppTheme.brandRed,
            unselectedLabelColor: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
            indicatorColor: AppTheme.brandRed,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Compartir resumen',
              onPressed: _isLoading ? null : _shareOverview,
            ),
            IconButton(
              icon: const Icon(Icons.assessment_outlined),
              tooltip: 'Reporte por cliente',
              onPressed: () => context.push('/debts/report'),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.brandRed,
                child: TabBarView(
                  children: [
                    _buildReceivableTab(context, isDark),
                    _buildPayableTab(context, isDark),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await context.push<bool>('/debts/add');
            if (result == true) _loadData();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva Deuda'),
        ),
      ),
    );
  }

  Widget _buildReceivableTab(BuildContext context, bool isDark) {
    if (_receivableDebts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 32),
          EmptyState(
            icon: Icons.money_off_rounded,
            title: 'No hay deudas registradas',
          ),
        ],
      );
    }

    final totalPending = _totalReceivablePending;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Pendiente',
                value: Formatters.formatCurrency(totalPending),
                color: AppTheme.errorColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Pagado',
                value: Formatters.formatCurrency(_totalReceivablePaid),
                color: AppTheme.successColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Vencidas',
                value: '$_overdueCount',
                color: AppTheme.warningColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Section title
        Text(
          'Todas las deudas',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        // Debt cards
        ..._receivableDebts.map((debt) {
          final isOverdue = debt.status != 'paid' && debt.dueDate.isBefore(DateTime.now());
          return _DebtCard(
            debt: debt,
            isOverdue: isOverdue,
            isDark: isDark,
            statusColor: _statusColor(debt.status),
            statusLabel: _statusLabel(debt.status),
            onShare: () => _shareReceivableDebt(debt),
            onTap: () => context.push('/debts/${debt.id}'),
          );
        }),
      ],
    );
  }

  Widget _buildPayableTab(BuildContext context, bool isDark) {
    if (_supplierDebts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 32),
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No hay deudas a proveedores',
          ),
        ],
      );
    }

    final pendingDebts = _supplierDebts.where((d) => d.status != 'paid').toList();
    final paidDebts = _supplierDebts.where((d) => d.status == 'paid').toList();
    final totalPending = pendingDebts.fold(0.0, (sum, d) => sum + d.remainingAmount);
    final totalPaid = paidDebts.fold(0.0, (sum, d) => sum + d.paidAmount);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Pendiente',
                value: Formatters.formatCurrency(totalPending),
                color: AppTheme.brandRed,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Pagado',
                value: Formatters.formatCurrency(totalPaid),
                color: AppTheme.successColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Deudas',
                value: '${pendingDebts.length}',
                color: AppTheme.warningColor,
                isDark: isDark,
              ),
            ),
          ],
        ),

        // Pay All button
        if (pendingDebts.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _payMultipleSupplierDebts(pendingDebts),
              icon: const Icon(Icons.payment, size: 20),
              label: Text('Pagar Todo (${Formatters.formatCurrency(totalPending)})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        Text(
          'Deudas pendientes',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 10),

        // Pending debts with pay button
        ...pendingDebts.map((debt) {
          final isOverdue = debt.dueDate.isBefore(DateTime.now());
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _paySupplierDebt(debt),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (isOverdue ? AppTheme.errorColor : AppTheme.brandRed).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_shipping_rounded,
                          color: isOverdue ? AppTheme.errorColor : AppTheme.brandRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debt.supplierName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  'Vence: ${Formatters.formatDate(debt.dueDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOverdue
                                        ? AppTheme.errorColor
                                        : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                                  ),
                                ),
                                if (isOverdue) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'VENCIDA',
                                      style: TextStyle(fontSize: 9, color: AppTheme.errorColor, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCurrency(debt.remainingAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        // Paid debts
        if (paidDebts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Pagadas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...paidDebts.map((debt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => context.push('/suppliers/${debt.supplierId}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.supplierName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Pagado: ${Formatters.formatCurrency(debt.paidAmount)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Pagada',
                            style: TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final bool isOverdue;
  final bool isDark;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const _DebtCard({
    required this.debt,
    required this.isOverdue,
    required this.isDark,
    required this.statusColor,
    required this.statusLabel,
    required this.onShare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    debt.status == 'paid' ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.customerName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Monto: ${Formatters.formatCurrency(debt.amount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Vence: ${Formatters.formatDate(debt.dueDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue ? AppTheme.errorColor : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VENCIDA',
                                style: TextStyle(fontSize: 9, color: AppTheme.errorColor, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(debt.remainingAmount),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Compartir',
                          onPressed: onShare,
                          icon: Icon(Icons.share_outlined, size: 18, color: isDark ? AppTheme.darkIconMuted : AppTheme.lightIconMuted),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
