import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase_order.dart';
import '../../../domain/entities/purchase_order_item.dart';
import '../../../domain/entities/supplier.dart';

class PurchaseOrderFormScreen extends StatefulWidget {
  final int? orderId;

  const PurchaseOrderFormScreen({super.key, this.orderId});

  @override
  State<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _notesCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController(text: '18');
  Supplier? _supplier;
  List<_OrderItem> _items = [];
  bool _isLoading = false;
  bool _isEditing = false;
  bool _hasTax = true;
  double _taxRate = 0.18;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _isEditing = true;
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await DatabaseHelper.getPurchaseOrderById(widget.orderId!);
    if (order != null && mounted) {
      if (!order.isPending) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Solo se pueden editar pedidos pendientes'),
          backgroundColor: AppTheme.warningColor,
        ));
        Navigator.pop(context);
        return;
      }
      _supplier = Supplier(
        id: order.supplierId,
        name: order.supplierName,
      );
      _items = order.items.map((i) => _OrderItem(
        productId: i.productId,
        productName: i.productName,
        quantity: i.quantity,
        unitCost: i.unitCost,
      )).toList();
      _notesCtrl.text = order.notes ?? '';
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.subtotal);
  double get _tax => _hasTax ? _subtotal * _taxRate : 0.0;
  double get _total => _subtotal + _tax;

  Future<void> _selectSupplier() async {
    final suppliers = await DatabaseHelper.getAllSuppliers();
    if (!mounted) return;

    final supplier = await showDialog<Supplier>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Proveedor'),
        content: SizedBox(
          width: double.maxFinite,
          child: suppliers.isEmpty
              ? const Text('No hay proveedores registrados')
              : ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (ctx, i) {
                    final s = suppliers[i];
                    return ListTile(
                      title: Text(s.name),
                      subtitle: Text(s.phone ?? ''),
                      onTap: () => Navigator.pop(ctx, s),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))],
      ),
    );

    if (supplier != null) {
      setState(() => _supplier = supplier);
    }
  }

  Future<void> _addProduct() async {
    final products = await DatabaseHelper.getAllProducts();
    if (!mounted) return;

    final product = await showDialog<Product>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Producto'),
        content: SizedBox(
          width: double.maxFinite,
          child: products.isEmpty
              ? const Text('No hay productos')
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (ctx, i) {
                    final p = products[i];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text('Costo: ${Formatters.formatCurrency(p.cost)} - Stock: ${p.stock}'),
                      onTap: () => Navigator.pop(ctx, p),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))],
      ),
    );

    if (product == null) return;

    final qtyCtrl = TextEditingController(text: '1');
    final qty = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cantidad: ${product.name}'),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cantidad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final q = int.tryParse(qtyCtrl.text) ?? 1;
            if (q > 0) Navigator.pop(ctx, q);
          }, child: const Text('Agregar')),
        ],
      ),
    );

    if (qty != null && qty > 0) {
      setState(() {
        final existingIdx = _items.indexWhere((i) => i.productId == product.id);
        if (existingIdx >= 0) {
          _items[existingIdx] = _OrderItem(
            productId: product.id!,
            productName: product.name,
            quantity: _items[existingIdx].quantity + qty,
            unitCost: product.cost,
          );
        } else {
          _items.add(_OrderItem(
            productId: product.id!,
            productName: product.name,
            quantity: qty,
            unitCost: product.cost,
          ));
        }
      });
    }
  }

  Future<void> _save() async {
    if (_supplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un proveedor'), backgroundColor: AppTheme.warningColor));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un producto'), backgroundColor: AppTheme.warningColor));
      return;
    }

    setState(() => _isLoading = true);

    final order = PurchaseOrder(
      id: widget.orderId,
      supplierId: _supplier!.id!,
      supplierName: _supplier!.name,
      subtotal: _subtotal,
      tax: _tax,
      total: _total,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      items: _items.map((i) => PurchaseOrderItem(
        productId: i.productId,
        productName: i.productName,
        quantity: i.quantity,
        unitCost: i.unitCost,
        subtotal: i.subtotal,
      )).toList(),
    );

    try {
      if (_isEditing) {
        await DatabaseHelper.updatePurchaseOrder(order);
      } else {
        await DatabaseHelper.insertPurchaseOrder(order);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? '✅ Pedido actualizado' : '✅ Pedido registrado'),
          backgroundColor: AppTheme.successColor,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Pedido' : 'Nuevo Pedido'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supplier selection
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.business),
                title: Text(_supplier?.name ?? 'Seleccionar Proveedor'),
                subtitle: _supplier?.phone != null ? Text(_supplier!.phone!) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectSupplier,
              ),
            ),
            const SizedBox(height: 16),

            // Products
            Row(
              children: [
                const Text('Productos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_items.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Agrega productos al pedido'))),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final i = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    title: Text(i.productName),
                    subtitle: Text('Costo: ${Formatters.formatCurrency(i.unitCost)} x ${i.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Formatters.formatCurrency(i.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.errorColor),
                          onPressed: () => setState(() => _items.removeAt(entry.key)),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // IGV toggle
            Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                title: const Text('Aplica IGV/IVA'),
                subtitle: Text(_hasTax ? '${(_taxRate * 100).toStringAsFixed(0)}% de impuesto' : 'Sin impuesto'),
                value: _hasTax,
                onChanged: (v) => setState(() {
                  _hasTax = v;
                  if (v && _taxRate == 0) _taxRate = 0.18;
                }),
                secondary: Icon(
                  _hasTax ? Icons.receipt : Icons.money_off,
                  color: _hasTax ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
            ),
            if (_hasTax)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _taxRateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje de impuesto',
                    prefixIcon: Icon(Icons.percent),
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null && parsed >= 0) {
                      _taxRate = parsed / 100;
                      setState(() {});
                    }
                  },
                ),
              ),
            const SizedBox(height: 12),

            // Totals
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _row('Subtotal', Formatters.formatCurrency(_subtotal)),
                    if (_hasTax)
                      _row('IGV (${(_taxRate * 100).toStringAsFixed(0)}%)', Formatters.formatCurrency(_tax)),
                    const Divider(),
                    _row('TOTAL', Formatters.formatCurrency(_total), bold: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
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
}

class _OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final double unitCost;

  _OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  double get subtotal => quantity * unitCost;
}
