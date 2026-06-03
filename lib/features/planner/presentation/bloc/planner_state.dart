import 'package:equatable/equatable.dart';
import '../../domain/meal_plan_model.dart';

class PlannerState extends Equatable {
  final List<MealPlanModel> plans;
  final bool isLoading;
  final String startDate;

  const PlannerState({
    this.plans = const [],
    this.isLoading = false,
    this.startDate = '',
  });

  List<MealPlanModel> plansForDate(String date) =>
      plans.where((p) => p.date == date).toList();

  PlannerState copyWith({
    List<MealPlanModel>? plans,
    bool? isLoading,
    String? startDate,
  }) =>
      PlannerState(
        plans: plans ?? this.plans,
        isLoading: isLoading ?? this.isLoading,
        startDate: startDate ?? this.startDate,
      );

  @override
  List<Object?> get props => [plans, isLoading, startDate];
}
