import 'package:equatable/equatable.dart';
import 'payment.dart';

class Debt extends Equatable {
  final int? id;
  final int customerId;
  final String customerName;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // pending, partial, paid
  final String? notes;
  final List<Payment>? payments;
  final DateTime createdAt;

  Debt({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    this.paidAmount = 0,
    required this.dueDate,
    this.paidDate,
    this.status = 'pending',
    this.notes,
    this.payments,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => amount - paidAmount;

  Debt copyWith({
    int? id,
    int? customerId,
    String? customerName,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    DateTime? paidDate,
    String? status,
    String? notes,
    List<Payment>? payments,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      customerName: map['customerName'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.parse(map['dueDate'] as String),
      paidDate: map['paidDate'] != null
          ? DateTime.tryParse(map['paidDate'] as String)
          : null,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        amount,
        paidAmount,
        dueDate,
        paidDate,
        status,
        notes,
        payments,
        createdAt,
      ];
}
