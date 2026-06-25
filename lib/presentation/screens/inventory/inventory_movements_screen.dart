import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/inventory_movement.dart';

class InventoryMovementsScreen extends StatefulWidget {
  const InventoryMovementsScreen({super.key});

  @override
  State<InventoryMovementsScreen> createState() => _InventoryMovementsScreenState();
}

class _InventoryMovementsScreenState extends State<InventoryMovementsScreen> {
  List<InventoryMovement> _movements = [];
  List<InventoryMovement> _filteredMovements = [];
  bool _isLoading = true;
  String _selectedType = 'Todos';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);
    final movements = await DatabaseHelper.getAllInventoryMovements();
    setState(() {
      _movements = movements;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = List<InventoryMovement>.from(_movements);

    if (_selectedType != 'Todos') {
      filtered = filtered.where((m) => m.typeLabel == _selectedType).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((m) => m.productName.toLowerCase().contains(query) || (m.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    setState(() => _filteredMovements = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar',
            onPressed: () => _showSearch(context),
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
                          label: 'Todos',
                          icon: Icons.inventory_2_rounded,
                          selected: _selectedType == 'Todos',
                          color: AppTheme.brandRed,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedType = 'Todos';
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Ventas',
                          icon: Icons.shopping_cart_rounded,
                          selected: _selectedType == 'Venta',
                          color: AppTheme.errorColor,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedType = 'Venta';
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Recepciones',
                          icon: Icons.local_shipping_rounded,
                          selected: _selectedType == 'Recepción de Pedido',
                          color: AppTheme.successColor,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedType = 'Recepción de Pedido';
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Ajustes',
                          icon: Icons.tune_rounded,
                          selected: _selectedType == 'Ajuste Manual' || _selectedType == 'Ajuste',
                          color: AppTheme.accentBlue,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedType = _selectedType == 'Ajustes' ? 'Todos' : 'Ajustes';
                              _applyFilters();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Count
                if (_filteredMovements.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredMovements.length} movimiento(s)',
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

                // Movements list
                Expanded(
                  child: _filteredMovements.isEmpty
                      ? EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No hay movimientos',
                          subtitle: 'Los movimientos de inventario aparecerán aquí',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMovements,
                          color: AppTheme.brandRed,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filteredMovements.length,
                            itemBuilder: (context, index) {
                              final movement = _filteredMovements[index];
                              return _MovementCard(
                                movement: movement,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch<void>(
      context: context,
      delegate: _MovementSearchDelegate(_movements),
    ).then((_) => _loadMovements());
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

class _MovementCard extends StatelessWidget {
  final InventoryMovement movement;
  final bool isDark;

  const _MovementCard({
    required this.movement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = movement.isPositive ? AppTheme.successColor : AppTheme.errorColor;
    final deltaIcon = movement.isPositive ? Icons.add_rounded : Icons.remove_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(deltaIcon, color: deltaColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.productName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${movement.typeLabel} · ${Formatters.formatDate(movement.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                    ),
                  ),
                  if (movement.description != null && movement.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      movement.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${movement.isPositive ? '+' : ''}${movement.quantityDelta.toStringAsFixed(movement.quantityDelta.truncateToDouble() == movement.quantityDelta ? 0 : 3)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: deltaColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${movement.previousStock.toStringAsFixed(movement.previousStock.truncateToDouble() == movement.previousStock ? 0 : 3)} → ${movement.newStock.toStringAsFixed(movement.newStock.truncateToDouble() == movement.newStock ? 0 : 3)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementSearchDelegate extends SearchDelegate<void> {
  final List<InventoryMovement> movements;

  _MovementSearchDelegate(this.movements);

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
        title: 'Busca por nombre de producto',
      );
    }

    final filtered = movements
        .where((m) => m.productName.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No se encontraron movimientos',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final movement = filtered[index];
        final deltaColor = movement.isPositive ? AppTheme.successColor : AppTheme.errorColor;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: deltaColor.withValues(alpha: 0.1),
            child: Icon(
              movement.isPositive ? Icons.add_rounded : Icons.remove_rounded,
              color: deltaColor,
            ),
          ),
          title: Text(movement.productName),
          subtitle: Text('${movement.typeLabel} · ${Formatters.formatDate(movement.createdAt)}'),
          trailing: Text(
            '${movement.isPositive ? '+' : ''}${movement.quantityDelta.toStringAsFixed(movement.quantityDelta.truncateToDouble() == movement.quantityDelta ? 0 : 3)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: deltaColor),
          ),
          onTap: () => close(context, null),
        );
      },
    );
  }
}
