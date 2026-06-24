import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_category.dart';
import '../../../domain/entities/product_variation.dart';
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
  final _unitsPerPackageController = TextEditingController(text: '1');

  List<ProductCategory> _categories = [];
  String? _selectedCategory;
  bool _isActive = true;
  bool _hasTax = true;
  double _taxRate = 0.18;
  final _taxRateCtrl = TextEditingController(text: '18');
  String? _imagePath;
  bool _isLoading = false;
  bool _isEditing = false;
  List<ProductVariation> _variations = [];

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
      _imagePath = product.imagePath;
      _selectedCategory = product.category;
      _isActive = product.isActive;
      _hasTax = product.hasTax;
      _taxRate = product.taxRate;
      _taxRateCtrl.text = (product.taxRate * 100).toStringAsFixed(0);
      _unitsPerPackageController.text = product.unitsPerPackage.toString();
    }
    await _loadVariations();
    setState(() => _isLoading = false);
  }

  Future<void> _loadVariations() async {
    if (widget.productId == null) return;
    final variations = await DatabaseHelper.getVariationsByProduct(widget.productId!);
    setState(() => _variations = variations);
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null || !mounted) return;

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'product_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    final savedPath = p.join(imagesDir.path, fileName);
    await File(image.path).copy(savedPath);

    setState(() => _imagePath = savedPath);
  }

  void _removeImage() {
    setState(() => _imagePath = null);
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
      stock: double.tryParse(_stockController.text) ?? 0.0,
      minStock: int.tryParse(_minStockController.text) ?? 5,
      category: _selectedCategory,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      isActive: _isActive,
      taxRate: _hasTax ? _taxRate : 0.0,
      imagePath: _imagePath,
      unitsPerPackage: int.tryParse(_unitsPerPackageController.text) ?? 1,
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
            style: TextButton.styleFrom(foregroundColor: Colors.white),
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
                    _buildImagePicker(),
                    const SizedBox(height: 16),

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
                              prefixText: r'$ ',
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
                              prefixText: r'$ ',
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

                    // Units per package
                    TextFormField(
                      controller: _unitsPerPackageController,
                      decoration: InputDecoration(
                        labelText: 'Unidades por paquete',
                        prefixIcon: const Icon(Icons.inventory),
                        hintText: '1 = producto simple, 30 = caja x30',
                        helperText: _unitsPerPackageController.text == '1'
                            ? 'Simple: se vende por unidad individual'
                            : 'Paquete: stock en paquetes, se venden unidades individuales',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
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

                    // Variations section (only when editing)
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      _buildVariationsSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVariationsSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.style, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Variaciones / Presentaciones',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${_variations.length} variación(es)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tallas, colores, tamaños o presentaciones del producto',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            if (_variations.isNotEmpty) ...[
              ..._variations.map((v) => _buildVariationTile(v)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddVariationDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar Variación'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationTile(ProductVariation variation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: variation.isActive ? null : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          variation.imagePath != null && variation.imagePath!.isNotEmpty && File(variation.imagePath!).existsSync()
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(variation.imagePath!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.style, size: 18, color: AppTheme.primaryColor),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variation.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '\$${variation.price.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock: ${variation.stock}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (variation.unitsPerPresentation > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${variation.unitsPerPresentation}x',
                          style: TextStyle(fontSize: 11, color: AppTheme.accentBlue, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (variation.barcode != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Cód: ${variation.barcode}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _showEditVariationDialog(variation),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
            onPressed: () => _deleteVariation(variation),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }

  void _showAddVariationDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: _priceController.text);
    final costCtrl = TextEditingController(text: _costController.text);
    final stockCtrl = TextEditingController(text: '0');
    final barcodeCtrl = TextEditingController();
    final unitsCtrl = TextEditingController(text: '1');
    String? imagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Variación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker
                if (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync())
                  Container(
                    height: 80,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setDialogState(() => imagePath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (image != null) {
                          final appDir = await getApplicationDocumentsDirectory();
                          final imagesDir = Directory(p.join(appDir.path, 'product_images'));
                          if (!await imagesDir.exists()) {
                            await imagesDir.create(recursive: true);
                          }
                          final fileName = 'var_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
                          final savedPath = p.join(imagesDir.path, fileName);
                          await File(image.path).copy(savedPath);
                          setDialogState(() => imagePath = savedPath);
                        }
                      },
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Imagen (opcional)'),
                    ),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej: 350ml, Rojo, Pack x6',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Precio *',
                          prefixText: r'$ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Costo',
                          prefixText: r'$ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unidades',
                          hintText: '1=unidad, 6=pack',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: barcodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código barras',
                    hintText: 'Opcional',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final variation = ProductVariation(
                  productId: widget.productId!,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  cost: double.tryParse(costCtrl.text) ?? 0,
                  stock: int.tryParse(stockCtrl.text) ?? 0,
                  unitsPerPresentation: int.tryParse(unitsCtrl.text) ?? 1,
                  barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                  imagePath: imagePath,
                );
                await DatabaseHelper.insertVariation(variation);
                await _loadVariations();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVariationDialog(ProductVariation variation) {
    final nameCtrl = TextEditingController(text: variation.name);
    final priceCtrl = TextEditingController(text: variation.price.toString());
    final costCtrl = TextEditingController(text: variation.cost.toString());
    final stockCtrl = TextEditingController(text: variation.stock.toString());
    final barcodeCtrl = TextEditingController(text: variation.barcode ?? '');
    final unitsCtrl = TextEditingController(text: variation.unitsPerPresentation.toString());
    String? imagePath = variation.imagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Variación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker
                if (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync())
                  Container(
                    height: 80,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setDialogState(() => imagePath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (image != null) {
                          final appDir = await getApplicationDocumentsDirectory();
                          final imagesDir = Directory(p.join(appDir.path, 'product_images'));
                          if (!await imagesDir.exists()) {
                            await imagesDir.create(recursive: true);
                          }
                          final fileName = 'var_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
                          final savedPath = p.join(imagesDir.path, fileName);
                          await File(image.path).copy(savedPath);
                          setDialogState(() => imagePath = savedPath);
                        }
                      },
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Imagen (opcional)'),
                    ),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Precio *',
                          prefixText: r'$ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Costo',
                          prefixText: r'$ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unidades',
                          hintText: '1=unidad, 6=pack',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: barcodeCtrl,
                  decoration: const InputDecoration(labelText: 'Código barras'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final updated = variation.copyWith(
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? variation.price,
                  cost: double.tryParse(costCtrl.text) ?? variation.cost,
                  stock: int.tryParse(stockCtrl.text) ?? variation.stock,
                  unitsPerPresentation: int.tryParse(unitsCtrl.text) ?? variation.unitsPerPresentation,
                  barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                  imagePath: imagePath,
                  updatedAt: DateTime.now(),
                );
                await DatabaseHelper.updateVariation(updated);
                await _loadVariations();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVariation(ProductVariation variation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Variación'),
        content: Text('¿Eliminar "${variation.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.deleteVariation(variation.id!);
      await _loadVariations();
    }
  }

  Widget _buildImagePicker() {
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imagen del producto',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 180,
                width: double.infinity,
                color: AppTheme.pearl,
                child: hasImage
                    ? Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_outlined, size: 52, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Sin imagen',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: Text(hasImage ? 'Cambiar imagen' : 'Subir imagen'),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Quitar imagen',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
