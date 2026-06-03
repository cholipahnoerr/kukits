import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlanModel {
  final String id;
  final String userId;
  final String date;
  final String mealType;
  final String menuName;
  final String reminderTime;
  final bool isReminderOn;
  final bool isDone;
  final DateTime createdAt;

  const MealPlanModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.menuName,
    required this.reminderTime,
    this.isReminderOn = false,
    this.isDone = false,
    required this.createdAt,
  });

  factory MealPlanModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MealPlanModel(
      id: doc.id,
      userId: d['userId'] as String,
      date: d['date'] as String,
      mealType: d['mealType'] as String,
      menuName: d['menuName'] as String,
      reminderTime: (d['reminderTime'] as String?) ?? '07:00',
      isReminderOn: (d['isReminderOn'] as bool?) ?? false,
      isDone: (d['isDone'] as bool?) ?? false,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': date,
        'mealType': mealType,
        'menuName': menuName,
        'reminderTime': reminderTime,
        'isReminderOn': isReminderOn,
        'isDone': isDone,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  MealPlanModel copyWith({bool? isDone, bool? isReminderOn}) => MealPlanModel(
        id: id,
        userId: userId,
        date: date,
        mealType: mealType,
        menuName: menuName,
        reminderTime: reminderTime,
        isReminderOn: isReminderOn ?? this.isReminderOn,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt,
      );

  String get mealTypeLabel => switch (mealType) {
        'sarapan' => 'Sarapan',
        'makan_siang' => 'Makan Siang',
        'makan_malam' => 'Makan Malam',
        'snack' => 'Snack',
        _ => mealType,
      };
}
