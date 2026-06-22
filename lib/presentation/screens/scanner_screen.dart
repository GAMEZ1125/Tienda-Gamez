import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';

/// Barcode scanner screen that returns the scanned barcode value via Navigator.pop
class ScannerScreen extends StatefulWidget {
  final String title;

  const ScannerScreen({
    super.key,
    this.title = 'Escanear Código',
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      torchEnabled: false,
      detectionTimeoutMs: 500,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _isScanning = false);
        HapticFeedback.heavyImpact();
        _controller?.stop();

        Navigator.pop(context, code);
        return;
      }
    }
  }

  void _switchCamera() {
    _controller?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: _switchCamera,
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text(
                      'Error al iniciar la cámara',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Asegúrate de haber concedido permisos de cámara',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Scan overlay guide
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isScanning
                      ? AppTheme.primaryColor.withValues(alpha: 0.8)
                      : AppTheme.successColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isScanning
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 48,
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enfoca el código de barras',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: AppTheme.successColor,
                      ),
                    ),
            ),
          ),

          // Bottom status card
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isScanning
                            ? 'Esperando código...'
                            : '✅ Código escaneado correctamente',
                        style: TextStyle(
                          color: _isScanning ? Colors.grey : AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!_isScanning)
                      TextButton(
                        onPressed: () {
                          setState(() => _isScanning = true);
                          _controller?.start();
                        },
                        child: const Text('Escanear otro'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
