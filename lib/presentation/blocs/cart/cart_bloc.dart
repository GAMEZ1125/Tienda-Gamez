import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/customer.dart';

// Events
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddProductToCart extends CartEvent {
  final Product product;
  final int quantity;
  const AddProductToCart(this.product, {this.quantity = 1});
  @override
  List<Object?> get props => [product, quantity];
}

class RemoveItemFromCart extends CartEvent {
  final int productId;
  const RemoveItemFromCart(this.productId);
  @override
  List<Object?> get props => [productId];
}

class UpdateItemQuantity extends CartEvent {
  final int productId;
  final int quantity;
  const UpdateItemQuantity(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends CartEvent {}

class SetDiscount extends CartEvent {
  final double discount;
  final bool isPercentage;
  const SetDiscount(this.discount, {this.isPercentage = false});
  @override
  List<Object?> get props => [discount, isPercentage];
}

class SetCustomer extends CartEvent {
  final Customer? customer;
  const SetCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class SetPaymentMethod extends CartEvent {
  final String method;
  const SetPaymentMethod(this.method);
  @override
  List<Object?> get props => [method];
}

// State
class CartState extends Equatable {
  final List<SaleItem> items;
  final double discount;
  final bool isPercentageDiscount;
  final Customer? customer;
  final String paymentMethod;
  final double taxRate;

  const CartState({
    this.items = const [],
    this.discount = 0,
    this.isPercentageDiscount = false,
    this.customer,
    this.paymentMethod = 'Efectivo',
    this.taxRate = 0.18,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get discountAmount {
    if (isPercentageDiscount) {
      return subtotal * (discount / 100);
    }
    return discount;
  }

  double get taxableAmount =>
      items.fold(0.0, (sum, item) => item.taxRate > 0 ? sum + item.subtotal : sum);
  double get taxAmount => items.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get total => subtotal - discountAmount + taxAmount;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<SaleItem>? items,
    double? discount,
    bool? isPercentageDiscount,
    Customer? customer,
    String? paymentMethod,
    double? taxRate,
    bool clearCustomer = false,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      isPercentageDiscount: isPercentageDiscount ?? this.isPercentageDiscount,
      customer: clearCustomer ? null : customer ?? this.customer,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  @override
  List<Object?> get props => [
        items,
        discount,
        isPercentageDiscount,
        customer,
        paymentMethod,
        taxRate,
      ];
}

// BLoC
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddProductToCart>(_onAddProduct);
    on<RemoveItemFromCart>(_onRemoveItem);
    on<UpdateItemQuantity>(_onUpdateQuantity);
    on<ClearCart>((event, emit) => emit(const CartState()));
    on<SetDiscount>(_onSetDiscount);
    on<SetCustomer>((event, emit) => emit(state.copyWith(customer: event.customer)));
    on<SetPaymentMethod>((event, emit) => emit(state.copyWith(paymentMethod: event.method)));
  }

  void _onAddProduct(AddProductToCart event, Emitter<CartState> emit) {
    final items = List<SaleItem>.from(state.items);
    final index = items.indexWhere((item) => item.productId == event.product.id);

    if (index >= 0) {
      final existing = items[index];
      items[index] = existing.copyWith(
        quantity: existing.quantity + event.quantity,
        subtotal: (existing.quantity + event.quantity) * existing.price,
      );
    } else {
      items.add(SaleItem(
        productId: event.product.id!,
        productName: event.product.name,
        barcode: event.product.barcode,
        price: event.product.price,
        quantity: event.quantity,
        subtotal: event.product.price * event.quantity,
        taxRate: event.product.hasTax ? state.taxRate : 0.0,
      ));
    }

    emit(state.copyWith(items: items));
  }

  void _onRemoveItem(RemoveItemFromCart event, Emitter<CartState> emit) {
    final items = List<SaleItem>.from(state.items);
    items.removeWhere((item) => item.productId == event.productId);
    emit(state.copyWith(items: items));
  }

  void _onUpdateQuantity(UpdateItemQuantity event, Emitter<CartState> emit) {
    final items = List<SaleItem>.from(state.items);
    final index = items.indexWhere((item) => item.productId == event.productId);
    if (index >= 0) {
      if (event.quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(
          quantity: event.quantity,
          subtotal: event.quantity * items[index].price,
        );
      }
    }
    emit(state.copyWith(items: items));
  }

  void _onSetDiscount(SetDiscount event, Emitter<CartState> emit) {
    emit(state.copyWith(
      discount: event.discount,
      isPercentageDiscount: event.isPercentage,
    ));
  }
}
