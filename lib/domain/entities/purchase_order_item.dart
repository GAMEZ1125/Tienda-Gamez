import 'package:equatable/equatable.dart';

class PurchaseOrderItem extends Equatable {
  final int? id;
  final int? orderId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitCost;
  final double subtotal;

  const PurchaseOrderItem({
    this.id,
    this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    this.subtotal = 0,
  });

  PurchaseOrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    String? productName,
    int? quantity,
    double? unitCost,
    double? subtotal,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (orderId != null) 'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitCost': unitCost,
      'subtotal': subtotal,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'] as int?,
      orderId: map['orderId'] as int?,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      quantity: map['quantity'] as int,
      unitCost: (map['unitCost'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        productName,
        quantity,
        unitCost,
        subtotal,
      ];
}
