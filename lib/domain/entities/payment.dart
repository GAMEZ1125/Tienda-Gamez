import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime date;
  final String method;
  final String? notes;

  Payment({
    this.id,
    required this.debtId,
    required this.amount,
    DateTime? date,
    this.method = 'Efectivo',
    this.notes,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      debtId: map['debtId'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      method: map['method'] as String? ?? 'Efectivo',
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, debtId, amount, date, method, notes];
}
