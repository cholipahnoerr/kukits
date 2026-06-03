import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/saved_food_model.dart';

class SavedFoodRepository {
  final _col = FirebaseFirestore.instance.collection('saved_foods');

  Stream<List<SavedFoodModel>> watchSavedFoods(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('foodName')
        .snapshots()
        .map((s) => s.docs.map(SavedFoodModel.fromFirestore).toList());
  }

  Future<void> saveFood(SavedFoodModel food) async {
    // Upsert: if same foodName exists for this user, update it
    final existing = await _col
        .where('userId', isEqualTo: food.userId)
        .where('foodName', isEqualTo: food.foodName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update(food.toFirestore());
    } else {
      await _col.add(food.toFirestore());
    }
  }

  Future<void> deleteFood(String id) async {
    await _col.doc(id).delete();
  }
}
