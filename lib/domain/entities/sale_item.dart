import 'package:equatable/equatable.dart';

class SaleItem extends Equatable {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final String? barcode;
  final double price;
  final int quantity;
  final double subtotal;
  final double taxRate;
  final int unitsPerPresentation;

  const SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    this.barcode,
    required this.price,
    required this.quantity,
    this.subtotal = 0,
    this.taxRate = 0.18,
    this.unitsPerPresentation = 1,
  });

  double get taxAmount => subtotal * taxRate;

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    String? barcode,
    double? price,
    int? quantity,
    double? subtotal,
    double? taxRate,
    int? unitsPerPresentation,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      unitsPerPresentation: unitsPerPresentation ?? this.unitsPerPresentation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'barcode': barcode,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'taxRate': taxRate,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['saleId'] as int?,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.18,
    );
  }

  @override
  List<Object?> get props => [
        id,
        saleId,
        productId,
        productName,
        barcode,
        price,
        quantity,
        subtotal,
        taxRate,
      ];
}
