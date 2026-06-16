import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/saved_food_model.dart';

class SavedFoodRepository {
  final _col = FirebaseFirestore.instance.collection('saved_foods');
  final _storage = Supabase.instance.client.storage;
  static const _bucket = 'food-images';

  Future<String?> uploadFoodImage(String userId, File imageFile) async {
    final ext = imageFile.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final path = '$userId/${const Uuid().v4()}.$ext';
    await _storage.from(_bucket).upload(
          path,
          imageFile,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    return _storage.from(_bucket).getPublicUrl(path);
  }

  Stream<List<SavedFoodModel>> watchSavedFoods(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final foods = s.docs.map(SavedFoodModel.fromFirestore).toList();
      foods.sort((a, b) => a.foodName.compareTo(b.foodName));
      return foods;
    });
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
