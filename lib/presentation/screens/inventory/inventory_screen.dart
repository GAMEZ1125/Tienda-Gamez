import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_category.dart';
import 'csv_import_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<ProductCategory> _categories = [];
  bool _isLoading = true;
  bool _showLowStockOnly = false;
  String _selectedCategory = 'Todas';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.getAllProductsIncludingInactive();
    final cats = await DatabaseHelper.getAllCategories();
    setState(() {
      _products = products;
      _categories = cats;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = List<Product>.from(_products);

    if (_showLowStockOnly) {
      filtered = filtered.where((p) => p.isLowStock).toList();
    }

    if (_selectedCategory != 'Todas') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(query) || (p.barcode?.contains(query) ?? false))
          .toList();
    }

    setState(() => _filteredProducts = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _products.where((p) => p.isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          if (lowStockCount > 0)
            Badge(
              label: Text('$lowStockCount'),
              child: IconButton(
                icon: const Icon(Icons.warning_amber_outlined),
                onPressed: () {
                  setState(() {
                    _showLowStockOnly = true;
                    _applyFilters();
                  });
                },
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import_csv') {
                _openCsvImport();
              } else if (value == 'categories') {
                context.push('/categories');
              } else if (value == 'purchase_orders') {
                context.push('/purchase-orders');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'categories',
                child: ListTile(
                  leading: Icon(Icons.category_outlined),
                  title: Text('Categorías'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'purchase_orders',
                child: ListTile(
                  leading: Icon(Icons.inbox_outlined),
                  title: Text('Pedidos a Proveedores'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import_csv',
                child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text('Importar CSV'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('Stock Bajo'),
                                selected: _showLowStockOnly,
                                onSelected: (v) {
                                  setState(() {
                                    _showLowStockOnly = v;
                                    _applyFilters();
                                  });
                                },
                                avatar: Icon(Icons.warning, size: 16, color: _showLowStockOnly ? Colors.white : AppTheme.warningColor),
                              ),
                              const SizedBox(width: 8),
                              ...['Todas', ..._categories.map((c) => c.name)].map((cat) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(cat),
                                    selected: _selectedCategory == cat,
                                    onSelected: (v) {
                                      setState(() {
                                        _selectedCategory = cat;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Low stock warning
                if (_showLowStockOnly && lowStockCount > 0)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppTheme.warningColor),
                        const SizedBox(width: 8),
                        Text(
                          '$lowStockCount productos con stock bajo',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                // Products list
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No hay productos',
                          subtitle: _showLowStockOnly
                              ? 'No hay productos con stock bajo'
                              : 'Agrega tu primer producto',
                          actionLabel: 'Agregar Producto',
                          onAction: () => context.push('/inventory/add'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: product.isActive
                                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: product.isActive ? AppTheme.primaryColor : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    product.name,
                                    style: TextStyle(
                                      color: product.isActive ? null : Colors.grey,
                                      decoration: product.isActive ? null : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(product.category ?? 'Sin categoría'),
                                      const SizedBox(width: 12),
                                      if (product.barcode != null)
                                        Text('Cód: ${product.barcode}', style: const TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Formatters.formatCurrency(product.price),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: product.isLowStock
                                              ? AppTheme.warningColor.withValues(alpha: 0.1)
                                              : AppTheme.successColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Stock: ${product.stock}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: product.isLowStock
                                                ? AppTheme.warningColor
                                                : AppTheme.successColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => context.push('/inventory/edit/${product.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openCsvImport() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CsvImportScreen()),
    );
    if (result == true && mounted) {
      _loadProducts();
    }
  }

  void _showSearch(BuildContext context) {
    showSearch<Product?>(
      context: context,
      delegate: _ProductSearchDelegate(),
    ).then((product) {
      if (!mounted) return;
      _loadProducts();
      if (product != null) {
        context.push('/inventory/edit/${product.id}');
      }
    });
  }
}

class _ProductSearchDelegate extends SearchDelegate<Product?> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchList(context);

  Widget _buildSearchList(BuildContext context) {
    if (query.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Busca productos por nombre o código',
      );
    }

    return FutureBuilder<List<Product>>(
      future: DatabaseHelper.searchProducts(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!;
        if (products.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No se encontraron productos',
          );
        }
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.inventory_2, color: AppTheme.primaryColor),
              ),
              title: Text(product.name),
              subtitle: Text('${Formatters.formatCurrency(product.price)} - Stock: ${product.stock}'),
              onTap: () => close(context, product),
            );
          },
        );
      },
    );
  }
}
