import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
    if (tax > 0) {
      buffer.writeln('${"IGV".padRight(20)} ${Formatters.formatCurrency(tax).padLeft(10)}');
    }
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
    try {
      final bytes = await _buildTicketImageBytes();
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'ticket_$_ticketNumber.png'));
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Comprobante $_ticketNumber - Tienda Gamez',
        subject: 'Comprobante $_ticketNumber - Tienda Gamez',
      );
    } catch (_) {
      await Share.share(
        _ticketText,
        subject: 'Comprobante $_ticketNumber - Tienda Gamez',
      );
    }
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
                  if (tax > 0)
                    _totalLine('IGV', Formatters.formatCurrency(tax)),
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

  Future<Uint8List> _buildTicketImageBytes() async {
    const width = 1080;
    const horizontalPadding = 56.0;
    final cardWidth = width - 112.0;
    final itemRowHeight = items.length * 108.0;
    final discountHeight = discount > 0 ? 32.0 : 0.0;
    final taxHeight = tax > 0 ? 32.0 : 0.0;
    final totalHeight = (420 +
            itemRowHeight +
            discountHeight +
            taxHeight +
            160)
        .ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bgPaint = Paint()..color = const Color(0xFFF5F1EA);
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), totalHeight.toDouble()), bgPaint);

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(horizontalPadding, 48.0, cardWidth, totalHeight - 96.0),
      const Radius.circular(32),
    );
    canvas.drawShadow(Path()..addRRect(cardRect), Colors.black.withValues(alpha: 0.16), 14, true);
    canvas.drawRRect(
      cardRect,
      Paint()..color = Colors.white,
    );

    double y = 72;
    final centerX = width / 2;

    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(56.0, 48.0, cardWidth, 220.0),
      const Radius.circular(32),
    );
    final headerPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(56, 48),
        const Offset(1024, 268),
        [AppTheme.brandRed, AppTheme.brandRed.withValues(alpha: 0.85)],
      );
    canvas.drawRRect(headerRect, headerPaint);

    _drawCircle(canvas, Offset(centerX, 122), 42, Colors.white.withValues(alpha: 0.95));
    _drawText(
      canvas,
      'TG',
      const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: AppTheme.brandRed,
      ),
      centerX,
      102,
      align: TextAlign.center,
      maxWidth: 120,
    );
    _drawText(
      canvas,
      'TIENDA GAMEZ',
      const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Colors.white,
      ),
      centerX,
      178,
      align: TextAlign.center,
      maxWidth: 700,
    );
    _drawText(
      canvas,
      'Ticket $_ticketNumber',
      const TextStyle(
        fontSize: 18,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
      ),
      centerX,
      220,
      align: TextAlign.center,
      maxWidth: 700,
    );

    y = 300;
    _drawText(canvas, 'Fecha', _sectionLabelStyle, 96, y);
    _drawText(canvas, Formatters.formatDateTime(date), _sectionValueStyle, 240, y);
    y += 34;
    _drawText(canvas, 'Método', _sectionLabelStyle, 96, y);
    _drawText(canvas, paymentMethod, _sectionValueStyle, 240, y);
    y += 34;
    if (customerName != null) {
      _drawText(canvas, 'Cliente', _sectionLabelStyle, 96, y);
      _drawText(canvas, customerName!, _sectionValueStyle, 240, y);
      y += 34;
    }

    y += 18;
    canvas.drawLine(
      Offset(96, y),
      Offset(width - 96, y),
      Paint()
        ..color = AppTheme.greyLight
        ..strokeWidth = 2,
    );
    y += 24;

    _drawText(canvas, 'Producto', _headerStyle, 96, y);
    _drawText(canvas, 'Cant', _headerStyle, 760, y, align: TextAlign.center, maxWidth: 80);
    _drawText(canvas, 'Total', _headerStyle, 874, y, align: TextAlign.right, maxWidth: 120);
    y += 18;
    canvas.drawLine(
      Offset(96, y),
      Offset(width - 96, y),
      Paint()
        ..color = AppTheme.greyLight
        ..strokeWidth = 1.5,
    );
    y += 18;

    for (final item in items) {
      final rowTop = y;
      final rowHeight = 92.0;
      _drawText(
        canvas,
        item.productName,
        const TextStyle(fontSize: 24, color: Color(0xFF1F1F1F), fontWeight: FontWeight.w600),
        96,
        rowTop,
        maxWidth: 620,
      );
      _drawText(
        canvas,
        '${item.quantity}',
        const TextStyle(fontSize: 24, color: Color(0xFF1F1F1F), fontWeight: FontWeight.w700),
        760,
        rowTop,
        align: TextAlign.center,
        maxWidth: 80,
      );
      _drawText(
        canvas,
        Formatters.formatCurrency(item.subtotal),
        TextStyle(fontSize: 24, color: AppTheme.brandRed, fontWeight: FontWeight.bold),
        874,
        rowTop,
        align: TextAlign.right,
        maxWidth: 120,
      );
      y += rowHeight;
      canvas.drawLine(
        Offset(96, y - 8),
        Offset(width - 96, y - 8),
        Paint()
          ..color = const Color(0xFFEDE7DF)
          ..strokeWidth = 1,
      );
    }

    y += 8;
    y = _drawTotalRow(canvas, 'Subtotal', Formatters.formatCurrency(subtotal), y);
    if (discount > 0) {
      y = _drawTotalRow(canvas, 'Descuento', '-${Formatters.formatCurrency(discount)}', y, valueColor: AppTheme.successColor);
    }
    if (tax > 0) {
      y = _drawTotalRow(canvas, 'IGV', Formatters.formatCurrency(tax), y);
    }
    canvas.drawLine(
      Offset(96, y + 8),
      Offset(width - 96, y + 8),
      Paint()
        ..color = AppTheme.brandRed.withValues(alpha: 0.25)
        ..strokeWidth = 2,
    );
    y += 28;
    _drawTotalRow(
      canvas,
      'TOTAL',
      Formatters.formatCurrency(total),
      y,
      bold: true,
      valueColor: AppTheme.brandRed,
    );

    y += 72;
    _drawText(
      canvas,
      '¡Gracias por su compra!',
      const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
      centerX,
      y,
      align: TextAlign.center,
      maxWidth: 700,
    );
    y += 36;
    _drawText(
      canvas,
      'Vuelva pronto a Tienda Gamez',
      const TextStyle(fontSize: 20, color: Color(0xFF666666)),
      centerX,
      y,
      align: TextAlign.center,
      maxWidth: 700,
    );

    final image = await recorder.endRecording().toImage(width, totalHeight);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  double _drawTotalRow(
    Canvas canvas,
    String label,
    String value,
    double y, {
    bool bold = false,
    Color? valueColor,
  }) {
    _drawText(
      canvas,
      label,
      TextStyle(
        fontSize: bold ? 26 : 22,
        fontWeight: bold ? FontWeight.bold : FontWeight.w600,
        color: const Color(0xFF333333),
      ),
      96,
      y,
      maxWidth: 400,
    );
    _drawText(
      canvas,
      value,
      TextStyle(
        fontSize: bold ? 26 : 22,
        fontWeight: bold ? FontWeight.bold : FontWeight.w600,
        color: valueColor ?? const Color(0xFF333333),
      ),
      984,
      y,
      align: TextAlign.right,
      maxWidth: 220,
    );
    return y + (bold ? 40 : 34);
  }

  void _drawCircle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  double _drawText(
    Canvas canvas,
    String text,
    TextStyle style,
    double x,
    double y, {
    TextAlign align = TextAlign.left,
    double maxWidth = 800,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 2,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x - (align == TextAlign.center ? painter.width / 2 : 0), y));
    return painter.height;
  }

  static const TextStyle _sectionLabelStyle = TextStyle(
    fontSize: 18,
    color: Color(0xFF888888),
    fontWeight: FontWeight.w600,
  );

  static const TextStyle _sectionValueStyle = TextStyle(
    fontSize: 18,
    color: Color(0xFF1F1F1F),
    fontWeight: FontWeight.w600,
  );

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 18,
    color: Color(0xFF666666),
    fontWeight: FontWeight.w700,
  );

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
