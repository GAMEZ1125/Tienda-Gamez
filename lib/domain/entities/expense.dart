import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final int? id;
  final String concept;
  final String category;
  final double amount;
  final DateTime date;
  final int? supplierId;
  final String? supplierName;
  final String? notes;

  Expense({
    this.id,
    required this.concept,
    required this.category,
    required this.amount,
    DateTime? date,
    this.supplierId,
    this.supplierName,
    this.notes,
  }) : date = date ?? DateTime.now();

  Expense copyWith({
    int? id,
    String? concept,
    String? category,
    double? amount,
    DateTime? date,
    int? supplierId,
    String? supplierName,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      concept: concept ?? this.concept,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'concept': concept,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      concept: map['concept'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      supplierId: map['supplierId'] as int?,
      supplierName: map['supplierName'] as String?,
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        concept,
        category,
        amount,
        date,
        supplierId,
        supplierName,
        notes,
      ];
}
