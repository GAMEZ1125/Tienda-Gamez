import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final double cost;
  final int stock;
  final int minStock;
  final String? category;
  final String? barcode;
  final String? imagePath;
  final bool isActive;
  final double taxRate; // 0.0 = exonerado, 0.18 = 18% IGV
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    required this.cost,
    this.stock = 0,
    this.minStock = 5,
    this.category,
    this.barcode,
    this.imagePath,
    this.isActive = true,
    this.taxRate = 0.18,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get hasTax => taxRate > 0;

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    double? cost,
    int? stock,
    int? minStock,
    String? category,
    String? barcode,
    String? imagePath,
    bool? isActive,
    double? taxRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'price': price,
      'cost': cost,
      'stock': stock,
      'minStock': minStock,
      'category': category,
      'barcode': barcode,
      'imagePath': imagePath,
      'isActive': isActive ? 1 : 0,
      'taxRate': taxRate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
      minStock: map['minStock'] as int? ?? 5,
      category: map['category'] as String?,
      barcode: map['barcode'] as String?,
      imagePath: map['imagePath'] as String?,
      isActive: (map['isActive'] as int?) == 1,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock <= 0;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        cost,
        stock,
        minStock,
        category,
        barcode,
        imagePath,
        isActive,
        taxRate,
        createdAt,
        updatedAt,
      ];
}
