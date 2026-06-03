import 'package:equatable/equatable.dart';
import '../../domain/cart_model.dart';

class CartState extends Equatable {
  final CartModel cart;
  const CartState({required this.cart});

  factory CartState.empty() => CartState(cart: const CartModel());

  @override
  List<Object?> get props => [cart.items.length, cart.totalPrice];
}