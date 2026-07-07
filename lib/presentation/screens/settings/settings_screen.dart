import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import '../../../services/app_state.dart';
import '../../../services/drive_backup_service.dart';
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
  final _businessNameController = TextEditingController(
    text: AppConstants.appName,
  );
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSigningInGoogle = false;
  bool _isUploadingDriveBackup = false;
  bool _isRestoringDriveBackup = false;
  bool _askedForGoogleLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _promptGoogleLoginIfNeeded(),
    );
  }

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
      final filename =
          'tienda_gamez_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.db';

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

  void _showInfo(
    String message, {
    Color backgroundColor = AppTheme.successColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _promptGoogleLoginIfNeeded() async {
    if (!mounted ||
        _askedForGoogleLogin ||
        preferencesService.googleDriveSignedIn)
      return;
    _askedForGoogleLogin = true;
    final connectNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conectar Google Drive'),
        content: const Text(
          'Para subir respaldos automáticos y restaurar datos desde Drive, debes iniciar sesión con Google.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Más tarde'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
    if (connectNow == true && mounted) {
      await _connectGoogleDrive();
    }
  }

  Future<void> _connectGoogleDrive() async {
    setState(() => _isSigningInGoogle = true);
    try {
      final account = await GoogleDriveBackupService.instance.signIn();
      if (!mounted) return;
      if (account != null) {
        _showInfo(
          'Google conectado como ${account.displayName ?? account.email}',
        );
      } else {
        _showInfo(
          'No se pudo conectar con Google',
          backgroundColor: AppTheme.warningColor,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al conectar con Google', e);
      }
    } finally {
      if (mounted) setState(() => _isSigningInGoogle = false);
    }
  }

  Future<void> _disconnectGoogleDrive() async {
    try {
      await GoogleDriveBackupService.instance.signOut();
      if (mounted) {
        setState(() {});
        _showInfo('Sesión de Google cerrada');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al cerrar sesión', e);
      }
    }
  }

  Future<void> _uploadDriveBackup() async {
    if (!preferencesService.googleDriveSignedIn) {
      final connected = await _connectGoogleDriveForAction();
      if (!connected) return;
    }
    setState(() => _isUploadingDriveBackup = true);
    try {
      final message = await GoogleDriveBackupService.instance.uploadBackupNow();
      if (!mounted) return;
      if (message != null) {
        _showInfo(message);
      } else {
        _showInfo(
          'Debes iniciar sesión con Google para subir el respaldo',
          backgroundColor: AppTheme.warningColor,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al subir backup a Drive', e);
      }
    } finally {
      if (mounted) setState(() => _isUploadingDriveBackup = false);
    }
  }

  Future<void> _restoreDriveBackup() async {
    if (!preferencesService.googleDriveSignedIn) {
      final connected = await _connectGoogleDriveForAction();
      if (!connected) return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar desde Drive'),
        content: const Text(
          'Esto reemplazará la base de datos actual con el último respaldo en Drive. '
          '¿Deseas continuar?',
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

    if (confirmed != true) return;

    setState(() => _isRestoringDriveBackup = true);
    try {
      final message = await GoogleDriveBackupService.instance
          .restoreLatestBackup();
      if (!mounted) return;
      if (message != null) {
        _showInfo(message);
      } else {
        _showInfo(
          'No fue posible restaurar el respaldo',
          backgroundColor: AppTheme.warningColor,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al restaurar desde Drive', e);
      }
    } finally {
      if (mounted) setState(() => _isRestoringDriveBackup = false);
    }
  }

  Future<void> _toggleAutoDriveBackup(bool value) async {
    try {
      await GoogleDriveBackupService.instance.setAutoBackupEnabled(value);
      if (mounted) {
        setState(() {});
        _showInfo(
          value
              ? 'Respaldo automático activado'
              : 'Respaldo automático desactivado',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('No se pudo cambiar el respaldo automático', e);
      }
    }
  }

  Future<bool> _connectGoogleDriveForAction() async {
    if (preferencesService.googleDriveSignedIn) return true;
    await _connectGoogleDrive();
    return preferencesService.googleDriveSignedIn;
  }

  String _formatLastBackup(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Nunca';
    }
    return Formatters.formatDateTime(dateTime);
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
        actions: [
          IconButton(
            tooltip: preferencesService.isDarkMode
                ? 'Cambiar a modo claro'
                : 'Cambiar a modo oscuro',
            onPressed: () async {
              await preferencesService.toggleTheme();
              if (mounted) setState(() {});
            },
            icon: Icon(
              preferencesService.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business info section
          Text(
            'Datos del Negocio',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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

          // Appearance section
          Text(
            'Apariencia',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: preferencesService.isDarkMode
                      ? AppTheme.brandRed.withValues(alpha: 0.35)
                      : AppTheme.greyLight,
                ),
                color: preferencesService.isDarkMode
                    ? AppTheme.brandRed.withValues(alpha: 0.08)
                    : Colors.white,
              ),
              child: SwitchListTile(
                secondary: CircleAvatar(
                  radius: 16,
                  backgroundColor: preferencesService.isDarkMode
                      ? AppTheme.brandRed.withValues(alpha: 0.15)
                      : AppTheme.warningColor.withValues(alpha: 0.15),
                  child: Icon(
                    preferencesService.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    size: 18,
                    color: preferencesService.isDarkMode
                        ? AppTheme.brandRed
                        : AppTheme.warningColor,
                  ),
                ),
                title: const Text(
                  'Modo Oscuro',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  preferencesService.isDarkMode ? 'Activado' : 'Desactivado',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: preferencesService.isDarkMode,
                activeThumbColor: AppTheme.brandRed,
                onChanged: (_) async {
                  await preferencesService.toggleTheme();
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Drive backup section
          Text(
            'Google Drive y Respaldo',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: preferencesService.googleDriveSignedIn
                        ? AppTheme.successColor.withValues(alpha: 0.15)
                        : AppTheme.warningColor.withValues(alpha: 0.15),
                    child: Icon(
                      preferencesService.googleDriveSignedIn
                          ? Icons.cloud_done
                          : Icons.cloud_upload,
                      color: preferencesService.googleDriveSignedIn
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                  ),
                  title: Text(
                    preferencesService.googleDriveSignedIn
                        ? 'Cuenta conectada'
                        : 'Conecta tu cuenta de Google',
                  ),
                  subtitle: Text(
                    preferencesService.googleDriveSignedIn
                        ? '${preferencesService.googleDriveDisplayName ?? preferencesService.googleDriveEmail ?? 'Google'}\nÚltimo respaldo: ${_formatLastBackup(preferencesService.lastDriveBackupAt)}'
                        : 'Sube y restaura respaldo en Drive, con copia diaria automática.',
                  ),
                  isThreeLine: preferencesService.googleDriveSignedIn,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Subir backup automáticamente, diariamente',
                    ),
                    subtitle: const Text(
                      'Se ejecuta cuando la app tenga acceso a Google Drive',
                    ),
                    value: preferencesService.autoDriveBackupEnabled,
                    onChanged: _toggleAutoDriveBackup,
                    activeColor: AppTheme.brandRed,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 180,
                        child: FilledButton.icon(
                          onPressed: _isSigningInGoogle
                              ? null
                              : (preferencesService.googleDriveSignedIn
                                    ? _disconnectGoogleDrive
                                    : _connectGoogleDrive),
                          icon: _isSigningInGoogle
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  preferencesService.googleDriveSignedIn
                                      ? Icons.logout
                                      : Icons.login,
                                ),
                          label: Text(
                            preferencesService.googleDriveSignedIn
                                ? 'Cerrar sesión'
                                : 'Conectar Google',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: OutlinedButton.icon(
                          onPressed:
                              preferencesService.googleDriveSignedIn &&
                                  !_isUploadingDriveBackup
                              ? _uploadDriveBackup
                              : null,
                          icon: _isUploadingDriveBackup
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.backup),
                          label: const Text('Subir backup a Drive'),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: OutlinedButton.icon(
                          onPressed:
                              preferencesService.googleDriveSignedIn &&
                                  !_isRestoringDriveBackup
                              ? _restoreDriveBackup
                              : null,
                          icon: _isRestoringDriveBackup
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.restore),
                          label: const Text('Restaurar Drive'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Local backup section
          Text(
            'Respaldo Local y Restauración',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      : Icon(Icons.backup, color: AppTheme.primaryColor),
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
                  subtitle: const Text(
                    'Recuperar datos desde un respaldo (.db)',
                  ),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.store, color: AppTheme.primaryColor),
                  title: Text('Tienda Gamez'),
                  subtitle: Text('Versión 1.0.0'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.code, color: AppTheme.primaryColor),
                  title: Text('Desarrollado por Gamez Code Solutions'),
                  // subtitle: Text('Clean Architecture + BLoC + SQLite'),
                  subtitle: Text('https://gamezsolutions.online'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
