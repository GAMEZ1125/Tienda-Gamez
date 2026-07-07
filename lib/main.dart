import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'services/app_state.dart';
import 'services/subscription_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/navigation/app_router.dart';
import 'services/notification_service.dart';
import 'services/drive_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load saved preferences (e.g., dark mode)
  await preferencesService.load();

  // Initialize local notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Check for overdue/due-soon debts and show notification
  await notificationService.checkAndNotify();

  // Schedule daily check at 8:00 AM
  await notificationService.scheduleDailyCheck();

  // Initialize background tasks for Drive backups
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  // Initialize Google Drive backup session and schedule if available
  await GoogleDriveBackupService.instance.bootstrap();

  // Initialize subscription service or switch to free mode.
  await SubscriptionService.instance.init();

  runApp(const TiendaGamezApp());
}

class TiendaGamezApp extends StatefulWidget {
  const TiendaGamezApp({super.key});

  @override
  State<TiendaGamezApp> createState() => _TiendaGamezAppState();
}

class _TiendaGamezAppState extends State<TiendaGamezApp> {
  @override
  void initState() {
    super.initState();
    preferencesService.addListener(_onPreferenceChange);
  }

  @override
  void dispose() {
    preferencesService.removeListener(_onPreferenceChange);
    super.dispose();
  }

  void _onPreferenceChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferencesService.themeMode,
      routerConfig: appRouter,
    );
  }
}
