import 'package:equatable/equatable.dart';

class SupplierPayment extends Equatable {
  final int? id;
  final int supplierId;
  final String supplierName;
  final double amount;
  final DateTime date;
  final String method;
  final String? notes;
  final DateTime createdAt;

  SupplierPayment({
    this.id,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    DateTime? date,
    this.method = 'Efectivo',
    this.notes,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  SupplierPayment copyWith({
    int? id,
    int? supplierId,
    String? supplierName,
    double? amount,
    DateTime? date,
    String? method,
    String? notes,
    DateTime? createdAt,
  }) {
    return SupplierPayment(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SupplierPayment.fromMap(Map<String, dynamic> map) {
    return SupplierPayment(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int,
      supplierName: map['supplierName'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      method: map['method'] as String? ?? 'Efectivo',
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
        amount,
        date,
        method,
        notes,
        createdAt,
      ];
}
