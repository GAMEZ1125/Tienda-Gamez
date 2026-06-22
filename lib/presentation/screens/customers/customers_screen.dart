import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/customer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await DatabaseHelper.getAllCustomers();
    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch<Customer?>(
              context: context,
              delegate: _CustomerSearchDelegate(),
            ).then((customer) {
              if (!mounted) return;
              _loadCustomers();
              if (customer != null && customer.id != null) {
                context.push('/customers/${customer.id}');
              }
            }),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCustomers,
              child: _customers.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: 'No hay clientes registrados',
                      actionLabel: 'Agregar Cliente',
                      onAction: () async {
                        final result = await context.push<bool>('/customers/add');
                        if (result == true) _loadCustomers();
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                customer.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(customer.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.phone ?? 'Sin teléfono'),
                                if (customer.lastPurchase != null)
                                  Text(
                                    'Última compra: ${Formatters.formatDate(customer.lastPurchase)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatCurrency(customer.totalSpent),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                Text(
                                  '${customer.purchaseCount} compras',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () => context.push('/customers/${customer.id}'),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/customers/add');
          if (result == true) _loadCustomers();
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _CustomerSearchDelegate extends SearchDelegate<Customer?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return const EmptyState(icon: Icons.search, title: 'Buscar clientes');
    }
    return FutureBuilder<List<Customer>>(
      future: DatabaseHelper.searchCustomers(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final customers = snapshot.data!;
        if (customers.isEmpty) {
          return const EmptyState(icon: Icons.search_off, title: 'No se encontraron clientes');
        }
        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, i) {
            final c = customers[i];
            return ListTile(
              leading: CircleAvatar(child: Text(c.name[0])),
              title: Text(c.name),
              subtitle: Text(c.phone ?? ''),
              onTap: () => close(context, c),
            );
          },
        );
      },
    );
  }
}
