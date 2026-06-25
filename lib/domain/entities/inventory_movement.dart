import 'package:equatable/equatable.dart';

class InventoryMovement extends Equatable {
  final int? id;
  final int productId;
  final String productName;
  final int? productVariationId;
  final String? variationName;
  final String type; // sale, purchase_order_receive, manual_adjustment, adjustment
  final double quantityDelta;
  final double previousStock;
  final double newStock;
  final String? description;
  final DateTime createdAt;

  InventoryMovement({
    this.id,
    required this.productId,
    required this.productName,
    this.productVariationId,
    this.variationName,
    required this.type,
    required this.quantityDelta,
    required this.previousStock,
    required this.newStock,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  InventoryMovement copyWith({
    int? id,
    int? productId,
    String? productName,
    int? productVariationId,
    String? variationName,
    String? type,
    double? quantityDelta,
    double? previousStock,
    double? newStock,
    String? description,
    DateTime? createdAt,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productVariationId: productVariationId ?? this.productVariationId,
      variationName: variationName ?? this.variationName,
      type: type ?? this.type,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'productName': productName,
      'productVariationId': productVariationId,
      'variationName': variationName,
      'type': type,
      'quantityDelta': quantityDelta,
      'previousStock': previousStock,
      'newStock': newStock,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      productVariationId: map['productVariationId'] as int?,
      variationName: map['variationName'] as String?,
      type: map['type'] as String,
      quantityDelta: (map['quantityDelta'] as num).toDouble(),
      previousStock: (map['previousStock'] as num).toDouble(),
      newStock: (map['newStock'] as num).toDouble(),
      description: map['description'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'sale':
        return 'Venta';
      case 'purchase_order_receive':
        return 'Recepción de Pedido';
      case 'manual_adjustment':
        return 'Ajuste Manual';
      case 'adjustment':
        return 'Ajuste';
      default:
        return type;
    }
  }

  bool get isPositive => quantityDelta > 0;

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productVariationId,
        variationName,
        type,
        quantityDelta,
        previousStock,
        newStock,
        description,
        createdAt,
      ];
}
