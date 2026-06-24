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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          if (lowStockCount > 0)
            Badge(
              label: Text('$lowStockCount'),
              backgroundColor: AppTheme.warningColor,
              child: IconButton(
                icon: const Icon(Icons.warning_amber_rounded),
                onPressed: () {
                  setState(() {
                    _showLowStockOnly = !_showLowStockOnly;
                    _applyFilters();
                  });
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar producto',
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Importar CSV',
            onPressed: _openCsvImport,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'categories') {
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
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('Pedidos a Proveedores'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Stock Bajo',
                          icon: Icons.warning_amber_rounded,
                          selected: _showLowStockOnly,
                          color: AppTheme.warningColor,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _showLowStockOnly = !_showLowStockOnly;
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Todos',
                          icon: Icons.inventory_2_rounded,
                          selected: _selectedCategory == 'Todas',
                          color: AppTheme.brandRed,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Todas';
                              _applyFilters();
                            });
                          },
                        ),
                        ..._categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: cat.name,
                            icon: Icons.label_outline_rounded,
                            selected: _selectedCategory == cat.name,
                            color: AppTheme.brandRed,
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat.name;
                                _applyFilters();
                              });
                            },
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

                // Low stock warning
                if (_showLowStockOnly && lowStockCount > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$lowStockCount productos con stock bajo',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Products count
                if (_filteredProducts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredProducts.length} producto(s)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

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
                          color: AppTheme.brandRed,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return _ProductCard(
                                product: product,
                                isDark: isDark,
                                onTap: () => context.push('/inventory/edit/${product.id}'),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Producto'),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? color.withValues(alpha: 0.1)
          : (isDark ? AppTheme.darkScaffold : AppTheme.lightScaffold),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.3)
                  : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? color
                    : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? color
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stockColor = product.isLowStock ? AppTheme.warningColor : AppTheme.successColor;

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
                    color: product.isActive
                        ? AppTheme.brandRed.withValues(alpha: 0.1)
                        : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: product.isActive
                        ? AppTheme.brandRed
                        : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: product.isActive
                              ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
                              : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                          decoration: product.isActive ? null : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            product.category ?? 'Sin categoría',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                            ),
                          ),
                          if (product.barcode != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkScaffold : AppTheme.lightScaffold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.barcode!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                                ),
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
                      Formatters.formatCurrency(product.price),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          fontSize: 11,
                          color: stockColor,
                          fontWeight: FontWeight.w600,
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

class _ProductSearchDelegate extends SearchDelegate<Product?> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
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
        icon: Icons.search_rounded,
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
            icon: Icons.search_off_rounded,
            title: 'No se encontraron productos',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.brandRed.withValues(alpha: 0.1),
                child: const Icon(Icons.inventory_2_rounded, color: AppTheme.brandRed),
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
