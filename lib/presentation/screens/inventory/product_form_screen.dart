import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_category.dart';
import '../scanner_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final int? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _barcodeController = TextEditingController();

  List<ProductCategory> _categories = [];
  String? _selectedCategory;
  bool _isActive = true;
  bool _hasTax = true;
  double _taxRate = 0.18;
  final _taxRateCtrl = TextEditingController(text: '18');
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.productId != null) {
      _isEditing = true;
      _loadProduct();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.getAllCategories();
    setState(() => _categories = cats);
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    final product = await DatabaseHelper.getProductById(widget.productId!);
    if (product != null) {
      _nameController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.price.toString();
      _costController.text = product.cost.toString();
      _stockController.text = product.stock.toString();
      _minStockController.text = product.minStock.toString();
      _barcodeController.text = product.barcode ?? '';
      _selectedCategory = product.category;
      _isActive = product.isActive;
      _hasTax = product.hasTax;
      _taxRate = product.taxRate;
      _taxRateCtrl.text = (product.taxRate * 100).toStringAsFixed(0);
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final product = Product(
      id: widget.productId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      cost: double.parse(_costController.text),
      stock: int.tryParse(_stockController.text) ?? 0,
      minStock: int.tryParse(_minStockController.text) ?? 5,
      category: _selectedCategory,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      isActive: _isActive,
      taxRate: _hasTax ? _taxRate : 0.0,
    );

    try {
      if (_isEditing) {
        await DatabaseHelper.updateProduct(product);
      } else {
        await DatabaseHelper.insertProduct(product);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Producto actualizado' : 'Producto creado'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openScanner() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen(
        title: 'Escanear Código de Barras',
      )),
    );

    if (barcode != null && mounted) {
      _barcodeController.text = barcode;
      try {
        final existing = await DatabaseHelper.getProductByBarcode(barcode);
        if (existing != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ El producto "${existing.name}" ya tiene este código'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al buscar producto: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: _isLoading && widget.productId != null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Price and Cost
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Precio venta *',
                              prefixIcon: Icon(Icons.attach_money),
                              prefixText: 'S/ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) return 'Invalido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(
                              labelText: 'Precio costo *',
                              prefixIcon: Icon(Icons.money_off),
                              prefixText: 'S/ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              final n = double.tryParse(v);
                              if (n == null || n < 0) return 'Invalido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock and Min Stock
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                              prefixIcon: Icon(Icons.inventory_2),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _minStockController,
                            decoration: const InputDecoration(
                              labelText: 'Stock mínimo',
                              prefixIcon: Icon(Icons.warning_amber),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: [
                        ..._categories.map((cat) {
                          return DropdownMenuItem(value: cat.name, child: Text(cat.name));
                        }),
                        if (_selectedCategory != null && !_categories.any((c) => c.name == _selectedCategory))
                          DropdownMenuItem<String>(value: _selectedCategory!, child: Text(_selectedCategory!)),
                      ],
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                    const SizedBox(height: 16),

                    // Barcode
                    TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Código de barras',
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () => _openScanner(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tax toggle
                    SwitchListTile(
                      title: const Text('Aplica IGV/IVA'),
                      subtitle: Text(_hasTax ? '${(_taxRate * 100).toStringAsFixed(0)}% de impuesto' : 'Producto exonerado de impuestos'),
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
                    if (_hasTax)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
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
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Active toggle
                    SwitchListTile(
                      title: const Text('Producto activo'),
                      subtitle: Text(_isActive ? 'Visible en ventas' : 'Oculto en ventas'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
