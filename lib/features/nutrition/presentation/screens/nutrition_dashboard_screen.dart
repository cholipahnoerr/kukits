import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/nutrition_bloc.dart';
import '../bloc/nutrition_event.dart';
import '../bloc/nutrition_state.dart';
import '../../domain/food_log_model.dart';

class NutritionDashboardScreen extends StatefulWidget {
  const NutritionDashboardScreen({super.key});

  @override
  State<NutritionDashboardScreen> createState() =>
      _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState
    extends State<NutritionDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<NutritionBloc>().add(NutritionLoadDay(
            userId: auth.user.uid,
            date: FoodLogModel.todayDate(),
          ));
    }
  }

  void _showEditTarget(BuildContext context, NutritionTarget current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _EditTargetSheet(current: current),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrisi Harian'),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final target = authState is AuthAuthenticated
                  ? authState.user.nutritionTarget
                  : const NutritionTarget();
              return IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Edit target harian',
                onPressed: () => _showEditTarget(context, target),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat',
            onPressed: () => context.push(RouteNames.foodHistory),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addFood),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<NutritionBloc, NutritionState>(
        listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ),
          );
        },
        builder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          final target = authState is AuthAuthenticated
              ? authState.user.nutritionTarget
              : const NutritionTarget();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CalorieSummaryCard(state: state, target: target),
              const SizedBox(height: 16),
              _MacroChart(state: state, target: target),
              const SizedBox(height: 16),
              ...['sarapan', 'makan_siang', 'makan_malam', 'snack']
                  .map((type) => _MealSection(
                        mealType: type,
                        logs: state.logsFor(type),
                        onDelete: (id) => context
                            .read<NutritionBloc>()
                            .add(NutritionDeleteFood(id)),
                        onEdit: (log) =>
                            context.push(RouteNames.editFood, extra: log),
                      )),
            ],
          );
        },
      ),
    );
  }
}

// ── Edit Target Bottom Sheet ──────────────────────────────────────
class _EditTargetSheet extends StatefulWidget {
  final NutritionTarget current;
  const _EditTargetSheet({required this.current});

  @override
  State<_EditTargetSheet> createState() => _EditTargetSheetState();
}

class _EditTargetSheetState extends State<_EditTargetSheet> {
  late final TextEditingController _calCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _calCtrl = TextEditingController(
        text: widget.current.calories.toString());
    _proteinCtrl = TextEditingController(
        text: widget.current.protein.toString());
    _carbsCtrl = TextEditingController(
        text: widget.current.carbs.toString());
    _fatCtrl =
        TextEditingController(text: widget.current.fat.toString());
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    final newTarget = NutritionTarget(
      calories: int.tryParse(_calCtrl.text) ?? widget.current.calories,
      protein: int.tryParse(_proteinCtrl.text) ?? widget.current.protein,
      carbs: int.tryParse(_carbsCtrl.text) ?? widget.current.carbs,
      fat: int.tryParse(_fatCtrl.text) ?? widget.current.fat,
    );

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.user.uid)
          .update({'nutritionTarget': newTarget.toMap()});

      final updatedUser = auth.user.copyWith(nutritionTarget: newTarget);
      if (mounted) {
        context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Target Nutrisi Harian',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _TargetField(ctrl: _calCtrl, label: 'Kalori (kkal)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child:
                      _TargetField(ctrl: _proteinCtrl, label: 'Protein (g)')),
              const SizedBox(width: 10),
              Expanded(
                  child: _TargetField(ctrl: _carbsCtrl, label: 'Karbo (g)')),
              const SizedBox(width: 10),
              Expanded(
                  child: _TargetField(ctrl: _fatCtrl, label: 'Lemak (g)')),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Simpan Target'),
          ),
        ],
      ),
    );
  }
}

class _TargetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _TargetField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
    );
  }
}

// ── Calorie Summary Card ──────────────────────────────────────────
class _CalorieSummaryCard extends StatelessWidget {
  final NutritionState state;
  final NutritionTarget target;
  const _CalorieSummaryCard(
      {required this.state, required this.target});

  @override
  Widget build(BuildContext context) {
    final progress =
        (state.totalCalories / target.calories).clamp(0.0, 1.0);
    final remaining = target.calories - state.totalCalories;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.totalCalories}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const Text('kkal dikonsumsi',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${remaining > 0 ? remaining : 0}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Text('kkal tersisa',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1 ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Target: ${target.calories} kkal',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Macro Chart ───────────────────────────────────────────────────
class _MacroChart extends StatelessWidget {
  final NutritionState state;
  final NutritionTarget target;
  const _MacroChart({required this.state, required this.target});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Makronutrisi',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MacroBar(
                    label: 'Protein',
                    value: state.totalProtein,
                    target: target.protein.toDouble(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroBar(
                    label: 'Karbo',
                    value: state.totalCarbs,
                    target: target.carbs.toDouble(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroBar(
                    label: 'Lemak',
                    value: state.totalFat,
                    target: target.fat.toDouble(),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Text('${value.toInt()}g',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color)),
        Text('/ ${target.toInt()}g',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ── Meal Section ──────────────────────────────────────────────────
class _MealSection extends StatelessWidget {
  final String mealType;
  final List<FoodLogModel> logs;
  final void Function(String) onDelete;
  final void Function(FoodLogModel) onEdit;

  const _MealSection({
    required this.mealType,
    required this.logs,
    required this.onDelete,
    required this.onEdit,
  });

  String get _label => switch (mealType) {
        'sarapan' => 'Sarapan',
        'makan_siang' => 'Makan Siang',
        'makan_malam' => 'Makan Malam',
        'snack' => 'Snack',
        _ => mealType,
      };

  int get _totalCalories => logs.fold(0, (s, l) => s + l.calories);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(_label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$_totalCalories kkal • ${logs.length} item',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        children: [
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada log',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ...logs.map((log) => ListTile(
                dense: true,
                title: Text(log.foodName),
                subtitle: Text(
                  '${log.calories} kkal • ${log.portion}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.primary),
                      onPressed: () => onEdit(log),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      onPressed: () => onDelete(log.id),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
