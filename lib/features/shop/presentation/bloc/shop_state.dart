import 'package:equatable/equatable.dart';
import '../../domain/product_model.dart';

abstract class ShopState extends Equatable {
  const ShopState();
  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {
  const ShopInitial();
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopLoaded extends ShopState {
  final List<ProductModel> products;
  const ShopLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class ShopError extends ShopState {
  final String message;
  const ShopError(this.message);
  @override
  List<Object?> get props => [message];
}