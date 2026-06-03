import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/planner_repository.dart';
import '../../../../core/services/notification_service.dart';
import 'planner_event.dart';
import 'planner_state.dart';

class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  final PlannerRepository _repository;

  PlannerBloc({PlannerRepository? repository})
      : _repository = repository ?? PlannerRepository(),
        super(const PlannerState()) {
    on<PlannerLoad>(_onLoad);
    on<PlannerAddMeal>(_onAddMeal);
    on<PlannerToggleDone>(_onToggleDone);
    on<PlannerToggleReminder>(_onToggleReminder);
    on<PlannerDeleteMeal>(_onDeleteMeal);
  }

  Future<void> _onLoad(PlannerLoad event, Emitter<PlannerState> emit) async {
    emit(state.copyWith(isLoading: true, startDate: event.startDate));
    await emit.forEach(
      _repository.watchWeekPlans(event.userId, event.startDate),
      onData: (plans) => state.copyWith(plans: plans, isLoading: false),
      onError: (_, __) => state.copyWith(isLoading: false),
    );
  }

  Future<void> _onAddMeal(PlannerAddMeal event, Emitter<PlannerState> emit) async {
    final id = await _repository.addMealPlan(event.plan);
    if (event.plan.isReminderOn) {
      await NotificationService.scheduleMealReminder(
        id: id.hashCode,
        title: event.plan.mealTypeLabel,
        body: 'Saatnya ${event.plan.mealTypeLabel}: ${event.plan.menuName}',
        time: event.plan.reminderTime,
      );
    }
  }

  Future<void> _onToggleDone(PlannerToggleDone event, Emitter<PlannerState> emit) async {
    await _repository.toggleDone(event.id, event.isDone);
  }

  Future<void> _onToggleReminder(PlannerToggleReminder event, Emitter<PlannerState> emit) async {
    await _repository.toggleReminder(event.planId, event.isOn);
    if (event.isOn) {
      await NotificationService.scheduleMealReminder(
        id: event.planId.hashCode,
        title: event.plan.mealTypeLabel,
        body: 'Saatnya ${event.plan.mealTypeLabel}: ${event.plan.menuName}',
        time: event.plan.reminderTime,
      );
    } else {
      await NotificationService.cancelNotification(event.planId.hashCode);
    }
  }

  Future<void> _onDeleteMeal(PlannerDeleteMeal event, Emitter<PlannerState> emit) async {
    await _repository.deleteMealPlan(event.id);
    await NotificationService.cancelNotification(event.id.hashCode);
  }
}
