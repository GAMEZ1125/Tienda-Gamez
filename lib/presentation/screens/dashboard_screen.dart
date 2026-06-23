import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/database_helper.dart';
import '../../domain/entities/debt.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Debt> _overdueDebts = [];
  List<Debt> _dueSoonDebts = [];
  List<Debt> _allDebts = [];
  bool _isLoading = true;
  bool _notificationsShown = false;

  // Calendar state
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Debt>> _calendarEvents = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final stats = await DatabaseHelper.getDashboardStats();
    final overdue = await DatabaseHelper.getOverdueDebts();
    final dueSoon = await DatabaseHelper.getDebtsDueSoon(3);
    final allDebts = await DatabaseHelper.getAllDebts();
    setState(() {
      _stats = stats;
      _overdueDebts = overdue;
      _dueSoonDebts = dueSoon;
      _allDebts = allDebts;
      _calendarEvents = _buildEventsMap(allDebts);
      _isLoading = false;
    });

    // Show notification dialog once per session (after frame is painted)
    if (!_notificationsShown && mounted) {
      _notificationsShown = true;
      final hasOverdue = overdue.isNotEmpty;
      final hasDueSoon = dueSoon.isNotEmpty;
      if (hasOverdue || hasDueSoon) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNotificationDialog(overdue, dueSoon);
        });
      }
    }
  }

  void _showNotificationDialog(List<Debt> overdue, List<Debt> dueSoon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              overdue.isNotEmpty ? Icons.notifications_active : Icons.notifications,
              color: overdue.isNotEmpty ? AppTheme.errorColor : AppTheme.warningColor,
            ),
            const SizedBox(width: 8),
            const Text('Alertas de Créditos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (overdue.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${overdue.length} crédito(s) vencido(s)',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...overdue.take(3).map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(d.customerName, style: const TextStyle(fontSize: 13))),
                    Text(Formatters.formatCurrency(d.amount - d.paidAmount),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorColor)),
                  ],
                ),
              )),
              if (overdue.length > 3)
                Text('Y ${overdue.length - 3} más...', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 12),
            ],
            if (dueSoon.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${dueSoon.length} crédito(s) por vencer (3 días)',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.warningColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.push('/debts');
              });
            },
            child: const Text('Ir a Créditos'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadísticas',
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification banner
                    if (_overdueDebts.isNotEmpty || _dueSoonDebts.isNotEmpty)
                      _buildNotificationBanner(),
                    if (_overdueDebts.isNotEmpty || _dueSoonDebts.isNotEmpty)
                      const SizedBox(height: 12),

                    // Credit summary card
                    _buildCreditSummary(),
                    const SizedBox(height: 16),

                    // Quick stats grid
                    _buildQuickStats(),
                    const SizedBox(height: 16),

                    // Calendar section
                    _buildCalendarSection(),
                    const SizedBox(height: 16),

                    // Overdue debts
                    if (_overdueDebts.isNotEmpty) ...[
                      _buildSectionTitle('Créditos Vencidos', Icons.warning_amber, AppTheme.errorColor),
                      const SizedBox(height: 8),
                      ..._overdueDebts.take(3).map((d) => _debtTile(d, true)),
                      if (_overdueDebts.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: TextButton(
                            onPressed: () => context.push('/debts'),
                            child: Text('Ver ${_overdueDebts.length - 3} más vencidos...'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Due soon
                    if (_dueSoonDebts.isNotEmpty) ...[
                      _buildSectionTitle('Próximos a Vencer', Icons.schedule, AppTheme.warningColor),
                      const SizedBox(height: 8),
                      ..._dueSoonDebts.take(3).map((d) => _debtTile(d, false)),
                      if (_dueSoonDebts.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: TextButton(
                            onPressed: () => context.push('/debts'),
                            child: Text('Ver ${_dueSoonDebts.length - 3} más...'),
                          ),
                        ),
                    ],

                    if (_overdueDebts.isEmpty && _dueSoonDebts.isEmpty)
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline, size: 48, color: AppTheme.successColor.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                const Text('No hay créditos pendientes', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNotificationBanner() {
    final totalAlerts = _overdueDebts.length + _dueSoonDebts.length;
    final hasOverdue = _overdueDebts.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/debts'),
          child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasOverdue
                  ? [AppTheme.errorColor, AppTheme.errorColor.withValues(alpha: 0.8)]
                  : [AppTheme.warningColor, AppTheme.warningColor.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (hasOverdue ? AppTheme.errorColor : AppTheme.warningColor).withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasOverdue ? Icons.notifications_active : Icons.notifications,
                  color: Colors.white, size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalAlerts alerta(s) de crédito',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      hasOverdue
                          ? '${_overdueDebts.length} vencido(s) · ${_dueSoonDebts.length} por vencer'
                          : '${_dueSoonDebts.length} crédito(s) por vencer',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildCreditSummary() {
    final pendingAmount = (_stats!['pendingDebts'] as num).toDouble();
    final pendingCount = (_stats!['pendingDebtsCount'] as num).toInt();
    final totalOverdue = _overdueDebts.fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.credit_card, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Resumen de Créditos',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pendiente Total', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(pendingAmount),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: pendingCount > 0 ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingCount créditos',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (totalOverdue > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${_overdueDebts.length} vencido(s) — ${Formatters.formatCurrency(totalOverdue)}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: [
        _statTile('Ventas Hoy', Formatters.formatCurrency((_stats!['todaySales'] as num).toDouble()),
            Icons.today, AppTheme.primaryColor, () => context.push('/pos')),
        _statTile('Stock Bajo', '${_stats!['lowStockCount']}',
            Icons.inventory, AppTheme.warningColor, () => context.push('/inventory')),
        _statTile('Pedidos', 'Proveedores',
            Icons.inbox_outlined, AppTheme.successColor, () => context.push('/purchase-orders')),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  /// Groups debts by their due date (date-only key) for the calendar.
  Map<DateTime, List<Debt>> _buildEventsMap(List<Debt> debts) {
    final map = <DateTime, List<Debt>>{};
    for (final d in debts) {
      final dateKey = DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day);
      map.putIfAbsent(dateKey, () => []).add(d);
    }
    return map;
  }

  Widget _buildCalendarSection() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Calendar header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_month, size: 18, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 8),
                const Text('Calendario de Vencimientos',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Calendar widget
          TableCalendar<Debt>(
            firstDay: DateTime.now().subtract(const Duration(days: 90)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _calendarEvents[DateTime(day.year, day.month, day.day)] ?? [],
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(Icons.chevron_left, size: 20),
              rightChevronIcon: Icon(Icons.chevron_right, size: 20),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(3),
              cellPadding: EdgeInsets.zero,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;

                // Check if any event is overdue (past due + unpaid)
                final hasOverdue = events.any((d) =>
                    d is Debt && d.status != 'paid' && d.dueDate.isBefore(DateTime.now()));
                final hasPending = events.any((d) =>
                    d is Debt && d.status != 'paid' && !d.dueDate.isBefore(DateTime.now()));

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasOverdue)
                        _dot(AppTheme.errorColor),
                      if (hasPending)
                        _dot(AppTheme.warningColor),
                    ],
                  ),
                );
              },
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppTheme.errorColor, 'Vencido'),
                const SizedBox(width: 16),
                _legendDot(AppTheme.warningColor, 'Pendiente'),
              ],
            ),
          ),

          // Debts for selected day
          _buildDayDebts(),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDayDebts() {
    final dateKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final dayDebts = _calendarEvents[dateKey];

    if (dayDebts == null || dayDebts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          'Sin créditos para ${Formatters.formatDate(_selectedDay)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      );
    }

    final totalPending = dayDebts.fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Text('${dayDebts.length} crédito(s)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const Spacer(),
              Text('Pendiente: ${Formatters.formatCurrency(totalPending)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorColor)),
            ],
          ),
        ),
        const Divider(height: 1),
        ...dayDebts.take(4).map((d) => _debtTile(d,
            d.status != 'paid' && d.dueDate.isBefore(DateTime.now()))),
        if (dayDebts.length > 4)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: TextButton(
              onPressed: () => context.push('/debts'),
              child: Text('Ver ${dayDebts.length - 4} más...'),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _debtTile(Debt debt, bool isOverdue) {
    final remaining = debt.amount - debt.paidAmount;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: (isOverdue ? AppTheme.errorColor : AppTheme.warningColor).withValues(alpha: 0.1),
          child: Icon(
            isOverdue ? Icons.error_outline : Icons.schedule,
            size: 16,
            color: isOverdue ? AppTheme.errorColor : AppTheme.warningColor,
          ),
        ),
        title: Text(debt.customerName, style: const TextStyle(fontSize: 13)),
        subtitle: Text('Vence: ${Formatters.formatDate(debt.dueDate)}', style: const TextStyle(fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Formatters.formatCurrency(remaining), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Pagado: ${Formatters.formatCurrency(debt.paidAmount)}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
        onTap: () => context.push('/debts/${debt.id}'),
      ),
    );
  }
}
