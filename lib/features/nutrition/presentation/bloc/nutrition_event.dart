import 'package:equatable/equatable.dart';
import '../../domain/food_log_model.dart';

abstract class NutritionEvent extends Equatable {
  const NutritionEvent();
  @override
  List<Object?> get props => [];
}

class NutritionLoadDay extends NutritionEvent {
  final String userId;
  final String date;
  const NutritionLoadDay({required this.userId, required this.date});
  @override
  List<Object?> get props => [userId, date];
}

class NutritionAddFood extends NutritionEvent {
  final FoodLogModel log;
  const NutritionAddFood(this.log);
  @override
  List<Object?> get props => [log];
}

class NutritionDeleteFood extends NutritionEvent {
  final String id;
  const NutritionDeleteFood(this.id);
  @override
  List<Object?> get props => [id];
}

class NutritionUpdateFood extends NutritionEvent {
  final FoodLogModel log;
  const NutritionUpdateFood(this.log);
  @override
  List<Object?> get props => [log.id];
}
