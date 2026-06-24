import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

/// Manages app-wide preferences like dark mode.
/// Provides reactive theme data and persistence via SharedPreferences.
class PreferencesService extends ChangeNotifier {
  static const _keyDarkMode = 'dark_mode';
  static const _keyGoogleDriveSignedIn = 'google_drive_signed_in';
  static const _keyGoogleDriveEmail = 'google_drive_email';
  static const _keyGoogleDriveDisplayName = 'google_drive_display_name';
  static const _keyAutoDriveBackupEnabled = 'auto_drive_backup_enabled';
  static const _keyLastDriveBackupAt = 'last_drive_backup_at';
  static const _keyUserLoggedIn = 'user_logged_in';
  static const _keyUserEmail = 'user_email';
  static const _keyUserDisplayName = 'user_display_name';

  bool _isDarkMode = false;
  bool _googleDriveSignedIn = false;
  String? _googleDriveEmail;
  String? _googleDriveDisplayName;
  bool _autoDriveBackupEnabled = true;
  DateTime? _lastDriveBackupAt;
  bool _userLoggedIn = false;
  String? _userEmail;
  String? _userDisplayName;

  bool get isDarkMode => _isDarkMode;
  bool get googleDriveSignedIn => _googleDriveSignedIn;
  String? get googleDriveEmail => _googleDriveEmail;
  String? get googleDriveDisplayName => _googleDriveDisplayName;
  bool get autoDriveBackupEnabled => _autoDriveBackupEnabled;
  DateTime? get lastDriveBackupAt => _lastDriveBackupAt;
  bool get userLoggedIn => _userLoggedIn;
  String? get userEmail => _userEmail;
  String? get userDisplayName => _userDisplayName;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get currentTheme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  /// Load saved preference from disk.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _googleDriveSignedIn = prefs.getBool(_keyGoogleDriveSignedIn) ?? false;
    _googleDriveEmail = prefs.getString(_keyGoogleDriveEmail);
    _googleDriveDisplayName = prefs.getString(_keyGoogleDriveDisplayName);
    _autoDriveBackupEnabled = prefs.getBool(_keyAutoDriveBackupEnabled) ?? true;
    final lastBackupAtIso = prefs.getString(_keyLastDriveBackupAt);
    _lastDriveBackupAt = lastBackupAtIso != null ? DateTime.tryParse(lastBackupAtIso) : null;
    _userLoggedIn = prefs.getBool(_keyUserLoggedIn) ?? false;
    _userEmail = prefs.getString(_keyUserEmail);
    _userDisplayName = prefs.getString(_keyUserDisplayName);
    notifyListeners();
  }

  /// Toggle dark/light mode and persist.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, _isDarkMode);
    notifyListeners();
  }

  /// Set a specific theme mode.
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, _isDarkMode);
    notifyListeners();
  }

  Future<void> setGoogleDriveSession({
    required bool signedIn,
    String? email,
    String? displayName,
  }) async {
    _googleDriveSignedIn = signedIn;
    _googleDriveEmail = email;
    _googleDriveDisplayName = displayName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGoogleDriveSignedIn, signedIn);
    if (email == null || email.isEmpty) {
      await prefs.remove(_keyGoogleDriveEmail);
    } else {
      await prefs.setString(_keyGoogleDriveEmail, email);
    }
    if (displayName == null || displayName.isEmpty) {
      await prefs.remove(_keyGoogleDriveDisplayName);
    } else {
      await prefs.setString(_keyGoogleDriveDisplayName, displayName);
    }
    notifyListeners();
  }

  Future<void> clearGoogleDriveSession() async {
    _googleDriveSignedIn = false;
    _googleDriveEmail = null;
    _googleDriveDisplayName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGoogleDriveSignedIn, false);
    await prefs.remove(_keyGoogleDriveEmail);
    await prefs.remove(_keyGoogleDriveDisplayName);
    notifyListeners();
  }

  Future<void> setAutoDriveBackupEnabled(bool value) async {
    if (_autoDriveBackupEnabled == value) return;
    _autoDriveBackupEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDriveBackupEnabled, value);
    notifyListeners();
  }

  Future<void> setLastDriveBackupAt(DateTime value) async {
    _lastDriveBackupAt = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDriveBackupAt, value.toIso8601String());
    notifyListeners();
  }

  Future<void> setUserSession({
    required bool loggedIn,
    String? email,
    String? displayName,
  }) async {
    _userLoggedIn = loggedIn;
    _userEmail = email;
    _userDisplayName = displayName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUserLoggedIn, loggedIn);
    if (email == null || email.isEmpty) {
      await prefs.remove(_keyUserEmail);
    } else {
      await prefs.setString(_keyUserEmail, email);
    }
    if (displayName == null || displayName.isEmpty) {
      await prefs.remove(_keyUserDisplayName);
    } else {
      await prefs.setString(_keyUserDisplayName, displayName);
    }
    notifyListeners();
  }

  Future<void> clearUserSession() async {
    _userLoggedIn = false;
    _userEmail = null;
    _userDisplayName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUserLoggedIn, false);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserDisplayName);
    notifyListeners();
  }
}
