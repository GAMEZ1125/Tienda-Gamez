import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ticket_receipt_dialog.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/sale.dart';
import '../scanner_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await DatabaseHelper.searchProducts(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _openScanner() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen(
        title: 'Escanear Producto',
      )),
    );

    if (barcode == null || !mounted) return;

    final product = await DatabaseHelper.getProductByBarcode(barcode);
    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto no encontrado: $barcode'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto agotado'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Agregar producto al carrito
    context.read<CartBloc>().add(AddProductToCart(product));

    if (mounted) {
      _searchController.text = product.name;
      _searchProducts(product.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${product.name} agregado al carrito'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartBloc(),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Punto de Venta'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Historial de Ventas',
                  onPressed: () => _showSalesHistory(context),
                ),
              ],
            ),
            body: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar producto por nombre o código...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchProducts('');
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: _openScanner,
                                    tooltip: 'Escanear código de barras',
                                  ),
                          ),
                          onChanged: _searchProducts,
                        ),
                      ),
                    ],
                  ),
                ),

                // Products grid
                Expanded(
                  flex: 5,
                  child: _isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults.isEmpty
                          ? EmptyState(
                              icon: Icons.shopping_bag_outlined,
                              title: 'Busca productos para vender',
                              subtitle: 'Usa el buscador o escanea un código de barras',
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final product = _searchResults[index];
                                return _ProductCard(
                                  product: product,
                                  onTap: () {
                                    if (product.stock <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Producto agotado')),
                                      );
                                      return;
                                    }
                                    context.read<CartBloc>().add(AddProductToCart(product));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${product.name} agregado al carrito'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),

                // Cart summary
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

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                Formatters.formatCurrency(product.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 14,
                    color: product.isLowStock ? AppTheme.warningColor : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stock: ${product.stock}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: product.isLowStock ? AppTheme.warningColor : Colors.grey,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          // Cart items list (compact)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cartState.items.length,
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
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
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () {
                          if (item.quantity <= 1) {
                            context.read<CartBloc>().add(RemoveItemFromCart(item.productId));
                          } else {
                            context.read<CartBloc>().add(UpdateItemQuantity(item.productId, item.quantity - 1));
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
          // Totals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 14)),
                    Text(
                      Formatters.formatCurrency(cartState.subtotal),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (cartState.discountAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Descuento',
                        style: TextStyle(fontSize: 14, color: Colors.green[600]),
                      ),
                      Text(
                        '-${Formatters.formatCurrency(cartState.discountAmount)}',
                        style: TextStyle(fontSize: 14, color: Colors.green[600]),
                      ),
                    ],
                  ),
                if (cartState.taxAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('IGV', style: TextStyle(fontSize: 14)),
                      Text(
                        Formatters.formatCurrency(cartState.taxAmount),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Formatters.formatCurrency(cartState.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons row
                Row(
                  children: [
                    // Three action buttons take less space
                    Tooltip(
                      message: 'Descuento',
                      child: SizedBox(
                        width: 36,
                        height: 36,
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
                        width: 36,
                        height: 36,
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
                        width: 36,
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => _showCustomerSelector(context),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Icon(Icons.person_outline, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Total + Vender
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCurrency(cartState.total),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: cartState.items.isEmpty
                                  ? null
                                  : () => _finalizeSale(context),
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
                  labelText: isPercentage ? 'Porcentaje (%)' : 'Monto (S/)',
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
                onChanged: (v) {
                  setDialogState(() => selected = v!);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
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
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
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
        
        // Mostrar ticket/comprobante
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
          SnackBar(
            content: Text('Error al registrar venta: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
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
                  const Text(
                    'Historial de Ventas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
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
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin ventas hoy',
                    );
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
