import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/supplier_payment.dart';

class SupplierPaymentsScreen extends StatefulWidget {
  const SupplierPaymentsScreen({super.key});

  @override
  State<SupplierPaymentsScreen> createState() => _SupplierPaymentsScreenState();
}

class _SupplierPaymentsScreenState extends State<SupplierPaymentsScreen> {
  List<SupplierPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final payments = await DatabaseHelper.getAllSupplierPayments();
    setState(() {
      _payments = payments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPayments = _payments.fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos a Proveedores')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_payments.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    child: Column(
                      children: [
                        Text('Total Pagado', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text(Formatters.formatCurrency(totalPayments), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ],
                    ),
                  ),
                Expanded(
                  child: _payments.isEmpty
                      ? const EmptyState(icon: Icons.payments_outlined, title: 'Sin pagos registrados')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _payments.length,
                            itemBuilder: (ctx, i) {
                              final p = _payments[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                                    child: const Icon(Icons.check, color: AppTheme.successColor),
                                  ),
                                  title: Text(p.supplierName),
                                  subtitle: Text('${Formatters.formatDate(p.date)} - ${p.method}'),
                                  trailing: Text(
                                    Formatters.formatCurrency(p.amount),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPayment(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Pago'),
      ),
    );
  }

  Future<void> _showAddPayment() async {
    final suppliers = await DatabaseHelper.getAllSuppliers();
    if (!mounted) return;

    final supplier = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Proveedor'),
        content: SizedBox(
          width: double.maxFinite,
          child: suppliers.isEmpty
              ? const Text('No hay proveedores')
              : ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (ctx, i) {
                    final s = suppliers[i];
                    return ListTile(
                      title: Text(s.name),
                      subtitle: Text(s.phone ?? ''),
                      onTap: () => Navigator.pop(ctx, s),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))],
      ),
    );

    if (supplier == null || !mounted) return;

    final amtCtrl = TextEditingController();
    final methodCtrl = TextEditingController(text: 'Efectivo');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto', prefixText: r'$ '),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: 'Efectivo',
              decoration: const InputDecoration(labelText: 'Método de pago'),
              items: ['Efectivo', 'Transferencia', 'Tarjeta', 'Yape/Plin'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => methodCtrl.text = v ?? 'Efectivo',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final amt = double.tryParse(amtCtrl.text);
            if (amt == null || amt <= 0) return;
            Navigator.pop(ctx, {'amount': amt, 'method': methodCtrl.text});
          }, child: const Text('Guardar')),
        ],
      ),
    );

    if (result != null && mounted) {
      await DatabaseHelper.insertSupplierPayment(SupplierPayment(
        supplierId: supplier.id!,
        supplierName: supplier.name,
        amount: result['amount'] as double,
        method: result['method'] as String,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Pago registrado'),
          backgroundColor: AppTheme.successColor,
        ));
        _load();
      }
    }
  }
}
