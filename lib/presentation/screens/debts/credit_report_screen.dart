import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/debt.dart';
import '../../../services/pdf_export_service.dart';

class CreditReportScreen extends StatefulWidget {
  const CreditReportScreen({super.key});

  @override
  State<CreditReportScreen> createState() => _CreditReportScreenState();
}

class _CreditReportScreenState extends State<CreditReportScreen> {
  List<_CustomerCreditSummary> _summaries = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  List<_CustomerCreditSummary> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final customers = await DatabaseHelper.getAllCustomers();
    final allDebts = await DatabaseHelper.getAllDebts();

    final summaries = <_CustomerCreditSummary>[];
    for (final customer in customers) {
      final customerDebts = allDebts.where((d) => d.customerId == customer.id).toList();
      if (customerDebts.isNotEmpty) {
        summaries.add(_CustomerCreditSummary(
          customer: customer,
          debts: customerDebts,
        ));
      }
    }

    // Also include customers who may not have debts registered but have credit-related data
    setState(() {
      _summaries = summaries;
      _filtered = summaries;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _summaries;
      } else {
        final q = query.toLowerCase();
        _filtered = _summaries.where((s) =>
          s.customer.name.toLowerCase().contains(q) ||
          (s.customer.phone?.contains(q) ?? false)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Créditos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => PdfExportService.exportCreditReport(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () { _searchCtrl.clear(); _search(''); },
                            )
                          : null,
                    ),
                    onChanged: _search,
                  ),
                ),
                const SizedBox(height: 8),

                // Summary stats
                if (_summaries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _miniStat('Clientes', '${_summaries.length}', AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        _miniStat('Total Créditos', Formatters.formatCurrency(
                          _summaries.fold(0.0, (s, c) => s + c.totalAmount)), AppTheme.warningColor),
                        const SizedBox(width: 8),
                        _miniStat('Pendiente', Formatters.formatCurrency(
                          _summaries.fold(0.0, (s, c) => s + c.pendingAmount)), AppTheme.errorColor),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),

                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('Sin resultados', style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final summary = _filtered[i];
                              final hasOverdue = summary.debts.any(
                                (d) => d.status != 'paid' && d.dueDate.isBefore(DateTime.now()));
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: InkWell(
                                  onTap: () => context.push('/customers/${summary.customer.id}'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: hasOverdue
                                              ? AppTheme.errorColor.withValues(alpha: 0.1)
                                              : AppTheme.primaryColor.withValues(alpha: 0.1),
                                          child: Text(
                                            summary.customer.name[0].toUpperCase(),
                                            style: TextStyle(
                                              color: hasOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(summary.customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text('${summary.debts.length} crédito(s) · ${summary.activeCount} pendiente(s)',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                              if (hasOverdue)
                                                Row(
                                                  children: [
                                                    const Icon(Icons.warning_amber, size: 12, color: AppTheme.errorColor),
                                                    const SizedBox(width: 4),
                                                    Text('Vencido', style: TextStyle(fontSize: 11, color: AppTheme.errorColor, fontWeight: FontWeight.w500)),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(Formatters.formatCurrency(summary.totalAmount),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text(Formatters.formatCurrency(summary.pendingAmount),
                                                style: TextStyle(fontSize: 12, color: AppTheme.errorColor)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CustomerCreditSummary {
  final Customer customer;
  final List<Debt> debts;

  _CustomerCreditSummary({required this.customer, required this.debts});

  double get totalAmount => debts.fold(0.0, (s, d) => s + d.amount);
  double get paidAmount => debts.fold(0.0, (s, d) => s + d.paidAmount);
  double get pendingAmount => totalAmount - paidAmount;
  int get activeCount => debts.where((d) => d.status != 'paid').length;
}
