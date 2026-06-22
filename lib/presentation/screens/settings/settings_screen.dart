import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _businessNameController = TextEditingController(text: AppConstants.appName);
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);

    try {
      // 1. Generate a descriptive filename with date
      final now = DateTime.now();
      final filename = 'tienda_gamez_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.db';

      // 2. Copy the database to a temporary file
      final tempDir = await getTemporaryDirectory();
      final backupPath = p.join(tempDir.path, filename);
      await DatabaseHelper.exportBackup(backupPath);

      // 3. Share the backup file so the user can save it anywhere
      if (mounted) {
        final xFile = XFile(backupPath);
        await Share.shareXFiles(
          [xFile],
          subject: 'Respaldo Tienda Gamez - ${Formatters.formatDate(now)}',
          text: 'Respaldo de base de datos Tienda Gamez',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al exportar respaldo', e);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    // 1. Confirm with the user first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar Base de Datos'),
        content: const Text(
          'Esta acción reemplazará TODOS los datos actuales con los del respaldo. '
          '¿Estás seguro de continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 2. Let the user pick a .db file
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
      );

      if (result == null || result.files.single.path == null) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      final backupPath = result.files.single.path!;

      // 3. Import the backup
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurando datos...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      await DatabaseHelper.importBackup(backupPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Base de datos restaurada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al restaurar respaldo', e);
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showError(String title, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $error'),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _showBackupInfo() async {
    try {
      final size = await DatabaseHelper.getDatabaseSizeBytes();
      final sizeKB = (size / 1024).toStringAsFixed(1);
      final path = await DatabaseHelper.getDatabasePath();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Información del Respaldo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Base de datos', AppConstants.databaseName),
                _infoRow('Tamaño', '$sizeKB KB'),
                _infoRow('Versión', '${AppConstants.databaseVersion}'),
                const SizedBox(height: 8),
                Text(
                  path,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // ignore
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business info section
          Text(
            'Datos del Negocio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Negocio',
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Configuración guardada'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      },
                      child: const Text('Guardar Configuración'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Backup section
          Text(
            'Respaldo y Restauración',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: _isExporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.backup, color: AppTheme.primaryColor),
                  title: const Text('Exportar Base de Datos'),
                  subtitle: const Text('Copia de seguridad de todos los datos'),
                  enabled: !_isExporting && !_isImporting,
                  onTap: _isExporting ? null : _exportBackup,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: _isImporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore, color: AppTheme.warningColor),
                  title: const Text('Restaurar Base de Datos'),
                  subtitle: const Text('Recuperar datos desde un respaldo (.db)'),
                  enabled: !_isExporting && !_isImporting,
                  onTap: _isImporting ? null : _importBackup,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: const Text('Información de la base de datos'),
                  subtitle: const Text('Ver detalles del archivo actual'),
                  onTap: _showBackupInfo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App info
          Text(
            'Acerca de',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.store, color: AppTheme.primaryColor),
                  title: Text('Tienda Gamez'),
                  subtitle: Text('Versión 1.0.0'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const ListTile(
                  leading: Icon(Icons.code, color: AppTheme.primaryColor),
                  title: Text('Desarrollado con Flutter'),
                  subtitle: Text('Clean Architecture + BLoC + SQLite'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
