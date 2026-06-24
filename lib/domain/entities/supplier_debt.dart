import 'package:equatable/equatable.dart';
import 'supplier_debt_payment.dart';

class SupplierDebt extends Equatable {
  final int? id;
  final int supplierId;
  final String supplierName;
  final int? purchaseOrderId;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // pending, partial, paid
  final String? notes;
  final List<SupplierDebtPayment>? payments;
  final DateTime createdAt;

  SupplierDebt({
    this.id,
    required this.supplierId,
    required this.supplierName,
    this.purchaseOrderId,
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

  SupplierDebt copyWith({
    int? id,
    int? supplierId,
    String? supplierName,
    int? purchaseOrderId,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    DateTime? paidDate,
    String? status,
    String? notes,
    List<SupplierDebtPayment>? payments,
    DateTime? createdAt,
  }) {
    return SupplierDebt(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
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
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseOrderId': purchaseOrderId,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SupplierDebt.fromMap(Map<String, dynamic> map) {
    return SupplierDebt(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int,
      supplierName: map['supplierName'] as String,
      purchaseOrderId: map['purchaseOrderId'] as int?,
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
        supplierId,
        supplierName,
        purchaseOrderId,
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
