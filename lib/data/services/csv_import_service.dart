import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/product.dart';

/// Represents a single row parsed from the CSV file, along with any
/// validation errors found for that row.
class CsvProductRow {
  final int rowNumber;
  final String? name;
  final double? price;
  final double? cost;
  final int? stock;
  final int? minStock;
  final String? category;
  final String? barcode;
  final String? description;
  final List<String> errors;

  bool get isValid => errors.isEmpty;

  const CsvProductRow({
    required this.rowNumber,
    this.name,
    this.price,
    this.cost,
    this.stock,
    this.minStock,
    this.category,
    this.barcode,
    this.description,
    this.errors = const [],
  });

  /// Converts this parsed row into a [Product] entity.
  /// Assumes the row is valid (call [isValid] first).
  Product toProduct() {
    return Product(
      name: name!,
      price: price!,
      cost: cost!,
      stock: stock ?? 0,
      minStock: minStock ?? 5,
      category: category,
      barcode: barcode?.isNotEmpty == true ? barcode : null,
      description: description?.isNotEmpty == true ? description : null,
    );
  }
}

/// Result of a CSV import operation.
class CsvImportResult {
  final List<CsvProductRow> rows;
  final int importedCount;
  final int errorCount;
  final String? filePath;

  int get totalRows => rows.length;

  const CsvImportResult({
    required this.rows,
    required this.importedCount,
    required this.errorCount,
    this.filePath,
  });
}

/// Handles parsing, validation, and preview of product CSV files.
class CsvImportService {
  /// Expected header columns in the CSV file.
  /// Order-independent: columns are matched by header name (case-insensitive).
  static const List<String> knownColumns = [
    'name',
    'price',
    'cost',
    'stock',
    'min_stock',
    'minStock',
    'category',
    'barcode',
    'description',
  ];

  /// Reads a CSV file and returns a preview with validation results (no DB
  /// writes). Use [importPreview] to let the user review before committing.
  Future<CsvImportResult> preview(String filePath) async {
    return _parseFile(filePath);
  }

  /// Parses and validates the CSV file, returning all rows regardless of
  /// validity so the caller can display both valid and errored rows.
  Future<CsvImportResult> _parseFile(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      final rows = Csv().decode(contents);

      if (rows.isEmpty) {
        return const CsvImportResult(
          rows: [],
          importedCount: 0,
          errorCount: 0,
          filePath: null,
        );
      }

      // First row is the header (strip BOM from first cell)
      final header = rows.first
          .map((c) => c.toString().trim().toLowerCase().replaceAll('\uFEFF', ''))
          .toList();
      final dataRows = rows.skip(1).toList();

      // Build column index map (case-insensitive)
      final colIndex = <String, int>{};
      for (var i = 0; i < header.length; i++) {
        colIndex[header[i]] = i;
        // Also store with underscore variants
        final noUnderscore = header[i].replaceAll('_', '');
        if (noUnderscore != header[i]) {
          colIndex[noUnderscore] = i;
        }
      }

      // Validate required columns
      if (!colIndex.containsKey('name')) {
        return const CsvImportResult(
          rows: [],
          importedCount: 0,
          errorCount: 0,
          filePath: null,
        );
      }

      final parsedRows = <CsvProductRow>[];

      for (var i = 0; i < dataRows.length; i++) {
        final rawRow = dataRows[i];
        final rowNumber = i + 2; // +2 because header is row 1 and list is 0-indexed
        final errors = <String>[];

        // Helper: get cell value trimmed
        String? cell(String col) {
          final idx = colIndex[col];
          if (idx == null || idx >= rawRow.length) return null;
          final val = rawRow[idx];
          if (val == null) return null;
          final s = val.toString().trim();
          return s.isEmpty ? null : s;
        }

        // Helper: parse double
        double? parseDouble(String? val) {
          if (val == null) return null;
          // Replace comma with dot for decimal separator
          final normalized = val.replaceAll(',', '.');
          return double.tryParse(normalized);
        }

        // --- Extract fields ---

        final name = cell('name');
        final priceStr = cell('price') ?? cell('precio');
        final costStr = cell('cost') ?? cell('costo');
        final stockStr = cell('stock');
        final minStockStr = cell('min_stock') ?? cell('minStock') ?? cell('stock_minimo');
        final category = cell('category') ?? cell('categoria');
        final barcode = cell('barcode') ?? cell('codigo') ?? cell('codigo_barras');
        final description = cell('description') ?? cell('descripcion');

        // --- Validate ---

        if (name == null) {
          errors.add('Nombre requerido');
        }

        final price = parseDouble(priceStr);
        if (priceStr == null) {
          errors.add('Precio requerido');
        } else if (price == null || price <= 0) {
          errors.add('Precio inválido "$priceStr"');
        }

        final cost = parseDouble(costStr);
        if (costStr == null) {
          errors.add('Costo requerido');
        } else if (cost == null || cost < 0) {
          errors.add('Costo inválido "$costStr"');
        }

        final stock = parseDouble(stockStr)?.toInt();
        if (stockStr != null && stock == null) {
          errors.add('Stock inválido "$stockStr"');
        } else if (stock != null && stock < 0) {
          errors.add('Stock no puede ser negativo');
        }

        final minStock = parseDouble(minStockStr)?.toInt();
        if (minStockStr != null && minStock == null) {
          errors.add('Stock mínimo inválido "$minStockStr"');
        } else if (minStock != null && minStock < 0) {
          errors.add('Stock mínimo no puede ser negativo');
        }

        parsedRows.add(CsvProductRow(
          rowNumber: rowNumber,
          name: name,
          price: price,
          cost: cost,
          stock: stock,
          minStock: minStock,
          category: category,
          barcode: barcode,
          description: description,
          errors: errors,
        ));
      }

      final valid = parsedRows.where((r) => r.isValid).toList();

      return CsvImportResult(
        rows: parsedRows,
        importedCount: valid.length,
        errorCount: parsedRows.length - valid.length,
        filePath: filePath,
      );
    } catch (e) {
      debugPrint('CSV parse error: $e');
      return const CsvImportResult(
        rows: [],
        importedCount: 0,
        errorCount: 0,
      );
    }
  }

  /// Returns a simple description of the expected CSV format.
  static String get helpText => '''
Formato CSV esperado:

Columnas requeridas:
  name, price, cost

Columnas opcionales:
  stock, minStock, category, barcode, description

Ejemplo:
  name,price,cost,stock,category,barcode
  Producto A,25.50,15.00,100,Juegos,123456789
  Producto B,10.00,5.50,50,Accesorios,

Los encabezados son insensibles a mayúsculas.
Se aceptan tanto punto como coma como separador decimal.
''';
}
