import 'package:flutter/foundation.dart';

import '../../domain/entities/sale_item.dart';

/// Result of a print operation.
class PrintResult {
  final bool success;
  final String message;

  const PrintResult({required this.success, required this.message});
}

/// Stub PrinterService — Bluetooth printing is not available in this build.
///
/// The previous implementation relied on `flutter_bluetooth_basic` which is
/// incompatible with Flutter 3.38.x. Printing will be re-added with a modern
/// library in a future release.
class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // ---------------------------------------------------------------------------
  // State — all hard-coded to "not available"
  // ---------------------------------------------------------------------------

  List<Object> get devices => [];
  Object? get selectedPrinter => null;
  bool get isScanning => false;
  bool get isConnected => false;
  String? get selectedPrinterName => null;

  // ---------------------------------------------------------------------------
  // Persistence stubs
  // ---------------------------------------------------------------------------

  Future<bool> tryReconnect() async => false;

  // ---------------------------------------------------------------------------
  // Discovery stubs
  // ---------------------------------------------------------------------------

  Future<void> startScan() async {
    debugPrint('[PrinterService] Escaneo no disponible en esta versión');
    notifyListeners();
  }

  void stopScan() {
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Connection stubs
  // ---------------------------------------------------------------------------

  Future<bool> connectToPrinter(Object printer) async {
    debugPrint('[PrinterService] Conexión no disponible en esta versión');
    return false;
  }

  Future<void> disconnect() async {
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Printing stub
  // ---------------------------------------------------------------------------

  Future<PrintResult> printTicket({
    int? saleId,
    DateTime? date,
    List<SaleItem>? items,
    double subtotal = 0,
    double discount = 0,
    double tax = 0,
    double total = 0,
    String paymentMethod = '',
    String? customerName,
    String? businessName,
    String? businessPhone,
  }) async {
    return const PrintResult(
      success: false,
      message: 'Impresión Bluetooth no disponible en esta versión',
    );
  }
}
