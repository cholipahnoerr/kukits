import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLogModel {
  final String id;
  final String userId;
  final String date;
  final String mealType;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String portion;
  final double servings;
  final bool fromScan;
  final String? imageUrl;
  final DateTime createdAt;

  const FoodLogModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portion,
    this.servings = 1.0,
    this.fromScan = false,
    this.imageUrl,
    required this.createdAt,
  });

  factory FoodLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FoodLogModel(
      id: doc.id,
      userId: d['userId'] as String,
      date: d['date'] as String,
      mealType: d['mealType'] as String,
      foodName: d['foodName'] as String,
      calories: (d['calories'] as num).toInt(),
      protein: (d['protein'] as num).toDouble(),
      carbs: (d['carbs'] as num).toDouble(),
      fat: (d['fat'] as num).toDouble(),
      portion: (d['portion'] as String?) ?? '1 porsi',
      servings: (d['servings'] as num?)?.toDouble() ?? 1.0,
      fromScan: (d['fromScan'] as bool?) ?? false,
      imageUrl: d['imageUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': date,
        'mealType': mealType,
        'foodName': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'portion': portion,
        'servings': servings,
        'fromScan': fromScan,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static String todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
