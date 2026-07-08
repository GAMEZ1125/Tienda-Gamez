import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/database/database_helper.dart';
import '../../../services/pdf_export_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _dailySales = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topProductsWithProfit = [];
  List<Map<String, dynamic>> _profitByCategory = [];
  double _totalProfit = 0;
  double _totalCogs = 0;
  bool _isLoading = true;
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final weekAgo = now.subtract(const Duration(days: 7));

    final stats = await DatabaseHelper.getDashboardStats();
    final dailySales = await DatabaseHelper.getDailySales(weekAgo, now);
    final topProducts = await DatabaseHelper.getTopProducts(monthStart, now);
    final topWithProfit = await DatabaseHelper.getTopProductsWithProfit(monthStart, now);
    final totalProfit = await DatabaseHelper.getTotalProfit(monthStart, now);
    final totalCogs = await DatabaseHelper.getTotalCogs(monthStart, now);
    final profitByCategory = await DatabaseHelper.getProfitByCategory(monthStart, now);

    setState(() {
      _stats = stats;
      _dailySales = dailySales;
      _topProducts = topProducts;
      _topProductsWithProfit = topWithProfit;
      _totalProfit = totalProfit;
      _totalCogs = totalCogs;
      _profitByCategory = profitByCategory;
      _isLoading = false;
    });
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    try {
      await PdfExportService.exportStatsPdf(context);
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: _isExportingPdf
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Exportar PDF',
            onPressed: _isExportingPdf ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Cargando estadísticas...')
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    _buildSummaryGrid(),
                    const SizedBox(height: 24),

                    // Daily sales chart
                    Text(
                      'Ventas de los Últimos 7 Días',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: _dailySales.isEmpty
                          ? const Center(child: Text('Sin datos de ventas'))
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (_dailySales.map((d) => (d['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${_dailySales[groupIndex]['day']}\n${Formatters.formatCurrency(rod.toY)}',
                                        const TextStyle(color: Colors.white, fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < _dailySales.length) {
                                          final day = _dailySales[index]['day'] as String;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              day.substring(day.length - 2),
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) => Text(
                                        '\$${value.toInt()}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _dailySales.asMap().entries.map((entry) {
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: (entry.value['total'] as num).toDouble(),
                                        color: AppTheme.primaryColor,
                                        width: 18,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Profit summary
                    if (_totalProfit > 0)
                      Card(
                        margin: EdgeInsets.zero,
                        color: AppTheme.successColor.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Utilidad Bruta del Mes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text(Formatters.formatCurrency(_totalProfit), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Costo de Ventas (COGS)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text(Formatters.formatCurrency(_totalCogs), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.warningColor)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Profit by category
                    Text(
                      'Utilidad por Categoría',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_profitByCategory.isEmpty)
                      const Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('Sin ventas este mes')),
                        ),
                      )
                    else
                      ..._profitByCategory.map((cat) {
                        final profit = (cat['totalProfit'] as num).toDouble();
                        final revenue = (cat['totalRevenue'] as num).toDouble();
                        final margin = revenue > 0 ? (profit / revenue * 100) : 0.0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: profit >= 0 ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.errorColor.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.category_rounded,
                                color: profit >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                                size: 20,
                              ),
                            ),
                            title: Text(cat['category'] as String),
                            subtitle: Text('${cat['totalQuantity']} vendidos | Ingresos: ${Formatters.formatCurrency(revenue)}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(Formatters.formatCurrency(profit),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: profit >= 0 ? AppTheme.successColor : AppTheme.errorColor)),
                                Text('${margin.toStringAsFixed(1)}% margen',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),

                    // Top products with profit
                    Text(
                      'Utilidad por Producto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_topProductsWithProfit.isEmpty)
                      const Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('Sin ventas este mes')),
                        ),
                      )
                    else
                      ..._topProductsWithProfit.asMap().entries.map((entry) {
                        final p = entry.value;
                        final profit = (p['totalProfit'] as num).toDouble();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: profit >= 0 ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.errorColor.withValues(alpha: 0.1),
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: profit >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                                ),
                              ),
                            ),
                            title: Text(p['productName'] as String),
                            subtitle: Text('${p['totalQuantity']} unds. vendidas | Costo: ${Formatters.formatCurrency((p['totalCost'] as num).toDouble())}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(Formatters.formatCurrency((p['totalAmount'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  Formatters.formatCurrency(profit),
                                  style: TextStyle(fontSize: 12, color: profit >= 0 ? AppTheme.successColor : AppTheme.errorColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),

                    // Top products sold
                    Text(
                      'Productos Más Vendidos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_topProducts.isEmpty)
                      const Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('Sin ventas este mes')),
                        ),
                      )
                    else
                      ..._topProducts.asMap().entries.map((entry) {
                        final product = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            title: Text(product['productName'] as String),
                            subtitle: Text('${product['totalQuantity']} unidades vendidas'),
                            trailing: Text(
                              Formatters.formatCurrency((product['totalAmount'] as num).toDouble()),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryGrid() {
    if (_stats == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _summaryCard(
          'Ventas Hoy',
          Formatters.formatCurrency((_stats!['todaySales'] as num).toDouble()),
          Icons.today,
          AppTheme.primaryColor,
        ),
        _summaryCard(
          'Ventas del Mes',
          Formatters.formatCurrency((_stats!['monthSales'] as num).toDouble()),
          Icons.shopping_cart,
          AppTheme.successColor,
        ),
        _summaryCard(
          'Gastos del Mes',
          Formatters.formatCurrency((_stats!['monthExpenses'] as num).toDouble()),
          Icons.money_off,
          AppTheme.errorColor,
        ),
        _summaryCard(
          'Ganancia Neta',
          Formatters.formatCurrency((_stats!['netProfit'] as num).toDouble()),
          Icons.trending_up,
          ( _stats!['netProfit'] as num) >= 0 ? AppTheme.successColor : AppTheme.errorColor,
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
