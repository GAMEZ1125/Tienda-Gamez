import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrinterSetupScreen extends StatelessWidget {
  const PrinterSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impresora Bluetooth'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.bluetooth_disabled,
                  size: 40,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Impresión no disponible',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'La funcionalidad de impresión Bluetooth ha sido\ndesactivada temporalmente en esta versión.\n\n'
                'Estará disponible nuevamente en una\nactualización futura.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
