import 'package:equatable/equatable.dart';
import '../../../shop/domain/product_model.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class AdminLoadOrders extends AdminEvent {
  const AdminLoadOrders();
}

class AdminLoadProducts extends AdminEvent {
  const AdminLoadProducts();
}

class AdminConfirmPayment extends AdminEvent {
  final String orderId;
  final String adminUid;
  const AdminConfirmPayment({required this.orderId, required this.adminUid});
  @override
  List<Object?> get props => [orderId];
}

class AdminUpdateOrderStatus extends AdminEvent {
  final String orderId;
  final String status;
  const AdminUpdateOrderStatus({required this.orderId, required this.status});
  @override
  List<Object?> get props => [orderId, status];
}

class AdminSaveProduct extends AdminEvent {
  final ProductModel product;
  final bool isNew;
  const AdminSaveProduct({required this.product, required this.isNew});
  @override
  List<Object?> get props => [product.id];
}

class AdminDeleteProduct extends AdminEvent {
  final String productId;
  const AdminDeleteProduct(this.productId);
  @override
  List<Object?> get props => [productId];
}
