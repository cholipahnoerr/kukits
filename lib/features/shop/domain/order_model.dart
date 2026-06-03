import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final int price;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  int get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] as String,
        productName: map['productName'] as String,
        quantity: (map['quantity'] as num).toInt(),
        price: (map['price'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
      };
}

class OrderModel {
  final String id;
  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final int totalPrice;
  final String deliveryMethod;
  final String deliveryAddress;
  final String status;
  final String? paymentProofUrl;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.deliveryMethod,
    required this.deliveryAddress,
    required this.status,
    this.paymentProofUrl,
    this.confirmedBy,
    this.confirmedAt,
    required this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderId: data['orderId'] as String,
      userId: data['userId'] as String,
      items: (data['items'] as List)
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (data['totalPrice'] as num).toInt(),
      deliveryMethod: data['deliveryMethod'] as String,
      deliveryAddress: data['deliveryAddress'] as String,
      status: data['status'] as String,
      paymentProofUrl: data['paymentProofUrl'] as String?,
      confirmedBy: data['confirmedBy'] as String?,
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'userId': userId,
        'items': items.map((i) => i.toMap()).toList(),
        'totalPrice': totalPrice,
        'deliveryMethod': deliveryMethod,
        'deliveryAddress': deliveryAddress,
        'status': status,
        'paymentProofUrl': paymentProofUrl,
        'confirmedBy': confirmedBy,
        'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  String get statusLabel => switch (status) {
        'menunggu_pembayaran' => 'Menunggu Pembayaran',
        'dibayar' => 'Sudah Dibayar',
        'diproses' => 'Diproses',
        'dikirim' => 'Dikirim',
        'selesai' => 'Selesai',
        _ => status,
      };

  String get formattedTotal {
    final formatted = totalPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }
}