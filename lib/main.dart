import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/navigation/app_router.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';

final PreferencesService preferencesService = PreferencesService();

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
