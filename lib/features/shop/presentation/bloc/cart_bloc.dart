import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState.empty()) {
    on<CartAddItem>((e, emit) => emit(CartState(cart: state.cart.addItem(e.product))));
    on<CartRemoveItem>((e, emit) => emit(CartState(cart: state.cart.removeItem(e.productId))));
    on<CartUpdateQuantity>((e, emit) =>
        emit(CartState(cart: state.cart.updateQuantity(e.productId, e.quantity))));
    on<CartClear>((_, emit) => emit(CartState.empty()));
  }
}