import 'package:equatable/equatable.dart';
import '../../domain/product_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class CartAddItem extends CartEvent {
  final ProductModel product;
  const CartAddItem(this.product);
  @override
  List<Object?> get props => [product.id];
}

class CartRemoveItem extends CartEvent {
  final String productId;
  const CartRemoveItem(this.productId);
  @override
  List<Object?> get props => [productId];
}

class CartUpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;
  const CartUpdateQuantity(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

class CartClear extends CartEvent {
  const CartClear();
}