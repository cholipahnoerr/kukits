import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final NutritionTarget nutritionTarget;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role = 'user',
    this.phone,
    this.address,
    required this.createdAt,
    required this.nutritionTarget,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      photoUrl: data['photoUrl'] as String?,
      role: (data['role'] as String?) ?? 'user',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      nutritionTarget: NutritionTarget.fromMap(
        (data['nutritionTarget'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'role': role,
        'phone': phone,
        'address': address,
        'createdAt': Timestamp.fromDate(createdAt),
        'nutritionTarget': nutritionTarget.toMap(),
      };

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? phone,
    String? address,
    NutritionTarget? nutritionTarget,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        createdAt: createdAt,
        nutritionTarget: nutritionTarget ?? this.nutritionTarget,
      );
}

class NutritionTarget {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const NutritionTarget({
    this.calories = 2000,
    this.protein = 60,
    this.carbs = 250,
    this.fat = 65,
  });

  factory NutritionTarget.fromMap(Map<String, dynamic> map) => NutritionTarget(
        calories: (map['calories'] as num?)?.toInt() ?? 2000,
        protein: (map['protein'] as num?)?.toInt() ?? 60,
        carbs: (map['carbs'] as num?)?.toInt() ?? 250,
        fat: (map['fat'] as num?)?.toInt() ?? 65,
      );

  Map<String, dynamic> toMap() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}