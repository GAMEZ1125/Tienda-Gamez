import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/services/csv_import_service.dart';

/// Screen for importing products from a CSV file with preview and validation.
class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final _service = CsvImportService();

  // States: idle → file_selected → preview → importing → done
  bool _isLoading = false;
  bool _isImporting = false;
  String? _filePath;
  CsvImportResult? _result;
  int _importedCount = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    setState(() {
      _isLoading = true;
      _filePath = path;
      _result = null;
    });

    try {
      final preview = await _service.preview(path);
      if (mounted) {
        setState(() {
          _result = preview;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al leer el archivo: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _import() async {
    if (_result == null || _result!.importedCount == 0) return;

    setState(() => _isImporting = true);

    try {
      final validRows = _result!.rows.where((r) => r.isValid).toList();
      final products = validRows.map((r) => r.toProduct()).toList();

      // Insert in batches of 50 to avoid huge single transactions
      var totalInserted = 0;
      const batchSize = 50;
      for (var i = 0; i < products.length; i += batchSize) {
        final batch = products.sublist(
          i,
          i + batchSize > products.length ? products.length : i + batchSize,
        );
        totalInserted += await DatabaseHelper.insertProductsBatch(batch);
      }

      _importedCount = totalInserted;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $totalInserted productos importados correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al importar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isImporting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Importar CSV'),
          actions: [
            if (_result != null && _importedCount == 0)
              TextButton.icon(
                onPressed: _isImporting ? null : _pickFile,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Otro archivo'),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Initial state: prompt to pick a file
    if (_filePath == null && !_isLoading) {
      return _buildPickPrompt();
    }

    // Loading state
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analizando archivo CSV...'),
          ],
        ),
      );
    }

    // Parse error / empty file
    if (_result == null || _result!.rows.isEmpty) {
      return _buildEmptyResult();
    }

    // Import completed
    if (_importedCount > 0) {
      return _buildImportComplete();
    }

    // Preview mode
    return _buildPreview();
  }

  Widget _buildPickPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.upload_file,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Importar productos desde CSV',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Selecciona un archivo CSV con los datos de\nlos productos que deseas importar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showHelp(),
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('Ver formato esperado'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_open),
                label: const Text('Seleccionar archivo CSV'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron leer productos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'El archivo no contiene datos válidos o\nno tiene el formato esperado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar con otro archivo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final result = _result!;
    final validRows = result.rows.where((r) => r.isValid).toList();
    final errorRows = result.rows.where((r) => !r.isValid).toList();

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem(
                    Icons.description,
                    '${result.totalRows}',
                    'Total filas',
                    Colors.grey,
                  ),
                  _summaryItem(
                    Icons.check_circle,
                    '${validRows.length}',
                    'Válidas',
                    AppTheme.successColor,
                  ),
                  _summaryItem(
                    Icons.error,
                    '${errorRows.length}',
                    'Con errores',
                    errorRows.isEmpty ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ],
              ),
              if (result.filePath != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        result.filePath!.split('\\').last.split('/').last,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Error rows section
        if (errorRows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              color: AppTheme.errorColor.withValues(alpha: 0.05),
              child: ExpansionTile(
                leading: const Icon(Icons.warning_amber, color: AppTheme.errorColor),
                title: Text(
                  '${errorRows.length} fila(s) con errores',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                    fontSize: 14,
                  ),
                ),
                children: errorRows.map((row) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fila ${row.rowNumber}: ${row.name ?? '(sin nombre)'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      ...row.errors.map((e) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right, size: 14, color: AppTheme.errorColor),
                            Expanded(
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 12, color: AppTheme.errorColor),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 12),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],

        // Valid rows preview (only show first 5)
        if (validRows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                const Icon(Icons.preview, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Vista previa (${validRows.length} productos)',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: validRows.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final product = validRows[index].toProduct();
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.shopping_bag, size: 18, color: AppTheme.primaryColor),
                    ),
                    title: Text(product.name, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${product.category ?? 'Sin categoría'} | Stock: ${product.stock}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      Formatters.formatCurrency(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (validRows.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '... y ${validRows.length - 5} producto(s) más',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],

        // Import button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isImporting || validRows.isEmpty ? null : _import,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isImporting
                      ? 'Importando...'
                      : validRows.isEmpty
                          ? 'Sin datos válidos para importar'
                          : 'Importar ${validRows.length} producto(s)',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: validRows.isEmpty ? Colors.grey : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportComplete() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: AppTheme.successColor),
            const SizedBox(height: 24),
            Text(
              '¡Importación completada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$_importedCount producto(s) importados\ncorrectamente a la base de datos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al inventario'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, size: 20),
            SizedBox(width: 8),
            Text('Formato CSV', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            CsvImportService.helpText,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
