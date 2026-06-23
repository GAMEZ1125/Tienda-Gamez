import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/purchase_order.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _receivableDebts = [];
  List<PurchaseOrder> _payableOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      DatabaseHelper.getAllDebts(),
      DatabaseHelper.getPendingPurchaseOrders(),
    ]);
    if (!mounted) return;
    setState(() {
      _receivableDebts = results[0] as List<Debt>;
      _payableOrders = results[1] as List<PurchaseOrder>;
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

  double get _totalReceivablePending =>
      _receivableDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);

  double get _totalReceivablePaid =>
      _receivableDebts.fold(0.0, (sum, debt) => sum + debt.paidAmount);

  double get _totalPayablePending =>
      _payableOrders.fold(0.0, (sum, order) => sum + order.total);

  int get _overdueCount => _receivableDebts
      .where((debt) => debt.status != 'paid' && debt.dueDate.isBefore(DateTime.now()))
      .length;

  Future<void> _shareOverview() async {
    final buffer = StringBuffer()
      ..writeln('Tienda Gamez - Resumen de deudas')
      ..writeln('Fecha: ${Formatters.formatDateTime(DateTime.now())}')
      ..writeln('')
      ..writeln('Por cobrar:')
      ..writeln('- Total pendiente: ${Formatters.formatCurrency(_totalReceivablePending)}')
      ..writeln('- Total pagado: ${Formatters.formatCurrency(_totalReceivablePaid)}')
      ..writeln('- Vencidas: $_overdueCount')
      ..writeln('')
      ..writeln('Por pagar:')
      ..writeln('- Total pendiente: ${Formatters.formatCurrency(_totalPayablePending)}')
      ..writeln('- Pedidos pendientes: ${_payableOrders.length}');

    await Share.share(buffer.toString(), subject: 'Resumen de deudas - Tienda Gamez');
  }

  Future<void> _shareReceivableDebt(Debt debt) async {
    final buffer = StringBuffer()
      ..writeln('Tienda Gamez - Estado de deuda')
      ..writeln('Cliente: ${debt.customerName}')
      ..writeln('Monto total: ${Formatters.formatCurrency(debt.amount)}')
      ..writeln('Pagado: ${Formatters.formatCurrency(debt.paidAmount)}')
      ..writeln('Pendiente: ${Formatters.formatCurrency(debt.remainingAmount)}')
      ..writeln('Vencimiento: ${Formatters.formatDate(debt.dueDate)}')
      ..writeln('Estado: ${_statusLabel(debt.status)}');

    await Share.share(buffer.toString(), subject: 'Estado de deuda - ${debt.customerName}');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deudas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Por Cobrar', icon: Icon(Icons.call_received)),
              Tab(text: 'Por Pagar', icon: Icon(Icons.call_made)),
            ],
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
                child: TabBarView(
                  children: [
                    _buildReceivableTab(context),
                    _buildPayableTab(context),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await context.push<bool>('/debts/add');
            if (result == true) _loadData();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildReceivableTab(BuildContext context) {
    if (_receivableDebts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 32),
          EmptyState(
            icon: Icons.money_off,
            title: 'No hay deudas registradas',
          ),
        ],
      );
    }

    final totalPending = _totalReceivablePending;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard('Pendiente', Formatters.formatCurrency(totalPending), AppTheme.errorColor),
            _summaryCard('Pagado', Formatters.formatCurrency(_totalReceivablePaid), AppTheme.successColor),
            _summaryCard('Vencidas', '$_overdueCount', AppTheme.warningColor),
          ],
        ),
        const SizedBox(height: 16),
        ..._receivableDebts.map((debt) {
          final isOverdue = debt.status != 'paid' && debt.dueDate.isBefore(DateTime.now());
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => context.push('/debts/${debt.id}'),
              borderRadius: BorderRadius.circular(12),
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
                          Text(
                            'Monto: ${Formatters.formatCurrency(debt.amount)}',
                            style: const TextStyle(fontSize: 12),
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
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Compartir deuda',
                              onPressed: () => _shareReceivableDebt(debt),
                              icon: const Icon(Icons.share_outlined, size: 18),
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
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPayableTab(BuildContext context) {
    if (_payableOrders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 32),
          EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No hay pedidos pendientes',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard('Pendiente', Formatters.formatCurrency(_totalPayablePending), AppTheme.primaryColor),
            _summaryCard('Órdenes', '${_payableOrders.length}', AppTheme.warningColor),
          ],
        ),
        const SizedBox(height: 16),
        ..._payableOrders.map((order) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Icon(Icons.local_shipping_outlined, color: AppTheme.primaryColor),
              ),
              title: Text(order.supplierName),
              subtitle: Text(
                '${Formatters.formatDate(order.date)} • ${order.items.length} productos',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(order.total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Pendiente',
                      style: TextStyle(fontSize: 11, color: AppTheme.warningColor),
                    ),
                  ),
                ],
              ),
              onTap: () => context.push('/purchase-orders'),
            ),
          );
        }),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
