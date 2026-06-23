import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/debt.dart';
import '../../../services/notification_service.dart';

class DebtFormScreen extends StatefulWidget {
  const DebtFormScreen({super.key});

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _customerId;
  String? _customerName;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un cliente'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final debt = Debt(
      customerId: _customerId!,
      customerName: _customerName!,
      amount: double.parse(_amountController.text),
      dueDate: _dueDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      final debtId = await DatabaseHelper.insertDebt(debt);

      // Show local notification for the new debt
      if (debt.dueDate.isBefore(DateTime.now().add(const Duration(days: 3)))) {
        NotificationService().showDebtNotification(
          debt.copyWith(id: debtId),
          isOverdue: debt.dueDate.isBefore(DateTime.now()),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deuda registrada'), backgroundColor: AppTheme.successColor),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Deuda'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Customer selector
              InkWell(
                onTap: _selectCustomer,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Cliente *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  child: Text(
                    _customerName ?? 'Seleccionar cliente...',
                    style: TextStyle(
                      color: _customerName != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'S/ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de Vencimiento'),
                subtitle: Text(Formatters.formatDate(_dueDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCustomer() async {
    final customers = await DatabaseHelper.getAllCustomers();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Cliente'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (ctx, i) {
              final c = customers[i];
              return ListTile(
                title: Text(c.name),
                subtitle: Text(c.phone ?? ''),
                leading: CircleAvatar(child: Text(c.name[0])),
                onTap: () {
                  setState(() {
                    _customerId = c.id;
                    _customerName = c.name;
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
