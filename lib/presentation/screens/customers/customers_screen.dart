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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.business_outlined),
            tooltip: 'Proveedores',
            onPressed: () => context.push('/suppliers'),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
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
              color: AppTheme.brandRed,
              child: _customers.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No hay clientes registrados',
                      actionLabel: 'Agregar Cliente',
                      onAction: () async {
                        final result = await context.push<bool>('/customers/add');
                        if (result == true) _loadCustomers();
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        return _CustomerCard(
                          customer: customer,
                          isDark: isDark,
                          onTap: () => context.push('/customers/${customer.id}'),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>('/customers/add');
          if (result == true) _loadCustomers();
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool isDark;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = customer.name.length >= 2
        ? customer.name.substring(0, 2).toUpperCase()
        : customer.name.toUpperCase();

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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.brandRed.withValues(alpha: 0.8),
                        AppTheme.brandRed,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        customer.phone ?? 'Sin teléfono',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                        ),
                      ),
                      if (customer.lastPurchase != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Última compra: ${Formatters.formatDate(customer.lastPurchase)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(customer.totalSpent),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkScaffold : AppTheme.lightScaffold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${customer.purchaseCount} compras',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? AppTheme.darkIconMuted : AppTheme.lightIconMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerSearchDelegate extends SearchDelegate<Customer?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return const EmptyState(icon: Icons.search_rounded, title: 'Buscar clientes');
    }
    return FutureBuilder<List<Customer>>(
      future: DatabaseHelper.searchCustomers(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final customers = snapshot.data!;
        if (customers.isEmpty) {
          return const EmptyState(icon: Icons.search_off_rounded, title: 'No se encontraron clientes');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          itemBuilder: (context, i) {
            final c = customers[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.brandRed.withValues(alpha: 0.1),
                child: Text(
                  c.name[0].toUpperCase(),
                  style: const TextStyle(color: AppTheme.brandRed, fontWeight: FontWeight.w600),
                ),
              ),
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
