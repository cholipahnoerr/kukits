import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final List<String> imageUrls;
  final String category;
  final bool isActive;
  final int sold;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrls,
    required this.category,
    this.isActive = true,
    this.sold = 0,
    required this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toInt(),
      stock: (data['stock'] as num).toInt(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: (data['category'] as String?) ?? 'kukusan',
      isActive: (data['isActive'] as bool?) ?? true,
      sold: (data['sold'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'imageUrls': imageUrls,
        'category': category,
        'isActive': isActive,
        'sold': sold,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  String get formattedPrice {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }
}