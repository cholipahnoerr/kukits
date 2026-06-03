import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/food_log_model.dart';

class NutritionRepository {
  final _col = FirebaseFirestore.instance.collection('food_logs');

  Stream<List<FoodLogModel>> watchDailyLogs(String userId, String date) {
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(FoodLogModel.fromFirestore).toList());
  }

  Future<void> addFoodLog(FoodLogModel log) async {
    await _col.add(log.toFirestore());
  }

  Future<void> updateFoodLog(FoodLogModel log) async {
    await _col.doc(log.id).update(log.toFirestore());
  }

  Future<void> deleteFoodLog(String id) async {
    await _col.doc(id).delete();
  }

  Stream<List<FoodLogModel>> watchHistory(String userId, {int days = 7}) {
    final dates = List.generate(days, (i) {
      final d = DateTime.now().subtract(Duration(days: i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', whereIn: dates)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FoodLogModel.fromFirestore).toList());
  }
}
