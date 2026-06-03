import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shop/domain/order_model.dart';
import '../../shop/domain/product_model.dart';

class AdminRepository {
  final _orders = FirebaseFirestore.instance.collection('orders');
  final _products = FirebaseFirestore.instance.collection('products');

  Stream<List<OrderModel>> watchAllOrders() {
    return _orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(OrderModel.fromFirestore).toList());
  }

  Stream<List<ProductModel>> watchAllProducts() {
    return _products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ProductModel.fromFirestore).toList());
  }

  Future<void> confirmPayment(String orderId, String adminUid) async {
    await _orders.doc(orderId).update({
      'status': 'diproses',
      'confirmedBy': adminUid,
      'confirmedAt': Timestamp.now(),
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _orders.doc(orderId).update({'status': status});
  }

  Future<void> saveProduct(ProductModel product, bool isNew) async {
    if (isNew) {
      await _products.add(product.toFirestore());
    } else {
      await _products.doc(product.id).update(product.toFirestore());
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }
}
