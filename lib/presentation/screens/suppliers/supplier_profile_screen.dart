import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/purchase_order.dart';
import '../../../domain/entities/supplier.dart';

class SupplierProfileScreen extends StatefulWidget {
  final int supplierId;

  const SupplierProfileScreen({super.key, required this.supplierId});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  Supplier? _supplier;
  List<PurchaseOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final supplier = await DatabaseHelper.getSupplierById(widget.supplierId);
    final orders = await DatabaseHelper.getPurchaseOrdersBySupplier(widget.supplierId);
    setState(() {
      _supplier = supplier;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_supplier == null) return Scaffold(
      appBar: AppBar(title: const Text('Proveedor')),
      body: const Center(child: Text('Proveedor no encontrado')),
    );

    final supplier = _supplier!;

    return Scaffold(
      appBar: AppBar(title: Text(supplier.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      supplier.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(supplier.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  if (supplier.phone != null)
                    Text(supplier.phone!, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            // Contact info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (supplier.contactPerson != null)
                        _infoRow(Icons.person, 'Contacto', supplier.contactPerson!),
                      if (supplier.email != null)
                        _infoRow(Icons.email, 'Email', supplier.email!),
                      if (supplier.address != null)
                        _infoRow(Icons.location_on, 'Dirección', supplier.address!),
                      _infoRow(Icons.date_range, 'Registrado', Formatters.formatDate(supplier.createdAt)),
                    ],
                  ),
                ),
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _statCard('Total Comprado', Formatters.formatCurrency(supplier.totalPurchases), AppTheme.primaryColor)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/suppliers/payments'),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Pagos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await context.push<bool>('/purchase-orders/add');
                        if (result == true) _loadData();
                      },
                      icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                      label: const Text('Nuevo Pedido'),
                    ),
                  ),
                ],
              ),
            ),

            // Order history
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Historial de Pedidos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push('/purchase-orders'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Sin pedidos registrados')),
                  ),
                ),
              )
            else
              ..._orders.map((order) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: _statusColor(order.status).withValues(alpha: 0.1),
                    child: Icon(
                      order.isPending ? Icons.schedule : order.isReceived ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: _statusColor(order.status),
                    ),
                  ),
                  title: Text('${Formatters.formatDate(order.date)} - ${order.items.length} productos',
                    style: const TextStyle(fontSize: 13)),
                  subtitle: Text(_statusLabel(order.status),
                    style: TextStyle(fontSize: 11, color: _statusColor(order.status))),
                  trailing: Text(Formatters.formatCurrency(order.total),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () => context.push('/purchase-orders'),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
