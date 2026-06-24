import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_state.dart';
import 'drive_backup_service.dart';

/// Service that triggers automatic backups after data changes.
/// Debounces rapid changes to avoid excessive uploads.
class RealtimeBackupService {
  RealtimeBackupService._();

  static final RealtimeBackupService instance = RealtimeBackupService._();

  Timer? _debounceTimer;
  bool _backupInProgress = false;
  static const _debounceDuration = Duration(seconds: 5);

  /// Called after any data change (insert, update, delete).
  /// Debounces to avoid backing up on every rapid change.
  void onDatabaseChanged() {
    if (!preferencesService.userLoggedIn) return;
    if (!preferencesService.autoDriveBackupEnabled) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _performBackup);
  }

  Future<void> _performBackup() async {
    if (_backupInProgress) return;

    _backupInProgress = true;
    try {
      debugPrint('RealtimeBackup: Iniciando backup automático...');
      await GoogleDriveBackupService.instance.uploadBackupNow();
      debugPrint('RealtimeBackup: Backup completado');
    } catch (e) {
      debugPrint('RealtimeBackup: Error en backup: $e');
    } finally {
      _backupInProgress = false;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
