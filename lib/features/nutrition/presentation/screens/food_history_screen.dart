import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/nutrition_repository.dart';
import '../../domain/food_log_model.dart';
import '../bloc/nutrition_bloc.dart';
import '../bloc/nutrition_event.dart';

class FoodHistoryScreen extends StatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen> {
  late final NutritionRepository _repo;
  late final String _userId;
  late final NutritionTarget _target;
  late DateTime _selectedDay;
  late Stream<List<FoodLogModel>> _stream;

  @override
  void initState() {
    super.initState();
    _repo = NutritionRepository();
    _selectedDay = _today;

    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      _userId = auth.user.uid;
      _target = auth.user.nutritionTarget;
    } else {
      _userId = '';
      _target = const NutritionTarget();
    }

    _stream = _buildStream();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String get _dateStr {
    final d = _selectedDay;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Stream<List<FoodLogModel>> _buildStream() =>
      _repo.watchDailyLogs(_userId, _dateStr);

  void _changeDay(int delta) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: delta));
      _stream = _buildStream();
    });
  }

  String _formatDate(DateTime d) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    if (d == _today) return 'Hari ini';
    if (d == _today.subtract(const Duration(days: 1))) return 'Kemarin';
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  bool get _isToday => _selectedDay == _today;
  bool get _isFuture => _selectedDay.isAfter(_today);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Nutrisi'),
        actions: [
          if (_isToday)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push(RouteNames.addFood),
            ),
        ],
      ),
      body: Column(
        children: [
          // Day navigation header
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDay(-1),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(context),
                    child: Text(
                      _formatDate(_selectedDay),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _isFuture ? null : () => _changeDay(1),
                  color: _isFuture ? AppColors.textSecondary : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: StreamBuilder<List<FoodLogModel>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_meals_outlined,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        const Text(
                          'Tidak ada log pada hari ini',
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                        if (_isToday) ...[
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () =>
                                context.push(RouteNames.addFood),
                            child: const Text('Tambah Makanan'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final totalCal =
                    logs.fold(0, (s, l) => s + l.calories);
                final totalProtein =
                    logs.fold(0.0, (s, l) => s + l.protein);
                final totalCarbs =
                    logs.fold(0.0, (s, l) => s + l.carbs);
                final totalFat =
                    logs.fold(0.0, (s, l) => s + l.fat);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Daily summary card
                    _DaySummaryCard(
                      totalCal: totalCal,
                      totalProtein: totalProtein,
                      totalCarbs: totalCarbs,
                      totalFat: totalFat,
                      target: _target,
                    ),
                    const SizedBox(height: 12),

                    // Meals grouped by type
                    for (final type in [
                      'sarapan',
                      'makan_siang',
                      'makan_malam',
                      'snack'
                    ]) ...[
                      _MealGroup(
                        mealType: type,
                        logs: logs
                            .where((l) => l.mealType == type)
                            .toList(),
                        onDelete: (id) => context
                            .read<NutritionBloc>()
                            .add(NutritionDeleteFood(id)),
                        onEdit: (log) => context.push(
                          RouteNames.editFood,
                          extra: log,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2024),
      lastDate: _today,
    );
    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _stream = _buildStream();
      });
    }
  }
}

class _DaySummaryCard extends StatelessWidget {
  final int totalCal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final NutritionTarget target;

  const _DaySummaryCard({
    required this.totalCal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (totalCal / target.calories).clamp(0.0, 1.0);
    final remaining = target.calories - totalCal;

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
                      '$totalCal kkal',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const Text('dikonsumsi',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${remaining > 0 ? remaining : 0} kkal',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Text('tersisa',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1 ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroChip('P', totalProtein, target.protein, Colors.blue),
                _MacroChip(
                    'K', totalCarbs, target.carbs, Colors.orange),
                _MacroChip('L', totalFat, target.fat, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final int targetVal;
  final Color color;

  const _MacroChip(this.label, this.value, this.targetVal, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toInt()}g',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 15),
        ),
        Text(
          '$label / ${targetVal}g',
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MealGroup extends StatelessWidget {
  final String mealType;
  final List<FoodLogModel> logs;
  final void Function(String) onDelete;
  final void Function(FoodLogModel) onEdit;

  const _MealGroup({
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

  int get _total => logs.fold(0, (s, l) => s + l.calories);

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(_label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$_total kkal • ${logs.length} item',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        children: logs
            .map((log) => ListTile(
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
                ))
            .toList(),
      ),
    );
  }
}
