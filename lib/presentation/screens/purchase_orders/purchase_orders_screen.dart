import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/purchase_order.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  List<PurchaseOrder> _orders = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    List<PurchaseOrder> orders;
    if (_statusFilter == 'all') {
      orders = await DatabaseHelper.getAllPurchaseOrders();
    } else {
      orders = await DatabaseHelper.getPurchaseOrdersByStatus(_statusFilter);
    }
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppTheme.warningColor;
      case 'received': return AppTheme.successColor;
      case 'cancelled': return AppTheme.errorColor;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'received': return 'Recibido';
      case 'cancelled': return 'Anulado';
      default: return status;
    }
  }

  Future<void> _markReceived(PurchaseOrder order) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await DatabaseHelper.updatePurchaseOrderStatus(order.id!, 'received');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Pedido recibido — stock y costo actualizados'),
          backgroundColor: AppTheme.successColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelOrder(PurchaseOrder order) async {
    if (_isProcessing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Pedido'),
        content: Text('¿Anular pedido a ${order.supplierName} por ${Formatters.formatCurrency(order.total)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, anular'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await DatabaseHelper.updatePurchaseOrderStatus(order.id!, 'cancelled');
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pedido anulado'),
            backgroundColor: AppTheme.warningColor,
          ));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _editOrder(PurchaseOrder order) async {
    if (!order.isPending) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Solo se pueden editar pedidos pendientes'),
        backgroundColor: AppTheme.warningColor,
      ));
      return;
    }
    final result = await context.push<bool>('/purchase-orders/edit/${order.id}');
    if (result == true) _load();
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() => _statusFilter = value);
        _load();
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, PurchaseOrder order) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final statusColor = _statusColor(order.status);
        final metaText = '${Formatters.formatDate(order.date)} • ${order.items.length} productos';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showOrderDetail(context, order),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: statusColor.withValues(alpha: 0.1),
                              child: Icon(
                                order.isPending ? Icons.schedule : order.isReceived ? Icons.check_circle : Icons.cancel,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order.supplierName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(metaText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Column(
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
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _statusLabel(order.status),
                                    style: TextStyle(fontSize: 11, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (order.isPending) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isProcessing ? null : () => _editOrder(order),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Editar'),
                              ),
                              FilledButton.icon(
                                onPressed: _isProcessing ? null : () => _markReceived(order),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Recibido'),
                                style: FilledButton.styleFrom(backgroundColor: AppTheme.successColor),
                              ),
                              TextButton.icon(
                                onPressed: _isProcessing ? null : () => _cancelOrder(order),
                                icon: const Icon(Icons.cancel_outlined, size: 18),
                                label: const Text('Anular'),
                                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                              ),
                            ],
                          ),
                        ],
                      ],
                    )
                  : ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        child: Icon(
                          order.isPending ? Icons.schedule : order.isReceived ? Icons.check_circle : Icons.cancel,
                          color: statusColor,
                        ),
                      ),
                      title: Text(order.supplierName),
                      subtitle: Text(metaText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
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
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _statusLabel(order.status),
                                  style: TextStyle(fontSize: 11, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          if (order.isPending) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Editar pedido',
                              onPressed: _isProcessing ? null : () => _editOrder(order),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: AppTheme.successColor),
                              tooltip: 'Marcar como recibido',
                              onPressed: _isProcessing ? null : () => _markReceived(order),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
                              tooltip: 'Anular pedido',
                              onPressed: _isProcessing ? null : () => _cancelOrder(order),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showOrderDetail(BuildContext context, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pedido: ${order.supplierName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${Formatters.formatDate(order.date)}', style: const TextStyle(fontSize: 13)),
              Text('Estado: ${_statusLabel(order.status)}', style: TextStyle(fontSize: 13, color: _statusColor(order.status))),
              if (order.notes != null) Text('Notas: ${order.notes}', style: const TextStyle(fontSize: 13)),
              const Divider(),
              const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 12))),
                    Text('x${item.quantity}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(Formatters.formatCurrency(item.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Subtotal'), Text(Formatters.formatCurrency(order.subtotal)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total'), Text(Formatters.formatCurrency(order.total), style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
        actions: [
          if (order.isPending) ...[
            FilledButton.icon(
              onPressed: () { Navigator.pop(ctx); _markReceived(order); },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Recibido'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.successColor),
            ),
            TextButton.icon(
              onPressed: () { Navigator.pop(ctx); _cancelOrder(order); },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Anular'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            ),
          ],
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos a Proveedores'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Todas', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('Pendientes', 'pending'),
                  const SizedBox(width: 8),
                  _filterChip('Recibidos', 'received'),
                  const SizedBox(width: 8),
                  _filterChip('Anulados', 'cancelled'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const EmptyState(icon: Icons.inbox_outlined, title: 'Sin pedidos')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _orders.length,
                          itemBuilder: (ctx, i) {
                            final order = _orders[i];
                            return _buildOrderCard(context, order);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final compact = MediaQuery.of(context).size.width < 420;
          if (compact) {
            return FloatingActionButton(
              onPressed: () async {
                final result = await context.push<bool>('/purchase-orders/add');
                if (result == true) _load();
              },
              child: const Icon(Icons.add),
            );
          }
          return FloatingActionButton.extended(
            onPressed: () async {
              final result = await context.push<bool>('/purchase-orders/add');
              if (result == true) _load();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Pedido'),
          );
        },
      ),
    );
  }
}
