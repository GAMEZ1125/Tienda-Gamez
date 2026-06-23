import 'package:equatable/equatable.dart';
import 'purchase_order_item.dart';

class PurchaseOrder extends Equatable {
  final int? id;
  final int supplierId;
  final String supplierName;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double total;
  final String status; // pending, received, cancelled
  final String? notes;
  final List<PurchaseOrderItem> items;
  final DateTime createdAt;

  PurchaseOrder({
    this.id,
    required this.supplierId,
    required this.supplierName,
    DateTime? date,
    this.subtotal = 0,
    this.tax = 0,
    this.total = 0,
    this.status = 'pending',
    this.notes,
    this.items = const [],
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isReceived => status == 'received';

  PurchaseOrder copyWith({
    int? id,
    int? supplierId,
    String? supplierName,
    DateTime? date,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
    String? notes,
    List<PurchaseOrderItem>? items,
    DateTime? createdAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int,
      supplierName: map['supplierName'] as String,
      date: DateTime.parse(map['date'] as String),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
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
        date,
        subtotal,
        tax,
        total,
        status,
        notes,
        items,
        createdAt,
      ];
}
