import 'dart:typed_data';

import 'package:flutter/material.dart' hide FontWeight;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../domain/entities/customer.dart';
import '../domain/entities/debt.dart';
import 'app_state.dart';
import '../data/database/database_helper.dart';

class PdfExportService {
  static final _currencyFormat = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
    locale: 'en_US',
  );
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Generates and shares a PDF with the complete credit report per customer.
  static Future<void> exportCreditReport(BuildContext context) async {
    try {
      final customers = await DatabaseHelper.getAllCustomers();
      final allDebts = await DatabaseHelper.getAllDebts();

      if (customers.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay datos para exportar')),
          );
        }
        return;
      }

      final pdfBytes = await _generatePdf(customers, allDebts);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'reporte_creditos_${_dateFormat.format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Generates and shares a PDF with statistics and profit by category.
  static Future<void> exportStatsPdf(BuildContext context) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final weekAgo = now.subtract(const Duration(days: 7));

      final stats = await DatabaseHelper.getDashboardStats();
      final dailySales = await DatabaseHelper.getDailySales(weekAgo, now);
      final topProducts = await DatabaseHelper.getTopProducts(monthStart, now);
      final topWithProfit = await DatabaseHelper.getTopProductsWithProfit(monthStart, now);
      final totalProfit = await DatabaseHelper.getTotalProfit(monthStart, now);
      final totalCogs = await DatabaseHelper.getTotalCogs(monthStart, now);
      final profitByCategory = await DatabaseHelper.getProfitByCategory(monthStart, now);

      final pdfBytes = await _generateStatsPdf(
        stats: stats,
        dailySales: dailySales,
        topProducts: topProducts,
        topWithProfit: topWithProfit,
        totalProfit: totalProfit,
        totalCogs: totalCogs,
        profitByCategory: profitByCategory,
        monthStart: monthStart,
        now: now,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'estadisticas_${_dateFormat.format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<Uint8List> _generatePdf(
    List<Customer> customers,
    List<Debt> allDebts,
  ) async {
    final pdf = pw.Document(title: 'Reporte de Créditos por Cliente');

    final summaries = <_Summary>[];
    for (final customer in customers) {
      final debts = allDebts.where((d) => d.customerId == customer.id).toList();
      if (debts.isNotEmpty) {
        summaries.add(_Summary(customer: customer, debts: debts));
      }
    }

    final totalPendiente = summaries.fold(0.0, (s, c) => s + c.pendingAmount);
    final totalCredits = summaries.fold(0, (s, c) => s + c.debts.length);
    final overdueCount = summaries.fold(0, (s, c) =>
        s + c.debts.where((d) => d.status != 'paid' && d.dueDate.isBefore(DateTime.now())).length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'REPORTE DE CRÉDITOS POR CLIENTE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Generado: ${_dateFormat.format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 16),

          _buildSummaryRow(summaries.length, totalCredits, totalPendiente, overdueCount),
          pw.SizedBox(height: 20),

          ...summaries.map((summary) => _buildCustomerSection(summary)),
        ],
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(preferencesService.businessName,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text('Reporte de Créditos', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${preferencesService.businessName} - Sistema POS', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    int clientCount, int totalCredits, double totalPendiente, int overdueCount,
  ) {
    return pw.Row(
      children: [
        _summaryCard('$clientCount', 'Clientes', PdfColors.blue700),
        pw.SizedBox(width: 8),
        _summaryCard('$totalCredits', 'Total Créditos', PdfColors.orange700),
        pw.SizedBox(width: 8),
        _summaryCard(_currencyFormat.format(totalPendiente), 'Pendiente', PdfColors.red700),
        pw.SizedBox(width: 8),
        _summaryCard('$overdueCount', 'Vencidos', PdfColors.red900),
      ],
    );
  }

  static pw.Widget _summaryCard(String value, String label, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          border: pw.Border.all(color: color),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(label, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildCustomerSection(_Summary summary) {
    final hasOverdue = summary.debts.any(
      (d) => d.status != 'paid' && d.dueDate.isBefore(DateTime.now()));
    final activeDebts = summary.debts.where((d) => d.status != 'paid').toList();
    final paidDebts = summary.debts.where((d) => d.status == 'paid').toList();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: hasOverdue ? PdfColors.red50 : PdfColors.blue50,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(summary.customer.name,
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      if (summary.customer.phone != null)
                        pw.Text('Tel: ${summary.customer.phone}',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Total: ${_currencyFormat.format(summary.totalAmount)}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Pendiente: ${_currencyFormat.format(summary.pendingAmount)}',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
                  ],
                ),
              ],
            ),
          ),
          if (activeDebts.isNotEmpty) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: pw.Text('Créditos Pendientes',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
            ),
            _buildDebtsTable(activeDebts, isActive: true),
          ],
          if (paidDebts.isNotEmpty) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: pw.Text('Créditos Pagados',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
            ),
            _buildDebtsTable(paidDebts, isActive: false),
          ],
          pw.SizedBox(height: 4),
        ],
      ),
    );
  }

  static pw.Widget _buildDebtsTable(List<Debt> debts, {required bool isActive}) {
    final headers = ['Monto', 'Pagado', 'Pendiente', 'Vencimiento', 'Estado'];

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.2),
          1: pw.FlexColumnWidth(1),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(1.2),
          4: pw.FlexColumnWidth(0.8),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey100),
            children: headers.map((h) => pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(h, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
            )).toList(),
          ),
          ...debts.map((d) {
            final isOverdue = isActive && d.dueDate.isBefore(DateTime.now());
            final pending = d.amount - d.paidAmount;
            return pw.TableRow(
              decoration: isOverdue ? pw.BoxDecoration(color: PdfColors.red50) : null,
              children: [
                _cell(_currencyFormat.format(d.amount)),
                _cell(_currencyFormat.format(d.paidAmount)),
                _cell(_currencyFormat.format(pending), color: isOverdue ? PdfColors.red700 : null),
                _cell(_dateFormat.format(d.dueDate)),
                _cell(
                  isOverdue ? 'VENCIDO' : d.status == 'paid' ? 'Pagado' : 'Pendiente',
                  color: isOverdue ? PdfColors.red700
                      : d.status == 'paid' ? PdfColors.green700 : PdfColors.orange700,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 7, color: color)),
    );
  }

  static Future<Uint8List> _generateStatsPdf({
    required Map<String, dynamic> stats,
    required List<Map<String, dynamic>> dailySales,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> topWithProfit,
    required double totalProfit,
    required double totalCogs,
    required List<Map<String, dynamic>> profitByCategory,
    required DateTime monthStart,
    required DateTime now,
  }) async {
    final pdf = pw.Document(title: 'Estadísticas del Negocio');
    final monthSales = (stats['monthSales'] as num).toDouble();
    final monthExpenses = (stats['monthExpenses'] as num).toDouble();
    final netProfit = (stats['netProfit'] as num).toDouble();
    final pendingDebts = (stats['pendingDebts'] as num).toDouble();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'ESTADÍSTICAS DEL NEGOCIO',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Período: ${_dateFormat.format(monthStart)} - ${_dateFormat.format(now)}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 16),

          // Summary cards
          pw.Row(
            children: [
              _summaryCard(_currencyFormat.format(monthSales), 'Ventas del Mes', PdfColors.green700),
              pw.SizedBox(width: 8),
              _summaryCard(_currencyFormat.format(monthExpenses), 'Gastos', PdfColors.red700),
              pw.SizedBox(width: 8),
              _summaryCard(_currencyFormat.format(netProfit), 'Ganancia Neta', PdfColors.blue700),
              pw.SizedBox(width: 8),
              _summaryCard(_currencyFormat.format(pendingDebts), 'Créditos Pend.', PdfColors.orange700),
            ],
          ),
          pw.SizedBox(height: 20),

          // Profit summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Utilidad Bruta', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(_currencyFormat.format(totalProfit),
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Costo de Ventas (COGS)', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(_currencyFormat.format(totalCogs),
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Profit by category
          pw.Text('UTILIDAD POR CATEGORÍA',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 8),
          if (profitByCategory.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text('Sin ventas este mes', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            )
          else
            _buildCategoryProfitTable(profitByCategory),
          pw.SizedBox(height: 20),

          // Top products with profit
          pw.Text('UTILIDAD POR PRODUCTO (TOP 10)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 8),
          if (topWithProfit.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text('Sin ventas este mes', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            )
          else
            _buildProductProfitTable(topWithProfit),

          // Daily sales chart (text table)
          pw.SizedBox(height: 20),
          pw.Text('VENTAS DE LOS ÚLTIMOS 7 DÍAS',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 8),
          if (dailySales.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text('Sin datos de ventas', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            )
          else
            _buildDailySalesTable(dailySales),
        ],
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildCategoryProfitTable(List<Map<String, dynamic>> categories) {
    final totalRevenue = categories.fold(0.0, (sum, c) => sum + (c['totalRevenue'] as num).toDouble());
    final totalCost = categories.fold(0.0, (sum, c) => sum + (c['totalCost'] as num).toDouble());
    final totalProfit = categories.fold(0.0, (sum, c) => sum + (c['totalProfit'] as num).toDouble());
    final totalQty = categories.fold(0, (sum, c) => sum + (c['totalQuantity'] as int));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue50),
          children: ['Categoría', 'Cant.', 'Ingresos', 'Costo', 'Utilidad', '% Margen']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...categories.map((c) {
          final profit = (c['totalProfit'] as num).toDouble();
          final revenue = (c['totalRevenue'] as num).toDouble();
          final margin = revenue > 0 ? (profit / revenue * 100) : 0.0;
          return pw.TableRow(
            children: [
              _cell(c['category'] as String),
              _cell('${c['totalQuantity']}'),
              _cell(_currencyFormat.format(revenue)),
              _cell(_currencyFormat.format((c['totalCost'] as num).toDouble())),
              _cell(_currencyFormat.format(profit), color: profit >= 0 ? PdfColors.green700 : PdfColors.red700),
              _cell('${margin.toStringAsFixed(1)}%', color: profit >= 0 ? PdfColors.green700 : PdfColors.red700),
            ],
          );
        }),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _cell('TOTAL', color: PdfColors.black),
            _cell('$totalQty'),
            _cell(_currencyFormat.format(totalRevenue), color: PdfColors.black),
            _cell(_currencyFormat.format(totalCost), color: PdfColors.black),
            _cell(_currencyFormat.format(totalProfit), color: PdfColors.black),
            _cell(totalRevenue > 0 ? '${(totalProfit / totalRevenue * 100).toStringAsFixed(1)}%' : '0%',
                color: PdfColors.black),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildProductProfitTable(List<Map<String, dynamic>> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.4),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(0.8),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue50),
          children: ['#', 'Producto', 'Cant.', 'Ingresos', 'Costo', 'Utilidad']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...products.asMap().entries.map((entry) {
          final p = entry.value;
          final profit = (p['totalProfit'] as num).toDouble();
          return pw.TableRow(
            children: [
              _cell('${entry.key + 1}'),
              _cell(p['productName'] as String),
              _cell('${p['totalQuantity']}'),
              _cell(_currencyFormat.format((p['totalAmount'] as num).toDouble())),
              _cell(_currencyFormat.format((p['totalCost'] as num).toDouble())),
              _cell(_currencyFormat.format(profit), color: profit >= 0 ? PdfColors.green700 : PdfColors.red700),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildDailySalesTable(List<Map<String, dynamic>> dailySales) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue50),
          children: ['Fecha', 'Total Ventas', '# Ventas']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...dailySales.map((d) {
          return pw.TableRow(
            children: [
              _cell(d['day'] as String),
              _cell(_currencyFormat.format((d['total'] as num).toDouble())),
              _cell('${d['count']}'),
            ],
          );
        }),
      ],
    );
  }
}

class _Summary {
  final Customer customer;
  final List<Debt> debts;

  _Summary({required this.customer, required this.debts});

  double get totalAmount => debts.fold(0.0, (s, d) => s + d.amount);
  double get paidAmount => debts.fold(0.0, (s, d) => s + d.paidAmount);
  double get pendingAmount => totalAmount - paidAmount;
  int get activeCount => debts.where((d) => d.status != 'paid').length;
}
