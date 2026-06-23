import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../data/database/database_helper.dart';
import '../domain/entities/debt.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _overdueChannelId = 'overdue_credits';
  static const String _dueSoonChannelId = 'due_soon_credits';

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _overdueChannelId,
        'Créditos Vencidos',
        description: 'Notificaciones de créditos vencidos',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dueSoonChannelId,
        'Créditos por Vencer',
        description: 'Recordatorios de créditos próximos a vencer',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Notification tap handling can be implemented here if needed
  }

  Future<void> showDebtNotification(Debt debt, {bool isOverdue = false}) async {
    final id = debt.id ?? DateTime.now().millisecondsSinceEpoch;
    final remaining = debt.amount - debt.paidAmount;

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        isOverdue ? _overdueChannelId : _dueSoonChannelId,
        isOverdue ? 'Créditos Vencidos' : 'Créditos por Vencer',
        importance: isOverdue ? Importance.high : Importance.defaultImportance,
        priority: isOverdue ? Priority.high : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final title = isOverdue
        ? '🔴 Crédito Vencido'
        : '🟡 Crédito por Vencer';
    final body = isOverdue
        ? '${debt.customerName} — S/${remaining.toStringAsFixed(2)} pendiente (venció ${_formatDate(debt.dueDate)})'
        : '${debt.customerName} — S/${remaining.toStringAsFixed(2)} vence el ${_formatDate(debt.dueDate)}';

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: '/debts/${debt.id}',
    );
  }

  Future<void> showSummaryNotification({
    required List<Debt> overdue,
    required List<Debt> dueSoon,
  }) async {
    if (overdue.isEmpty && dueSoon.isEmpty) return;

    final isOverdue = overdue.isNotEmpty;
    final channelId = isOverdue ? _overdueChannelId : _dueSoonChannelId;
    final channelName = isOverdue ? 'Créditos Vencidos' : 'Créditos por Vencer';

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: isOverdue ? Importance.high : Importance.defaultImportance,
        priority: isOverdue ? Priority.high : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        styleInformation: _buildSummaryStyle(overdue, dueSoon),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    String title;
    String body;

    if (overdue.isNotEmpty && dueSoon.isNotEmpty) {
      title = '🔴 ${overdue.length} vencido(s) · ${dueSoon.length} por vencer';
      body = 'Toca para ver los detalles de tus créditos pendientes';
    } else if (overdue.isNotEmpty) {
      title = '🔴 ${overdue.length} crédito(s) vencido(s)';
      body = 'Total pendiente: S/${overdue.fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount)).toStringAsFixed(2)}';
    } else {
      title = '🟡 ${dueSoon.length} crédito(s) por vencer';
      body = 'Revisa tus créditos próximos a vencer';
    }

    await _plugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: '/debts',
    );
  }

  InboxStyleInformation? _buildSummaryStyle(List<Debt> overdue, List<Debt> dueSoon) {
    final lines = <String>[];
    for (final d in overdue) {
      lines.add('🔴 ${d.customerName} — S/${(d.amount - d.paidAmount).toStringAsFixed(2)} (vencido)');
    }
    for (final d in dueSoon) {
      lines.add('🟡 ${d.customerName} — S/${(d.amount - d.paidAmount).toStringAsFixed(2)}');
    }
    if (lines.isEmpty) return null;
    return InboxStyleInformation(
      lines,
      contentTitle: 'Alertas de Créditos',
      summaryText: '${overdue.length} vencidos · ${dueSoon.length} por vencer',
    );
  }

  Future<void> scheduleDailyCheck({int hour = 8, int minute = 0}) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id: 888,
      scheduledDate: tzScheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _dueSoonChannelId,
          'Créditos por Vencer',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Revisa tus créditos pendientes',
      body: 'Toca para ver el estado de tus créditos',
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/debts',
    );
  }

  Future<void> checkAndNotify() async {
    try {
      await initialize();
      final overdue = await DatabaseHelper.getOverdueDebts();
      final dueSoon = await DatabaseHelper.getDebtsDueSoon(3);
      if (overdue.isEmpty && dueSoon.isEmpty) return;
      await showSummaryNotification(overdue: overdue, dueSoon: dueSoon);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
