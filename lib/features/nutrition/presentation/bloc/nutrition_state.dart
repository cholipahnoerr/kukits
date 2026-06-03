import 'package:equatable/equatable.dart';
import '../../domain/food_log_model.dart';

class NutritionState extends Equatable {
  final List<FoodLogModel> logs;
  final bool isLoading;
  final String? error;
  final String date;

  const NutritionState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.date = '',
  });

  int get totalCalories => logs.fold(0, (s, l) => s + l.calories);
  double get totalProtein => logs.fold(0.0, (s, l) => s + l.protein);
  double get totalCarbs => logs.fold(0.0, (s, l) => s + l.carbs);
  double get totalFat => logs.fold(0.0, (s, l) => s + l.fat);

  List<FoodLogModel> logsFor(String mealType) =>
      logs.where((l) => l.mealType == mealType).toList();

  NutritionState copyWith({
    List<FoodLogModel>? logs,
    bool? isLoading,
    String? error,
    String? date,
  }) =>
      NutritionState(
        logs: logs ?? this.logs,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        date: date ?? this.date,
      );

  @override
  List<Object?> get props => [logs, isLoading, error, date];
}
