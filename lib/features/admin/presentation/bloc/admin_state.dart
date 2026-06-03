import 'package:equatable/equatable.dart';
import '../../../shop/domain/order_model.dart';
import '../../../shop/domain/product_model.dart';

class AdminState extends Equatable {
  final List<OrderModel> orders;
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AdminState({
    this.orders = const [],
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AdminState copyWith({
    List<OrderModel>? orders,
    List<ProductModel>? products,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) =>
      AdminState(
        orders: orders ?? this.orders,
        products: products ?? this.products,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        successMessage: successMessage,
      );

  @override
  List<Object?> get props => [orders, products, isLoading, error, successMessage];
}
