import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/nutrition_repository.dart';
import 'nutrition_event.dart';
import 'nutrition_state.dart';

class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  final NutritionRepository _repository;

  NutritionBloc({NutritionRepository? repository})
      : _repository = repository ?? NutritionRepository(),
        super(const NutritionState()) {
    on<NutritionLoadDay>(_onLoadDay);
    on<NutritionAddFood>(_onAddFood);
    on<NutritionUpdateFood>(_onUpdateFood);
    on<NutritionDeleteFood>(_onDeleteFood);
  }

  Future<void> _onLoadDay(NutritionLoadDay event, Emitter<NutritionState> emit) async {
    emit(state.copyWith(isLoading: true, date: event.date));
    await emit.forEach(
      _repository.watchDailyLogs(event.userId, event.date),
      onData: (logs) => state.copyWith(logs: logs, isLoading: false, date: event.date),
      onError: (_, _) => state.copyWith(isLoading: false, error: 'Gagal memuat data'),
    );
  }

  Future<void> _onAddFood(NutritionAddFood event, Emitter<NutritionState> emit) async {
    try {
      await _repository.addFoodLog(event.log);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateFood(NutritionUpdateFood event, Emitter<NutritionState> emit) async {
    try {
      await _repository.updateFoodLog(event.log);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteFood(NutritionDeleteFood event, Emitter<NutritionState> emit) async {
    try {
      await _repository.deleteFoodLog(event.id);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
