import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double totalSpent;
  final int purchaseCount;
  final DateTime? lastPurchase;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.totalSpent = 0,
    this.purchaseCount = 0,
    this.lastPurchase,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalSpent,
    int? purchaseCount,
    DateTime? lastPurchase,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalSpent: totalSpent ?? this.totalSpent,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      lastPurchase: lastPurchase ?? this.lastPurchase,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalSpent': totalSpent,
      'purchaseCount': purchaseCount,
      'lastPurchase': lastPurchase?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0,
      purchaseCount: map['purchaseCount'] as int? ?? 0,
      lastPurchase: map['lastPurchase'] != null
          ? DateTime.tryParse(map['lastPurchase'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        address,
        totalSpent,
        purchaseCount,
        lastPurchase,
        createdAt,
      ];
}
