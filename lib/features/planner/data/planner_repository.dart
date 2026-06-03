import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/meal_plan_model.dart';

class PlannerRepository {
  final _col = FirebaseFirestore.instance.collection('meal_plans');

  Stream<List<MealPlanModel>> watchWeekPlans(String userId, String startDate) {
    final dates = List.generate(7, (i) {
      final d = DateTime.parse(startDate).add(Duration(days: i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    return _col
        .where('userId', isEqualTo: userId)
        .where('date', whereIn: dates)
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs.map(MealPlanModel.fromFirestore).toList());
  }

  Future<String> addMealPlan(MealPlanModel plan) async {
    final doc = await _col.add(plan.toFirestore());
    return doc.id;
  }

  Future<void> toggleDone(String id, bool isDone) async {
    await _col.doc(id).update({'isDone': isDone});
  }

  Future<void> toggleReminder(String id, bool isOn) async {
    await _col.doc(id).update({'isReminderOn': isOn});
  }

  Future<void> deleteMealPlan(String id) async {
    await _col.doc(id).delete();
  }
}
