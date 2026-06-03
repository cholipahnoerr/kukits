import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final _col = FirebaseFirestore.instance.collection('products');

  Stream<List<ProductModel>> watchProducts({String? category}) {
    Query query = _col.where('isActive', isEqualTo: true);
    if (category != null) query = query.where('category', isEqualTo: category);
    return query.snapshots().map(
          (snap) => snap.docs.map(ProductModel.fromFirestore).toList(),
        );
  }

  Future<ProductModel> getProduct(String id) async {
    final doc = await _col.doc(id).get();
    return ProductModel.fromFirestore(doc);
  }
}