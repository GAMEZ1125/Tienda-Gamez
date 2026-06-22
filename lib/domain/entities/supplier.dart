import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? contactPerson;
  final double totalPurchases;
  final DateTime createdAt;

  Supplier({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.contactPerson,
    this.totalPurchases = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? contactPerson,
    double? totalPurchases,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      totalPurchases: totalPurchases ?? this.totalPurchases,
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
      'contactPerson': contactPerson,
      'totalPurchases': totalPurchases,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      contactPerson: map['contactPerson'] as String?,
      totalPurchases: (map['totalPurchases'] as num?)?.toDouble() ?? 0,
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
        contactPerson,
        totalPurchases,
        createdAt,
      ];
}
