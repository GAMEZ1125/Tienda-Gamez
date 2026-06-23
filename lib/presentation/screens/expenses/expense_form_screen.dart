import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/expense.dart';

class ExpenseFormScreen extends StatefulWidget {
  final int? expenseId;

  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  int? _supplierId;
  String? _supplierName;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _isEditing = true;
      _loadExpense();
    }
  }

  Future<void> _loadExpense() async {
    final expenses = await DatabaseHelper.getAllExpenses();
    final expense = expenses.where((e) => e.id == widget.expenseId).firstOrNull;
    if (expense != null) {
      _conceptController.text = expense.concept;
      _amountController.text = expense.amount.toString();
      _notesController.text = expense.notes ?? '';
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
      _supplierId = expense.supplierId;
      _supplierName = expense.supplierName;
    }
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final expense = Expense(
      id: widget.expenseId,
      concept: _conceptController.text.trim(),
      category: _selectedCategory ?? 'Otros',
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      supplierId: _supplierId,
      supplierName: _supplierName,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      if (_isEditing) {
        await DatabaseHelper.updateExpense(expense);
      } else {
        await DatabaseHelper.insertExpense(expense);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Gasto actualizado' : 'Gasto registrado'),
            backgroundColor: AppTheme.successColor,
          ),
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
        title: Text(_isEditing ? 'Editar Gasto' : 'Nuevo Gasto'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _conceptController,
                decoration: const InputDecoration(
                  labelText: 'Concepto *',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: r'$ ',
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

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: AppConstants.expenseCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha'),
                subtitle: Text(formatDate(_selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final suppliers = await DatabaseHelper.getAllSuppliers();
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Seleccionar Proveedor'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          itemCount: suppliers.length + 1,
                          itemBuilder: (ctx, i) {
                            if (i == 0) {
                              return ListTile(
                                title: const Text('Sin proveedor'),
                                leading: const Icon(Icons.person_off),
                                onTap: () {
                                  setState(() {
                                    _supplierId = null;
                                    _supplierName = null;
                                  });
                                  Navigator.pop(ctx);
                                },
                              );
                            }
                            final supplier = suppliers[i - 1];
                            return ListTile(
                              title: Text(supplier.name),
                              subtitle: Text(supplier.phone ?? ''),
                              onTap: () {
                                setState(() {
                                  _supplierId = supplier.id;
                                  _supplierName = supplier.name;
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    prefixIcon: Icon(Icons.business),
                  ),
                  child: Text(_supplierName ?? 'Seleccionar proveedor...'),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
