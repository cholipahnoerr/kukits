import 'package:equatable/equatable.dart';
import '../../domain/meal_plan_model.dart';

abstract class PlannerEvent extends Equatable {
  const PlannerEvent();
  @override
  List<Object?> get props => [];
}

class PlannerLoad extends PlannerEvent {
  final String userId;
  final String startDate;
  const PlannerLoad({required this.userId, required this.startDate});
  @override
  List<Object?> get props => [userId, startDate];
}

class PlannerAddMeal extends PlannerEvent {
  final MealPlanModel plan;
  const PlannerAddMeal(this.plan);
  @override
  List<Object?> get props => [plan];
}

class PlannerToggleDone extends PlannerEvent {
  final String id;
  final bool isDone;
  const PlannerToggleDone(this.id, this.isDone);
  @override
  List<Object?> get props => [id, isDone];
}

class PlannerToggleReminder extends PlannerEvent {
  final String planId;
  final MealPlanModel plan;
  final bool isOn;
  const PlannerToggleReminder(this.planId, this.plan, this.isOn);
  @override
  List<Object?> get props => [planId, isOn];
}

class PlannerDeleteMeal extends PlannerEvent {
  final String id;
  const PlannerDeleteMeal(this.id);
  @override
  List<Object?> get props => [id];
}
