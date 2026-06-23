import 'dart:typed_data';

import 'package:flutter/material.dart' hide FontWeight;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../domain/entities/customer.dart';
import '../domain/entities/debt.dart';
import '../data/database/database_helper.dart';

class PdfExportService {
  static final _currencyFormat = NumberFormat.currency(
    symbol: 'S/ ',
    decimalDigits: 2,
    locale: 'es_PE',
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
            pw.Text('Tienda Gamez',
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
            pw.Text('Tienda Gamez - Sistema POS', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
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
