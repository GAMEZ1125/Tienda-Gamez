import 'package:equatable/equatable.dart';

class SupplierDebtPayment extends Equatable {
  final int? id;
  final int supplierDebtId;
  final double amount;
  final DateTime date;
  final String method;
  final String? notes;

  SupplierDebtPayment({
    this.id,
    required this.supplierDebtId,
    required this.amount,
    DateTime? date,
    this.method = 'Efectivo',
    this.notes,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplierDebtId': supplierDebtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
      'notes': notes,
    };
  }

  factory SupplierDebtPayment.fromMap(Map<String, dynamic> map) {
    return SupplierDebtPayment(
      id: map['id'] as int?,
      supplierDebtId: map['supplierDebtId'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      method: map['method'] as String? ?? 'Efectivo',
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, supplierDebtId, amount, date, method, notes];
}
