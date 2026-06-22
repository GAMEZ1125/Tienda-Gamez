import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/supplier.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final suppliers = await DatabaseHelper.getAllSuppliers();
    setState(() {
      _suppliers = suppliers;
      _filteredSuppliers = suppliers;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      _filteredSuppliers = _suppliers.where((s) =>
        s.name.toLowerCase().contains(query.toLowerCase()) ||
        (s.phone?.contains(query) ?? false)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar proveedor...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _search,
                  ),
                ),
                Expanded(
                  child: _filteredSuppliers.isEmpty
                      ? EmptyState(
                          icon: Icons.business_outlined,
                          title: 'No hay proveedores',
                          actionLabel: 'Agregar Proveedor',
                          onAction: () async {
                            final result = await context.push<bool>('/suppliers/add');
                            if (result == true) _loadSuppliers();
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSuppliers,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _filteredSuppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = _filteredSuppliers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      supplier.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(supplier.name),
                                  subtitle: Text(supplier.phone ?? 'Sin teléfono'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.push('/suppliers/${supplier.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>('/suppliers/add');
          if (result == true) _loadSuppliers();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
