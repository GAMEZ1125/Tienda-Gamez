import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ticket_receipt_dialog.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_variation.dart';
import '../../../domain/entities/sale.dart';
import '../scanner_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _searchController = TextEditingController();
  final CartBloc _cartBloc = CartBloc();
  List<_ProductItem> _allItems = [];
  List<_ProductItem> _visibleItems = [];
  bool _isLoadingProducts = true;
  _ProductViewMode _viewMode = _ProductViewMode.card;

  @override
  void dispose() {
    _searchController.dispose();
    _cartBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseHelper.getAllProducts();
    final items = <_ProductItem>[];

    for (final product in products) {
      // Always add the main product
      items.add(_ProductItem(
        product: product,
        variation: null,
        displayName: product.unitsPerPackage > 1
            ? '${product.name} (Cubeta completa)'
            : product.name,
      ));

      // Add variations
      final variations = await DatabaseHelper.getVariationsByProduct(product.id!);
      for (final v in variations.where((v) => v.isActive)) {
        items.add(_ProductItem(
          product: product,
          variation: v,
          displayName: '${product.name} - ${v.name}',
        ));
      }
    }

    setState(() {
      _allItems = items;
      _applyFilter(_searchController.text);
      _isLoadingProducts = false;
    });
  }

  void _applyFilter(String query) {
    final normalized = query.trim().toLowerCase();
    _visibleItems = normalized.isEmpty
        ? List<_ProductItem>.from(_allItems)
        : _allItems.where((item) {
            return item.displayName.toLowerCase().contains(normalized) ||
                (item.product.category?.toLowerCase().contains(normalized) ?? false) ||
                (item.product.barcode?.toLowerCase().contains(normalized) ?? false) ||
                (item.variation?.barcode?.toLowerCase().contains(normalized) ?? false);
          }).toList();
  }

  Future<void> _openScanner() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen(
        title: 'Escanear Producto',
      )),
    );

    if (barcode == null || !mounted) return;

    // Check main product barcode
    final product = await DatabaseHelper.getProductByBarcode(barcode);
    if (product != null) {
      if (!mounted) return;
      if (product.stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agotado'), backgroundColor: AppTheme.errorColor),
        );
        return;
      }
      _addToCart(_ProductItem(product: product, variation: null, displayName: product.name));
      return;
    }

    // Check variation barcode
    final variation = await DatabaseHelper.getVariationByBarcode(barcode);
    if (variation != null) {
      final parentProduct = await DatabaseHelper.getProductById(variation.productId);
      if (parentProduct != null && mounted) {
        _addToCart(_ProductItem(
          product: parentProduct,
          variation: variation,
          displayName: '${parentProduct.name} - ${variation.name}',
        ));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto no encontrado: $barcode'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }
  }

  void _addToCart(_ProductItem item) {
    final product = item.product;
    final variation = item.variation;

    if (variation != null) {
      // Check effective stock for variation
      final unitsPerPkg = product.unitsPerPackage;
      final unitsPerPres = variation.unitsPerPresentation;
      double effectiveStock;
      if (unitsPerPkg > 1) {
        effectiveStock = product.stock * unitsPerPkg;
      } else {
        effectiveStock = product.stock * unitsPerPres;
      }
      if (effectiveStock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Variación agotada'), backgroundColor: AppTheme.errorColor),
        );
        return;
      }

      final variationProduct = product.copyWith(
        price: variation.price,
        cost: variation.cost > 0 ? variation.cost : product.cost,
        stock: effectiveStock,
      );
      _cartBloc.add(AddProductToCart(variationProduct));
    } else {
      if (product.stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agotado'), backgroundColor: AppTheme.errorColor),
        );
        return;
      }
      _cartBloc.add(AddProductToCart(product));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.displayName} agregado'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cartBloc,
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Punto de Venta'),
              actions: [
                IconButton(
                  icon: Icon(_viewMode == _ProductViewMode.card ? Icons.view_list : Icons.grid_view),
                  tooltip: _viewMode == _ProductViewMode.card ? 'Ver lista' : 'Ver tarjetas',
                  onPressed: () => setState(() {
                    _viewMode = _viewMode == _ProductViewMode.card
                        ? _ProductViewMode.list
                        : _ProductViewMode.card;
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Historial de Ventas',
                  onPressed: () => _showSalesHistory(context),
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar producto...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _applyFilter('');
                                      });
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: _openScanner,
                                    tooltip: 'Escanear código de barras',
                                  ),
                          ),
                          onChanged: (value) => setState(() => _applyFilter(value)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingProducts
                      ? const Center(child: CircularProgressIndicator())
                      : _visibleItems.isEmpty
                          ? EmptyState(
                              icon: Icons.shopping_bag_outlined,
                              title: _searchController.text.isEmpty
                                  ? 'No hay productos activos'
                                  : 'No se encontraron productos',
                              subtitle: _searchController.text.isEmpty
                                  ? 'Agrega o activa productos desde inventario'
                                  : 'Usa el buscador o escanea un código de barras',
                            )
                          : _viewMode == _ProductViewMode.card
                              ? GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
                                    childAspectRatio: 0.82,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _visibleItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _visibleItems[index];
                                    return _ProductCard(
                                      item: item,
                                      onTap: () => _addToCart(item),
                                    );
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _visibleItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _visibleItems[index];
                                    return _ProductListTile(
                                      item: item,
                                      onTap: () => _addToCart(item),
                                    );
                                  },
                                ),
                ),
                if (cartState.items.isNotEmpty)
                  _CartSummary(cartState: cartState),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSalesHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SalesHistorySheet(),
    );
  }
}

class _ProductItem {
  final Product product;
  final ProductVariation? variation;
  final String displayName;

  const _ProductItem({
    required this.product,
    this.variation,
    required this.displayName,
  });

  double get price => variation?.price ?? product.price;
  String? get imagePath => variation?.imagePath ?? product.imagePath;
  bool get isOutOfStock {
    if (variation != null) {
      final unitsPerPkg = product.unitsPerPackage;
      final unitsPerPres = variation!.unitsPerPresentation;
      if (unitsPerPkg > 1) {
        return product.stock * unitsPerPkg <= 0;
      }
      return product.stock * unitsPerPres <= 0;
    }
    return product.isOutOfStock;
  }
}

class _ProductCard extends StatelessWidget {
  final _ProductItem item;
  final VoidCallback onTap;

  const _ProductCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isVariation = item.variation != null;
    final displayPrice = item.price;
    final product = item.product;

    String stockText;
    if (isVariation) {
      final unitsPerPkg = product.unitsPerPackage;
      final unitsPerPres = item.variation!.unitsPerPresentation;
      double effectiveStock;
      if (unitsPerPkg > 1) {
        effectiveStock = product.stock * unitsPerPkg;
      } else {
        effectiveStock = product.stock * unitsPerPres;
      }
      stockText = 'Stock: ${effectiveStock % 1 == 0 ? effectiveStock.toInt() : effectiveStock.toStringAsFixed(0)}';
    } else if (product.unitsPerPackage > 1) {
      stockText = '${product.stock.toInt()} paquetes';
    } else {
      stockText = 'Stock: ${product.stock % 1 == 0 ? product.stock.toInt() : product.stock.toStringAsFixed(0)}';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: item.isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: item.isOutOfStock ? 0.4 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: AppTheme.pearl,
                      child: _ProductImage(imagePath: item.imagePath),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(displayPrice),
                  style: TextStyle(
                    fontSize: 14,
                    color: isVariation ? AppTheme.accentEmerald : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 12,
                      color: item.isOutOfStock ? AppTheme.errorColor : Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      stockText,
                      style: TextStyle(
                        fontSize: 11,
                        color: item.isOutOfStock ? AppTheme.errorColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final _ProductItem item;
  final VoidCallback onTap;

  const _ProductListTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isVariation = item.variation != null;
    final product = item.product;

    String stockText;
    if (isVariation) {
      final unitsPerPkg = product.unitsPerPackage;
      final unitsPerPres = item.variation!.unitsPerPresentation;
      double effectiveStock;
      if (unitsPerPkg > 1) {
        effectiveStock = product.stock * unitsPerPkg;
      } else {
        effectiveStock = product.stock * unitsPerPres;
      }
      stockText = '${effectiveStock % 1 == 0 ? effectiveStock.toInt() : effectiveStock.toStringAsFixed(0)} uds';
    } else if (product.unitsPerPackage > 1) {
      stockText = '${product.stock.toInt()} paquetes';
    } else {
      stockText = '${product.stock % 1 == 0 ? product.stock.toInt() : product.stock.toStringAsFixed(0)} uds';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: item.isOutOfStock ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: AppTheme.pearl,
            child: _ProductImage(imagePath: item.imagePath),
          ),
        ),
        title: Text(
          item.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          '${Formatters.formatCurrency(item.price)} · $stockText',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isVariation ? AppTheme.accentEmerald : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          item.isOutOfStock ? Icons.block : Icons.add_shopping_cart,
          color: item.isOutOfStock ? AppTheme.errorColor : AppTheme.primaryColor,
          size: 20,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imagePath;

  const _ProductImage({this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync()) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Container(
      color: AppTheme.pearl,
      child: Center(
        child: Icon(Icons.inventory_2_outlined, size: 32, color: Colors.grey[400]),
      ),
    );
  }
}

enum _ProductViewMode { card, list }

class _CartSummary extends StatelessWidget {
  final CartState cartState;

  const _CartSummary({required this.cartState});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cartState.items.length,
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                final lineId = 'product_${item.productId}_price_${item.price}';
                return ListTile(
                  dense: true,
                  leading: GestureDetector(
                    onTap: () => _showQuantityDialog(context, lineId, item.quantity),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  title: Text(item.productName, style: const TextStyle(fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.formatCurrency(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () {
                          context.read<CartBloc>().add(UpdateItemQuantity(lineId, item.quantity + 1));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () {
                          if (item.quantity <= 1) {
                            context.read<CartBloc>().add(RemoveItemFromCart(lineId));
                          } else {
                            context.read<CartBloc>().add(UpdateItemQuantity(lineId, item.quantity - 1));
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 14)),
                    Text(Formatters.formatCurrency(cartState.subtotal), style: const TextStyle(fontSize: 14)),
                  ],
                ),
                if (cartState.discountAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Descuento', style: TextStyle(fontSize: 14, color: Colors.green)),
                      Text('-${Formatters.formatCurrency(cartState.discountAmount)}', style: const TextStyle(fontSize: 14, color: Colors.green)),
                    ],
                  ),
                if (cartState.taxAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('IGV', style: TextStyle(fontSize: 14)),
                      Text(Formatters.formatCurrency(cartState.taxAmount), style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      Formatters.formatCurrency(cartState.total),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Tooltip(
                      message: 'Descuento',
                      child: SizedBox(
                        width: 36, height: 36,
                        child: OutlinedButton(
                          onPressed: () => _showDiscountDialog(context),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Icon(Icons.discount_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Método de pago',
                      child: SizedBox(
                        width: 36, height: 36,
                        child: OutlinedButton(
                          onPressed: () => _showPaymentMethodDialog(context),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Icon(Icons.payments_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Cliente',
                      child: SizedBox(
                        width: 36, height: 36,
                        child: OutlinedButton(
                          onPressed: () => _showCustomerSelector(context),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Icon(Icons.person_outline, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCurrency(cartState.total),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: cartState.items.isEmpty ? null : () => _finalizeSale(context),
                              icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                              label: const Text('Vender', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, String lineId, int currentQuantity) {
    final qtyCtrl = TextEditingController(text: currentQuantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cantidad'),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '0',
            suffixText: 'uds',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              if (qty <= 0) {
                context.read<CartBloc>().add(RemoveItemFromCart(lineId));
              } else {
                context.read<CartBloc>().add(UpdateItemQuantity(lineId, qty));
              }
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    final discountCtrl = TextEditingController();
    bool isPercentage = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Aplicar Descuento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: discountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isPercentage ? 'Porcentaje (%)' : r'Monto ($)',
                  prefixIcon: const Icon(Icons.discount),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Porcentaje'),
                  Switch(
                    value: isPercentage,
                    onChanged: (v) => setDialogState(() => isPercentage = v),
                  ),
                  const Text('Monto fijo'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<CartBloc>().add(const SetDiscount(0));
                Navigator.pop(ctx);
              },
              child: const Text('Quitar descuento'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(discountCtrl.text) ?? 0;
                context.read<CartBloc>().add(SetDiscount(value, isPercentage: isPercentage));
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodDialog(BuildContext context) {
    final methods = ['Efectivo', 'Tarjeta Débito', 'Tarjeta Crédito', 'Transferencia', 'Yape/Plin', 'Crédito'];
    String selected = cartState.paymentMethod;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Método de Pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: methods.map((method) {
              return RadioListTile<String>(
                title: Text(method),
                value: method,
                groupValue: selected,
                onChanged: (v) => setDialogState(() => selected = v!),
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                context.read<CartBloc>().add(SetPaymentMethod(selected));
                Navigator.pop(ctx);
              },
              child: const Text('Seleccionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Cliente'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List>(
            future: DatabaseHelper.getAllCustomers(),
            builder: (ctx, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final customers = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cartState.customer != null)
                    ListTile(
                      title: const Text('Sin cliente'),
                      subtitle: Text('Actual: ${cartState.customer!.name}'),
                      leading: const Icon(Icons.person_off),
                      onTap: () {
                        context.read<CartBloc>().add(const SetCustomer(null));
                        Navigator.pop(ctx);
                      },
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (ctx, i) {
                        final c = customers[i];
                        return ListTile(
                          title: Text(c.name),
                          subtitle: Text(c.phone ?? 'Sin teléfono'),
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          selected: cartState.customer?.id == c.id,
                          onTap: () {
                            context.read<CartBloc>().add(SetCustomer(c));
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<void> _finalizeSale(BuildContext context) async {
  final cartState = context.read<CartBloc>().state;
  if (cartState.items.isEmpty) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Venta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _summaryRow('Productos', '${cartState.items.length} ítems'),
          _summaryRow('Subtotal', Formatters.formatCurrency(cartState.subtotal)),
          if (cartState.discountAmount > 0)
            _summaryRow('Descuento', '-${Formatters.formatCurrency(cartState.discountAmount)}'),
          if (cartState.taxAmount > 0)
            _summaryRow('IGV', Formatters.formatCurrency(cartState.taxAmount)),
          const Divider(),
          _summaryRow('TOTAL', Formatters.formatCurrency(cartState.total), bold: true),
          const SizedBox(height: 8),
          _summaryRow('Método de pago', cartState.paymentMethod),
          if (cartState.customer != null)
            _summaryRow('Cliente', cartState.customer!.name),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.check),
          label: const Text('Confirmar Venta'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    int? saleId;
    try {
      final sale = Sale(
        subtotal: cartState.subtotal,
        tax: cartState.taxAmount,
        discount: cartState.discountAmount,
        total: cartState.total,
        paymentMethod: cartState.paymentMethod,
        customerId: cartState.customer?.id,
        customerName: cartState.customer?.name,
        items: cartState.items,
        status: 'completed',
      );
      saleId = await DatabaseHelper.insertSale(sale);

      if (context.mounted) {
        context.read<CartBloc>().add(ClearCart());
        await showDialog(
          context: context,
          builder: (_) => TicketReceiptDialog(
            saleId: saleId,
            date: DateTime.now(),
            items: cartState.items,
            subtotal: cartState.subtotal,
            discount: cartState.discountAmount,
            tax: cartState.taxAmount,
            total: cartState.total,
            paymentMethod: cartState.paymentMethod,
            customerName: cartState.customer?.name,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar venta: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

Widget _summaryRow(String label, String value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    ),
  );
}

class _SalesHistorySheet extends StatelessWidget {
  const _SalesHistorySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Historial de Ventas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Sale>>(
                future: DatabaseHelper.getTodaySales(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final sales = snapshot.data!;
                  if (sales.isEmpty) {
                    return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Sin ventas hoy');
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: sales.length,
                    itemBuilder: (ctx, i) {
                      final sale = sales[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.check, color: AppTheme.successColor),
                        ),
                        title: Text(Formatters.formatDateTime(sale.date)),
                        subtitle: Text('${sale.items.length} productos - ${sale.paymentMethod}'),
                        trailing: Text(
                          Formatters.formatCurrency(sale.total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
