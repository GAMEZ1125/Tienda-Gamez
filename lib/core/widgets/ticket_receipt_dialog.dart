import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/sale_item.dart';

class TicketReceiptDialog extends StatelessWidget {
  final int? saleId;
  final DateTime date;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final String? customerName;

  const TicketReceiptDialog({
    super.key,
    this.saleId,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.customerName,
  });

  String get _ticketNumber => saleId != null ? 'V${saleId!.toString().padLeft(6, '0')}' : '---';

  /// Generates the plain text version of the ticket for sharing
  String get _ticketText {
    final buffer = StringBuffer();
    buffer.writeln('╔══════════════════════════════╗');
    buffer.writeln('║       TIENDA GAMEZ           ║');
    buffer.writeln('╚══════════════════════════════╝');
    buffer.writeln('');
    buffer.writeln('Ticket: $_ticketNumber');
    buffer.writeln('Fecha: ${Formatters.formatDateTime(date)}');
    buffer.writeln('Método: $paymentMethod');
    if (customerName != null) {
      buffer.writeln('Cliente: $customerName');
    }
    buffer.writeln('');
    buffer.writeln('───────────────────────────────');
    buffer.writeln('  PRODUCTO         CANT  TOTAL');
    buffer.writeln('───────────────────────────────');
    for (final item in items) {
      final name = item.productName.length > 15
          ? '${item.productName.substring(0, 15)}.'
          : item.productName;
      buffer.writeln(
          '${name.padRight(16)}${item.quantity.toString().padLeft(3)}  ${Formatters.formatCurrency(item.subtotal).padLeft(8)}');
    }
    buffer.writeln('───────────────────────────────');
    buffer.writeln('${"Subtotal".padRight(20)} ${Formatters.formatCurrency(subtotal).padLeft(10)}');
    if (discount > 0) {
      buffer.writeln('${"Descuento".padRight(20)} -${Formatters.formatCurrency(discount).padLeft(9)}');
    }
    buffer.writeln('${"IGV (18%)".padRight(20)} ${Formatters.formatCurrency(tax).padLeft(10)}');
    buffer.writeln('───────────────────────────────');
    buffer.writeln('${"TOTAL".padRight(20)} ${Formatters.formatCurrency(total).padLeft(10)}');
    buffer.writeln('');
    buffer.writeln('  ¡Gracias por su compra!');
    buffer.writeln('  Vuelva pronto a Tienda Gamez');
    return buffer.toString();
  }

  Future<void> _printTicket(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impresión Bluetooth no disponible en esta versión'),
        backgroundColor: AppTheme.warningColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _shareTicket(BuildContext context) async {
    await Share.share(
      _ticketText,
      subject: 'Comprobante $_ticketNumber - Tienda Gamez',
    );
  }

  Future<void> _copyTicket(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _ticketText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Comprobante copiado al portapapeles'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'TIENDA GAMEZ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ticket: $_ticketNumber',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info row
                  _infoLine(Icons.calendar_today, Formatters.formatDateTime(date)),
                  _infoLine(Icons.payment, paymentMethod),
                  if (customerName != null)
                    _infoLine(Icons.person, customerName!),

                  const Divider(height: 24),

                  // Items header
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('Producto', style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        )),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text('Cant', style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ), textAlign: TextAlign.center),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text('Total', style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 1),

                  // Items
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            item.productName,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            Formatters.formatCurrency(item.subtotal),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  )),

                  const Divider(height: 1),

                  // Totals
                  const SizedBox(height: 8),
                  _totalLine('Subtotal', Formatters.formatCurrency(subtotal)),
                  if (discount > 0)
                    _totalLine('Descuento', '-${Formatters.formatCurrency(discount)}',
                        color: AppTheme.successColor),
                  _totalLine('IGV (18%)', Formatters.formatCurrency(tax)),
                  const Divider(height: 1),
                  _totalLine('TOTAL', Formatters.formatCurrency(total),
                      bold: true, color: AppTheme.primaryColor),

                  const SizedBox(height: 16),

                  // Thank you
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.favorite, color: AppTheme.errorColor.withValues(alpha: 0.6), size: 20),
                        const SizedBox(height: 4),
                        Text(
                          '¡Gracias por su compra!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _printTicket(context),
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Imprimir', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareTicket(context),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Compartir', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyTicket(context),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copiar', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _totalLine(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 14 : 13,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 14 : 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
