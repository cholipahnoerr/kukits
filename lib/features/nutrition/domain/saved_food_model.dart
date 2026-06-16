import 'package:cloud_firestore/cloud_firestore.dart';

class SavedFoodModel {
  final String id;
  final String userId;
  final String foodName;
  final int caloriesPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final String? imageUrl;
  final DateTime createdAt;

  const SavedFoodModel({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.caloriesPerServing,
    required this.proteinPerServing,
    required this.carbsPerServing,
    required this.fatPerServing,
    this.imageUrl,
    required this.createdAt,
  });

  factory SavedFoodModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SavedFoodModel(
      id: doc.id,
      userId: d['userId'] as String,
      foodName: d['foodName'] as String,
      caloriesPerServing: (d['caloriesPerServing'] as num).toInt(),
      proteinPerServing: (d['proteinPerServing'] as num).toDouble(),
      carbsPerServing: (d['carbsPerServing'] as num).toDouble(),
      fatPerServing: (d['fatPerServing'] as num).toDouble(),
      imageUrl: d['imageUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'foodName': foodName,
        'caloriesPerServing': caloriesPerServing,
        'proteinPerServing': proteinPerServing,
        'carbsPerServing': carbsPerServing,
        'fatPerServing': fatPerServing,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
