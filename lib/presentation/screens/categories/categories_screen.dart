import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/product_category.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<ProductCategory> _categories = [];
  List<ProductCategory> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final categories = await DatabaseHelper.getAllCategories();
    setState(() {
      _categories = categories;
      _filtered = categories;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _categories;
      } else {
        final q = query.toLowerCase();
        _filtered = _categories.where((c) =>
          c.name.toLowerCase().contains(q) ||
          (c.description?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
    });
  }

  Future<void> _delete(ProductCategory cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Eliminar "${cat.name}"?\nLos productos con esta categoría no se verán afectados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.deleteCategory(cat.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar categoría...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _search('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _search,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: _searchCtrl.text.isEmpty ? 'Sin categorías' : 'Sin resultados',
                          subtitle: _searchCtrl.text.isEmpty ? null : 'Intenta con otro término',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final cat = _filtered[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: Icon(Icons.category, color: AppTheme.primaryColor),
                                  ),
                                  title: Text(cat.name),
                                  subtitle: cat.description != null ? Text(cat.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () async {
                                          final result = await context.push<bool>('/categories/edit/${cat.id}');
                                          if (result == true) _load();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor),
                                        onPressed: () => _delete(cat),
                                      ),
                                    ],
                                  ),
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
          final result = await context.push<bool>('/categories/add');
          if (result == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
