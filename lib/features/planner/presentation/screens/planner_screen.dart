import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/meal_plan_model.dart';
import '../bloc/planner_bloc.dart';
import '../bloc/planner_event.dart';
import '../bloc/planner_state.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _weekDates;

  @override
  void initState() {
    super.initState();
    final monday = _getMonday(DateTime.now());
    _weekDates = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    _tabController = TabController(length: 7, vsync: this);

    final todayIdx = _weekDates.indexOf(_todayStr);
    if (todayIdx >= 0) _tabController.index = todayIdx;

    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<PlannerBloc>().add(
            PlannerLoad(userId: auth.user.uid, startDate: _weekDates[0]),
          );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getMonday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _weekDates.map((d) {
            final dt = DateTime.parse(d);
            final isToday = d == _todayStr;
            return Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _shortDay(dt.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    '${dt.day}',
                    style: TextStyle(
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final selectedDate = _weekDates[_tabController.index];
          context.push(RouteNames.addMeal, extra: selectedDate);
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<PlannerBloc, PlannerState>(
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: _weekDates.map((date) {
              final plans = state.plansForDate(date);
              return _DayPlanView(date: date, plans: plans);
            }).toList(),
          );
        },
      ),
    );
  }

  String _shortDay(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }
}

class _DayPlanView extends StatelessWidget {
  final String date;
  final List<MealPlanModel> plans;

  const _DayPlanView({required this.date, required this.plans});

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 48, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text('Belum ada rencana makan',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _MealPlanTile(plan: plans[i]),
    );
  }
}

class _MealPlanTile extends StatelessWidget {
  final MealPlanModel plan;
  const _MealPlanTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: plan.isDone,
          onChanged: (v) => context
              .read<PlannerBloc>()
              .add(PlannerToggleDone(plan.id, v ?? false)),
          activeColor: AppColors.primary,
        ),
        title: Text(
          plan.menuName,
          style: TextStyle(
            decoration: plan.isDone ? TextDecoration.lineThrough : null,
            color: plan.isDone ? AppColors.textSecondary : null,
          ),
        ),
        subtitle: Text(
          '${plan.mealTypeLabel} • ${plan.reminderTime}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                plan.isReminderOn
                    ? Icons.notifications
                    : Icons.notifications_off_outlined,
                color: plan.isReminderOn
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => context.read<PlannerBloc>().add(
                    PlannerToggleReminder(plan.id, plan, !plan.isReminderOn),
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: () =>
                  context.read<PlannerBloc>().add(PlannerDeleteMeal(plan.id)),
            ),
          ],
        ),
      ),
    );
  }
}
