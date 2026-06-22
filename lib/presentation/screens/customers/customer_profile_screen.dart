import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/sale.dart';

class CustomerProfileScreen extends StatefulWidget {
  final int customerId;

  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Customer? _customer;
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final customer = await DatabaseHelper.getCustomerById(widget.customerId);
    final sales = await DatabaseHelper.getSalesByCustomer(widget.customerId);
    setState(() {
      _customer = customer;
      _sales = sales;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_customer == null) return Scaffold(appBar: AppBar(title: const Text('Cliente')), body: const Center(child: Text('Cliente no encontrado')));

    final customer = _customer!;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await context.push<bool>('/customers/edit/${widget.customerId}');
              if (result == true) _loadData();
            },
          ),
        ],
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
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        customer.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      customer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (customer.phone != null)
                      Text(customer.phone!, style: const TextStyle(color: Colors.white70)),
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
                        if (customer.email != null)
                          _infoRow(Icons.email, 'Email', customer.email!),
                        if (customer.address != null)
                          _infoRow(Icons.location_on, 'Dirección', customer.address!),
                        _infoRow(Icons.date_range, 'Registrado', Formatters.formatDate(customer.createdAt)),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _statCard('Total Gastado', Formatters.formatCurrency(customer.totalSpent), AppTheme.primaryColor)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Compras', '${customer.purchaseCount}', AppTheme.successColor)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Última Compra', customer.lastPurchase != null ? Formatters.formatDate(customer.lastPurchase) : '-', AppTheme.warningColor)),
                  ],
                ),
              ),

              // Sales history
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Historial de Compras',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (_sales.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Sin compras registradas',
                  ),
                )
              else
                ...(_sales.map((sale) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check, color: AppTheme.successColor),
                    ),
                    title: Text(Formatters.formatDateTime(sale.date)),
                    subtitle: Text('${sale.items.length} productos - ${sale.paymentMethod}'),
                    trailing: Text(
                      Formatters.formatCurrency(sale.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ))),
            ],
          ),
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
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
