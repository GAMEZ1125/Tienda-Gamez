import 'package:equatable/equatable.dart';
import 'sale_item.dart';

class Sale extends Equatable {
  final int? id;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod;
  final int? customerId;
  final String? customerName;
  final String? notes;
  final List<SaleItem> items;
  final String status;

  Sale({
    this.id,
    DateTime? date,
    this.subtotal = 0,
    this.tax = 0,
    this.discount = 0,
    this.total = 0,
    this.paymentMethod = 'Efectivo',
    this.customerId,
    this.customerName,
    this.notes,
    this.items = const [],
    this.status = 'completed',
  }) : date = date ?? DateTime.now();

  Sale copyWith({
    int? id,
    DateTime? date,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? paymentMethod,
    int? customerId,
    String? customerName,
    String? notes,
    List<SaleItem>? items,
    String? status,
  }) {
    return Sale(
      id: id ?? this.id,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'customerId': customerId,
      'customerName': customerName,
      'notes': notes,
      'status': status,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? 'Efectivo',
      customerId: map['customerId'] as int?,
      customerName: map['customerName'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'completed',
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        subtotal,
        tax,
        discount,
        total,
        paymentMethod,
        customerId,
        customerName,
        notes,
        items,
        status,
      ];
}
