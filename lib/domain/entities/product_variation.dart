import 'package:equatable/equatable.dart';

class ProductVariation extends Equatable {
  final int? id;
  final int productId;
  final String name;
  final String? barcode;
  final double price;
  final double cost;
  final int stock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductVariation({
    this.id,
    required this.productId,
    required this.name,
    this.barcode,
    required this.price,
    required this.cost,
    this.stock = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOutOfStock => stock <= 0;

  ProductVariation copyWith({
    int? id,
    int? productId,
    String? name,
    String? barcode,
    double? price,
    double? cost,
    int? stock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'name': name,
      'barcode': barcode,
      'price': price,
      'cost': cost,
      'stock': stock,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductVariation.fromMap(Map<String, dynamic> map) {
    return ProductVariation(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] as int? ?? 0,
      isActive: (map['isActive'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        name,
        barcode,
        price,
        cost,
        stock,
        isActive,
        createdAt,
        updatedAt,
      ];
}
