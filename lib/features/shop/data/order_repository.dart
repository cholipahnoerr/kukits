import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../domain/cart_model.dart';
import '../domain/order_model.dart';

class OrderRepository {
  final _col = FirebaseFirestore.instance.collection('orders');
  final _storage = Supabase.instance.client.storage;

  static const _bucket = 'payment-proofs';

  Future<OrderModel> createOrder({
    required String userId,
    required CartModel cart,
    required String deliveryMethod,
    required String deliveryAddress,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final shortId = const Uuid().v4().substring(0, 3).toUpperCase();
    final orderId = 'ORD-$dateStr-$shortId';

    final order = OrderModel(
      id: '',
      orderId: orderId,
      userId: userId,
      items: cart.items
          .map((i) => OrderItem(
                productId: i.product.id,
                productName: i.product.name,
                quantity: i.quantity,
                price: i.product.price,
              ))
          .toList(),
      totalPrice: cart.totalPrice,
      deliveryMethod: deliveryMethod,
      deliveryAddress: deliveryAddress,
      status: deliveryMethod == 'cod' ? 'diproses' : 'menunggu_pembayaran',
      createdAt: now,
    );

    final doc = await _col.add(order.toFirestore());
    return order.copyWith(id: doc.id);
  }

  Future<String> uploadPaymentProof(String orderId, File imageFile) async {
    final path = '$orderId.jpg';

    await _storage.from(_bucket).upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final url = _storage.from(_bucket).getPublicUrl(path);

    await _col.doc(orderId).update({
      'paymentProofUrl': url,
      'status': 'dibayar',
    });

    return url;
  }

  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final orders = snap.docs.map(OrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<OrderModel> watchOrder(String orderId) {
    return _col.doc(orderId).snapshots().map(OrderModel.fromFirestore);
  }
}

extension on OrderModel {
  OrderModel copyWith({String? id}) => OrderModel(
        id: id ?? this.id,
        orderId: orderId,
        userId: userId,
        items: items,
        totalPrice: totalPrice,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        status: status,
        paymentProofUrl: paymentProofUrl,
        confirmedBy: confirmedBy,
        confirmedAt: confirmedAt,
        createdAt: createdAt,
      );
}
