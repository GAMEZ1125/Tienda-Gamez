import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/app_state.dart';
import '../../../services/auth_service.dart';
import '../../../services/drive_backup_service.dart';
import '../../../services/subscription_service.dart';
import '../subscription/premium_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _error;
  String? _status;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _status = 'Iniciando sesión...';
    });

    try {
      final account = await AuthService.instance.signInWithGoogle();
      if (account == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Inicio de sesión cancelado';
          });
        }
        return;
      }

      await preferencesService.setUserSession(
        loggedIn: true,
        email: account.email,
        displayName: account.displayName,
      );

      await preferencesService.setGoogleDriveSession(
        signedIn: true,
        email: account.email,
        displayName: account.displayName,
      );

      // Check for existing backups on Drive
      if (mounted) {
        setState(() => _status = 'Buscando respaldos en Drive...');
      }

      final hasBackups = await GoogleDriveBackupService.instance.hasExistingBackups();

      if (!hasBackups) {
        // First time with this account - create initial backup
        if (mounted) {
          setState(() => _status = 'Creando respaldo inicial...');
        }
        await GoogleDriveBackupService.instance.uploadBackupNow();

        if (mounted) {
          context.go('/home');
        }
        return;
      }

      // Account has existing backups - offer to restore
      if (mounted) {
        final shouldRestore = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.cloud_download_rounded, size: 40, color: AppTheme.brandRed),
            title: const Text('Respaldo encontrado'),
            content: const Text(
              'Esta cuenta ya tiene datos respaldados en Google Drive. '
              '¿Deseas restaurarlos?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No, usar vacío'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí, restaurar'),
              ),
            ],
          ),
        );

        if (shouldRestore == true) {
          if (mounted) {
            setState(() => _status = 'Restaurando datos desde Drive...');
          }

          try {
            await GoogleDriveBackupService.instance.restoreLatestBackup();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos restaurados correctamente'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al restaurar: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        }
      }

      // Schedule auto-backup
      if (preferencesService.autoDriveBackupEnabled) {
        await GoogleDriveBackupService.instance.scheduleDailyBackup();
      }

      if (mounted) {
        if (!SubscriptionService.instance.isPremium) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumScreen()),
          ).then((_) => context.go('/home'));
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al iniciar sesión: $e';
        });
      }
    }
  }

  Future<void> _skipLogin() async {
    await preferencesService.setUserSession(loggedIn: true);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.brandRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/TiendaGamez_logo.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.store_rounded,
                        size: 50,
                        color: AppTheme.brandRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // App name
                Text(
                  preferencesService.businessName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistema POS para tu tienda',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                  ),
                ),
                const SizedBox(height: 48),

                // Status indicator
                if (_isLoading && _status != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.brandRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.brandRed.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandRed),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _status!,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Google Sign-In button
                if (!_isLoading)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F1F1F),
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFDADCE0)),
                        ),
                      ),
                        child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'G',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Continuar con Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFF59E0B)),
                        ],
                      ),
                    ),
                  ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Skip login
                if (!_isLoading)
                  TextButton(
                    onPressed: _skipLogin,
                    child: Text(
                      'Usar sin cuenta (Versión Gratuita)',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                      ),
                    ),
                  ),

                if (!_isLoading) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Incluye suscripción Premium y respaldo en Drive',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
