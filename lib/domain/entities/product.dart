import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final double cost;
  final double stock;
  final int minStock;
  final String? category;
  final String? barcode;
  final String? imagePath;
  final bool isActive;
  final double taxRate;
  final int unitsPerPackage;
  final bool allowNegativeStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    required this.cost,
    this.stock = 0.0,
    this.minStock = 5,
    this.category,
    this.barcode,
    this.imagePath,
    this.isActive = true,
    this.taxRate = 0.18,
    this.unitsPerPackage = 1,
    this.allowNegativeStock = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get hasTax => taxRate > 0;

  /// Returns effective stock in base units (considering unitsPerPackage).
  /// If product is "Caja x30" with stock=10, effectiveStock = 300.0 units.
  double get effectiveStock => stock * unitsPerPackage;

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    double? cost,
    double? stock,
    int? minStock,
    String? category,
    String? barcode,
    String? imagePath,
    bool? isActive,
    double? taxRate,
    int? unitsPerPackage,
    bool? allowNegativeStock,
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
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
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
      'unitsPerPackage': unitsPerPackage,
      'allowNegativeStock': allowNegativeStock ? 1 : 0,
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
      stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
      minStock: map['minStock'] as int? ?? 5,
      category: map['category'] as String?,
      barcode: map['barcode'] as String?,
      imagePath: map['imagePath'] as String?,
      isActive: (map['isActive'] as int?) == 1,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      unitsPerPackage: map['unitsPerPackage'] as int? ?? 1,
      allowNegativeStock: (map['allowNegativeStock'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock <= 0.0;

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
        unitsPerPackage,
        allowNegativeStock,
        createdAt,
        updatedAt,
      ];
}
