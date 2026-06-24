import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:workmanager/workmanager.dart';

import '../data/database/database_helper.dart';
import '../core/constants/app_constants.dart';
import 'app_state.dart';
import 'auth_service.dart';

const String kDailyDriveBackupTask = 'daily_drive_backup';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kDailyDriveBackupTask) {
      await GoogleDriveBackupService.instance.performScheduledBackup();
    }
    return Future.value(true);
  });
}

class GoogleDriveBackupService {
  GoogleDriveBackupService._();

  static final GoogleDriveBackupService instance = GoogleDriveBackupService._();

  static const _backupPrefix = 'tienda_gamez_backup_';

  Future<void> bootstrap() async {
    final account = await AuthService.instance.signInSilently();
    if (account != null) {
      await preferencesService.setGoogleDriveSession(
        signedIn: true,
        email: account.email,
        displayName: account.displayName,
      );
      if (preferencesService.autoDriveBackupEnabled) {
        await scheduleDailyBackup();
      }
    } else if (preferencesService.googleDriveSignedIn) {
      await preferencesService.clearGoogleDriveSession();
      await cancelScheduledBackup();
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    final account = await AuthService.instance.signInWithGoogle();
    if (account != null) {
      await preferencesService.setGoogleDriveSession(
        signedIn: true,
        email: account.email,
        displayName: account.displayName,
      );
      if (preferencesService.autoDriveBackupEnabled) {
        await scheduleDailyBackup();
      }
    }
    return account;
  }

  Future<void> signOut() async {
    await cancelScheduledBackup();
    await AuthService.instance.signOut();
    await preferencesService.clearGoogleDriveSession();
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await preferencesService.setAutoDriveBackupEnabled(enabled);
    if (enabled) {
      await scheduleDailyBackup();
    } else {
      await cancelScheduledBackup();
    }
  }

  Future<void> scheduleDailyBackup() async {
    final initialDelay = _delayUntilNextRun(hour: 2, minute: 0);
    await Workmanager().registerPeriodicTask(
      kDailyDriveBackupTask,
      kDailyDriveBackupTask,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  Future<void> cancelScheduledBackup() async {
    await Workmanager().cancelByUniqueName(kDailyDriveBackupTask);
  }

  Future<bool> performScheduledBackup() async {
    if (!preferencesService.autoDriveBackupEnabled) return true;
    final account = await AuthService.instance.signInSilently();
    if (account == null) return false;
    return _uploadBackup(account: account);
  }

  Future<String?> uploadBackupNow() async {
    final account = await AuthService.instance.signInSilently();
    if (account == null) return null;
    final ok = await _uploadBackup(account: account);
    return ok ? 'Backup subido correctamente' : null;
  }

  Future<String?> restoreLatestBackup() async {
    final client = await AuthService.instance.getAuthenticatedClient();
    if (client == null) {
      return 'Debes iniciar sesión con Google para restaurar desde Drive';
    }

    try {
      final api = drive.DriveApi(client);
      final latest = await _getLatestBackup(api);
      if (latest == null) {
        return 'No se encontró ningún backup en Drive';
      }

      final media = await api.files.get(
        latest.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final tempDir = await getTemporaryDirectory();
      final restorePath = p.join(tempDir.path, latest.name ?? 'restore.db');
      await io.File(restorePath).writeAsBytes(bytes, flush: true);
      await DatabaseHelper.importBackup(restorePath);
      await preferencesService.setLastDriveBackupAt(DateTime.now());
      return 'Backup restaurado desde Drive';
    } catch (error) {
      throw Exception(_driveErrorMessage(error));
    }
  }

  Future<String?> getLatestBackupLabel() async {
    final client = await AuthService.instance.getAuthenticatedClient();
    if (client == null) return null;
    final api = drive.DriveApi(client);
    final latest = await _getLatestBackup(api);
    if (latest == null) return null;
    return latest.name;
  }

  Future<bool> _uploadBackup({required GoogleSignInAccount account}) async {
    final client = await AuthService.instance.getAuthenticatedClient();
    if (client == null) return false;

    try {
      final api = drive.DriveApi(client);
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final filename = '$_backupPrefix${_timestamp(now)}.db';
      final localPath = p.join(tempDir.path, filename);

      await DatabaseHelper.exportBackup(localPath);

      final file = io.File(localPath);
      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File()
        ..name = filename
        ..appProperties = {
          'app': AppConstants.appName,
          'type': 'database_backup',
        };

      final created = await api.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id,name,modifiedTime',
      );

      await preferencesService.setLastDriveBackupAt(now);
      debugPrint('Backup subido a Drive: ${created.name} (${account.email})');
      return true;
    } catch (error) {
      throw Exception(_driveErrorMessage(error));
    }
  }

  Future<drive.File?> _getLatestBackup(drive.DriveApi api) async {
    final response = await api.files.list(
      q: "name contains '$_backupPrefix' and trashed = false",
      orderBy: 'modifiedTime desc',
      pageSize: 1,
      $fields: 'files(id,name,modifiedTime)',
    );

    final files = response.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  Duration _delayUntilNextRun({required int hour, required int minute}) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled.difference(now);
  }

  String _timestamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}_${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }

  String _driveErrorMessage(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('status: 403') &&
        lower.contains('drive.googleapis.com') &&
        (lower.contains('has not been used') || lower.contains('disabled'))) {
      return 'La API de Google Drive no está habilitada para este proyecto de Google Cloud. '
          'Actívala en Google Cloud Console, espera unos minutos y vuelve a intentar.';
    }

    if (lower.contains('status: 401') || lower.contains('unauthorized')) {
      return 'La sesión de Google venció o no tiene permisos. Cierra sesión, inicia de nuevo e intenta otra vez.';
    }

    return 'Error al comunicarse con Google Drive: $raw';
  }
}
