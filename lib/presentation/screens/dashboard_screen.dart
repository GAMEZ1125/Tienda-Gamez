import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/database_helper.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/supplier_debt.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Debt> _overdueDebts = [];
  List<Debt> _dueSoonDebts = [];
  List<SupplierDebt> _overdueSupplierDebts = [];
  List<SupplierDebt> _dueSoonSupplierDebts = [];
  double _totalPendingSupplierDebts = 0;
  int _pendingSupplierDebtsCount = 0;
  bool _isLoading = true;
  bool _notificationsShown = false;

  // Calendar state
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<dynamic>> _calendarEvents = {};

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
    final supplierOverdue = await DatabaseHelper.getOverdueSupplierDebts();
    final supplierDueSoon = await DatabaseHelper.getSupplierDebtsDueSoon(3);
    final allSupplierDebts = await DatabaseHelper.getAllSupplierDebtsForCalendar();
    final totalPendingSupplier = await DatabaseHelper.getTotalPendingSupplierDebts();
    final pendingSupplierCount = await DatabaseHelper.getPendingSupplierDebtsCount();
    setState(() {
      _stats = stats;
      _overdueDebts = overdue;
      _dueSoonDebts = dueSoon;
      _overdueSupplierDebts = supplierOverdue;
      _dueSoonSupplierDebts = supplierDueSoon;
      _totalPendingSupplierDebts = totalPendingSupplier;
      _pendingSupplierDebtsCount = pendingSupplierCount;
      _calendarEvents = _buildEventsMap(allDebts, allSupplierDebts);
      _isLoading = false;
    });

    if (!_notificationsShown && mounted) {
      _notificationsShown = true;
      final hasOverdue = overdue.isNotEmpty || supplierOverdue.isNotEmpty;
      final hasDueSoon = dueSoon.isNotEmpty || supplierDueSoon.isNotEmpty;
      if (hasOverdue || hasDueSoon) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNotificationDialog(overdue, dueSoon, supplierOverdue, supplierDueSoon);
        });
      }
    }
  }

  void _showNotificationDialog(List<Debt> overdue, List<Debt> dueSoon, List<SupplierDebt> supplierOverdue, List<SupplierDebt> supplierDueSoon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (overdue.isNotEmpty || supplierOverdue.isNotEmpty ? AppTheme.errorColor : AppTheme.warningColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                overdue.isNotEmpty || supplierOverdue.isNotEmpty ? Icons.notifications_active : Icons.notifications,
                color: overdue.isNotEmpty || supplierOverdue.isNotEmpty ? AppTheme.errorColor : AppTheme.warningColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Alertas de Créditos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (overdue.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${overdue.length} crédito(s) vencido(s) de clientes',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.errorColor, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...overdue.take(3).map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
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
            if (supplierOverdue.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${supplierOverdue.length} deuda(s) vencida(s) a proveedores',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.errorColor, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...supplierOverdue.take(3).map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(d.supplierName, style: const TextStyle(fontSize: 13))),
                    Text(Formatters.formatCurrency(d.amount - d.paidAmount),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorColor)),
                  ],
                ),
              )),
              if (supplierOverdue.length > 3)
                Text('Y ${supplierOverdue.length - 3} más...', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 12),
            ],
            if (dueSoon.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${dueSoon.length} crédito(s) por vencer',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.warningColor, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (supplierDueSoon.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${supplierDueSoon.length} deuda(s) a proveedores por vencer',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.warningColor, fontSize: 14),
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
            child: const Text('Ver Créditos'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Estadísticas',
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => context.push('/configuracion'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.brandRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification banner
                    if (_overdueDebts.isNotEmpty || _dueSoonDebts.isNotEmpty || _overdueSupplierDebts.isNotEmpty || _dueSoonSupplierDebts.isNotEmpty)
                      _buildNotificationBanner(),
                    if (_overdueDebts.isNotEmpty || _dueSoonDebts.isNotEmpty || _overdueSupplierDebts.isNotEmpty || _dueSoonSupplierDebts.isNotEmpty)
                      const SizedBox(height: 12),

                    // Quick stats
                    _buildQuickStats(isDark),
                    const SizedBox(height: 16),

                    // Credit summary (customers + suppliers)
                    _buildCreditSummary(isDark),
                    const SizedBox(height: 16),

                    // Calendar
                    _buildCalendarSection(isDark),
                    const SizedBox(height: 16),

                    // Overdue customer debts
                    if (_overdueDebts.isNotEmpty) ...[
                      _buildSectionTitle('Créditos Vencidos (Clientes)', Icons.warning_amber_rounded, AppTheme.errorColor),
                      const SizedBox(height: 8),
                      ..._overdueDebts.take(3).map((d) => _debtTile(d, true, isDark)),
                      if (_overdueDebts.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () => context.push('/debts'),
                            child: const Text('Ver más vencidos...'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Overdue supplier debts
                    if (_overdueSupplierDebts.isNotEmpty) ...[
                      _buildSectionTitle('Deudas Vencidas (Proveedores)', Icons.business, AppTheme.errorColor),
                      const SizedBox(height: 8),
                      ..._overdueSupplierDebts.take(3).map((d) => _supplierDebtTile(d, true, isDark)),
                      if (_overdueSupplierDebts.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () => context.push('/suppliers'),
                            child: const Text('Ver más vencidas...'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Due soon customer debts
                    if (_dueSoonDebts.isNotEmpty) ...[
                      _buildSectionTitle('Próximos a Vencer (Clientes)', Icons.schedule_rounded, AppTheme.warningColor),
                      const SizedBox(height: 8),
                      ..._dueSoonDebts.take(3).map((d) => _debtTile(d, false, isDark)),
                      if (_dueSoonDebts.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () => context.push('/debts'),
                            child: const Text('Ver más por vencer...'),
                          ),
                        ),
                    ],

                    // Due soon supplier debts
                    if (_dueSoonSupplierDebts.isNotEmpty) ...[
                      _buildSectionTitle('Prox. a Vencer (Proveedores)', Icons.business, AppTheme.warningColor),
                      const SizedBox(height: 8),
                      ..._dueSoonSupplierDebts.take(3).map((d) => _supplierDebtTile(d, false, isDark)),
                      if (_dueSoonSupplierDebts.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () => context.push('/suppliers'),
                            child: const Text('Ver más por vencer...'),
                          ),
                        ),
                    ],

                    if (_overdueDebts.isEmpty && _dueSoonDebts.isEmpty && _overdueSupplierDebts.isEmpty && _dueSoonSupplierDebts.isEmpty)
                      _buildAllClearCard(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNotificationBanner() {
    final totalAlerts = _overdueDebts.length + _dueSoonDebts.length + _overdueSupplierDebts.length + _dueSoonSupplierDebts.length;
    final hasOverdue = _overdueDebts.isNotEmpty || _overdueSupplierDebts.isNotEmpty;
    final bannerColor = hasOverdue ? AppTheme.errorColor : AppTheme.warningColor;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerColor,
            bannerColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/debts'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasOverdue ? Icons.notifications_active_rounded : Icons.notifications_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalAlerts alerta(s) de crédito',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_overdueDebts.length + _overdueSupplierDebts.length} vencido(s) · ${_dueSoonDebts.length + _dueSoonSupplierDebts.length} por vencer',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    final todaySales = (_stats!['todaySales'] as num).toDouble();
    final lowStockCount = (_stats!['lowStockCount'] as num).toInt();
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Ventas Hoy',
            value: Formatters.formatCurrency(todaySales),
            icon: Icons.trending_up_rounded,
            color: AppTheme.accentEmerald,
            isDark: isDark,
            onTap: () => context.push('/pos'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Stock Bajo',
            value: '$lowStockCount',
            icon: Icons.inventory_2_rounded,
            color: AppTheme.accentAmber,
            isDark: isDark,
            onTap: () => context.push('/inventory'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Pedidos',
            value: 'Ver',
            icon: Icons.receipt_long_rounded,
            color: AppTheme.accentBlue,
            isDark: isDark,
            onTap: () => context.push('/purchase-orders'),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditSummary(bool isDark) {
    final pendingAmount = (_stats!['pendingDebts'] as num).toDouble();
    final pendingCount = (_stats!['pendingDebtsCount'] as num).toInt();
    final totalOverdue = _overdueDebts.fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));
    final totalPendingAll = pendingAmount + _totalPendingSupplierDebts;
    final totalCountAll = pendingCount + _pendingSupplierDebtsCount;
    final totalOverdueAll = totalOverdue + _overdueSupplierDebts.fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brandRed, Color(0xFFC41230)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandRed.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Resumen de Créditos',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
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
                      Text(
                        'Pendiente Total (Clientes + Proveedores)',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(totalPendingAll),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCountAll créditos',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _creditBadge('Clientes', Formatters.formatCurrency(pendingAmount), '$pendingCount', AppTheme.accentEmerald),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _creditBadge('Proveedores', Formatters.formatCurrency(_totalPendingSupplierDebts), '$_pendingSupplierDebtsCount', AppTheme.accentBlue),
                ),
              ],
            ),
            if (totalOverdueAll > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_overdueDebts.length + _overdueSupplierDebts.length} vencido(s) — ${Formatters.formatCurrency(totalOverdueAll)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
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

  Widget _creditBadge(String label, String amount, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('$count crédito(s)', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.brandRed),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Calendario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          TableCalendar<dynamic>(
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
              titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, size: 22),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, size: 22),
              headerPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.brandRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.brandRed),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.brandRed,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
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
                final debts = events.whereType<Debt>();
                final supplierDebts = events.whereType<SupplierDebt>();
                final hasOverdue = debts.any((d) => d.status != 'paid' && d.dueDate.isBefore(DateTime.now())) ||
                    supplierDebts.any((d) => d.status != 'paid' && d.dueDate.isBefore(DateTime.now()));
                final hasPending = debts.any((d) => d.status != 'paid' && !d.dueDate.isBefore(DateTime.now())) ||
                    supplierDebts.any((d) => d.status != 'paid' && !d.dueDate.isBefore(DateTime.now()));

                return Positioned(
                  bottom: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasOverdue)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                        ),
                      if (hasPending)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(color: AppTheme.warningColor, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppTheme.errorColor, label: 'Vencido'),
                const SizedBox(width: 16),
                _LegendDot(color: AppTheme.warningColor, label: 'Pendiente'),
              ],
            ),
          ),
          _buildDayDebts(isDark),
        ],
      ),
    );
  }

  Widget _buildDayDebts(bool isDark) {
    final dateKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final dayItems = _calendarEvents[dateKey];

    if (dayItems == null || dayItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Text(
          'Sin créditos para ${Formatters.formatDate(_selectedDay)}',
          style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
        ),
      );
    }

    final dayDebts = dayItems.whereType<Debt>().toList();
    final daySupplierDebts = dayItems.whereType<SupplierDebt>().toList();
    final totalPending = dayDebts.fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount)) +
        daySupplierDebts.fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            children: [
              Text(
                '${dayItems.length} crédito(s)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
              const Spacer(),
              Text(
                'Pendiente: ${Formatters.formatCurrency(totalPending)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorColor),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...dayItems.take(4).map((item) {
          if (item is Debt) {
            return _debtTile(item, item.status != 'paid' && item.dueDate.isBefore(DateTime.now()), isDark);
          } else if (item is SupplierDebt) {
            return _supplierDebtTile(item, item.status != 'paid' && item.dueDate.isBefore(DateTime.now()), isDark);
          }
          return const SizedBox.shrink();
        }),
        if (dayItems.length > 4)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: TextButton(
              onPressed: () => context.push('/debts'),
              child: Text('Ver ${dayItems.length - 4} más...'),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _debtTile(Debt debt, bool isOverdue, bool isDark) {
    final remaining = debt.amount - debt.paidAmount;
    final statusColor = isOverdue ? AppTheme.errorColor : AppTheme.warningColor;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/debts/${debt.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOverdue ? Icons.error_outline_rounded : Icons.schedule_rounded,
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.customerName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vence: ${Formatters.formatDate(debt.dueDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(remaining),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOverdue ? 'VENCIDA' : 'Pendiente',
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _supplierDebtTile(SupplierDebt debt, bool isOverdue, bool isDark) {
    final remaining = debt.amount - debt.paidAmount;
    final statusColor = isOverdue ? AppTheme.errorColor : AppTheme.warningColor;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/suppliers/${debt.supplierId}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOverdue ? Icons.error_outline_rounded : Icons.schedule_rounded,
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.supplierName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Proveedor · Vence: ${Formatters.formatDate(debt.dueDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(remaining),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOverdue ? 'VENCIDA' : 'Pendiente',
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllClearCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppTheme.successColor),
          ),
          const SizedBox(height: 12),
          Text(
            'Todo al día',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No hay créditos pendientes (clientes ni proveedores)',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<dynamic>> _buildEventsMap(List<Debt> debts, List<SupplierDebt> supplierDebts) {
    final map = <DateTime, List<dynamic>>{};
    for (final d in debts) {
      final dateKey = DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day);
      map.putIfAbsent(dateKey, () => []).add(d);
    }
    for (final sd in supplierDebts) {
      final dateKey = DateTime(sd.dueDate.year, sd.dueDate.month, sd.dueDate.day);
      map.putIfAbsent(dateKey, () => []).add(sd);
    }
    return map;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
          ),
        ),
      ],
    );
  }
}
