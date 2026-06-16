import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/food_log_model.dart';

class NutritionRepository {
  final _col = FirebaseFirestore.instance.collection('food_logs');

  Stream<List<FoodLogModel>> watchDailyLogs(String userId, String date) {
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((s) {
      final logs = s.docs.map(FoodLogModel.fromFirestore).toList();
      logs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return logs;
    });
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
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffKey =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final logs = s.docs
          .map(FoodLogModel.fromFirestore)
          .where((l) => l.date.compareTo(cutoffKey) >= 0)
          .toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return logs;
    });
  }
}
