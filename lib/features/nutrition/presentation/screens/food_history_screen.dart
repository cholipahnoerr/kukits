import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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

  bool get _isToday => _selectedDay == _today;
  bool get _isFuture => _selectedDay.isAfter(_today);

  String _formatDate(DateTime d) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (d == _today) return 'Hari ini';
    if (d == _today.subtract(const Duration(days: 1))) return 'Kemarin';
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  Future<void> _pickDate() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopBar(
            isToday: _isToday,
            onAdd: () => context.push(RouteNames.addFood),
          ),
          _DateNavigator(
            label: _formatDate(_selectedDay),
            onPrev: () => _changeDay(-1),
            onNext: _isFuture ? null : () => _changeDay(1),
            onTap: _pickDate,
            isToday: _isToday,
          ),
          Expanded(
            child: StreamBuilder<List<FoodLogModel>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return _EmptyDay(
                    isToday: _isToday,
                    onAdd: () => context.push(RouteNames.addFood),
                  );
                }

                final totalCal = logs.fold(0, (s, l) => s + l.calories);
                final totalProtein =
                    logs.fold(0.0, (s, l) => s + l.protein);
                final totalCarbs = logs.fold(0.0, (s, l) => s + l.carbs);
                final totalFat = logs.fold(0.0, (s, l) => s + l.fat);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    _DaySummaryCard(
                      totalCal: totalCal,
                      totalProtein: totalProtein,
                      totalCarbs: totalCarbs,
                      totalFat: totalFat,
                      target: _target,
                    ),
                    const SizedBox(height: 14),
                    for (final type in [
                      'sarapan',
                      'makan_siang',
                      'makan_malam',
                      'snack'
                    ]) ...[
                      _MealGroup(
                        mealType: type,
                        logs: logs.where((l) => l.mealType == type).toList(),
                        onDelete: (id) => context
                            .read<NutritionBloc>()
                            .add(NutritionDeleteFood(id)),
                        onEdit: (log) =>
                            context.push(RouteNames.editFood, extra: log),
                      ),
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
}

// ── Top Bar ───────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isToday;
  final VoidCallback onAdd;
  const _TopBar({required this.isToday, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Nutrisi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Log makanan harian',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isToday)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 20, color: Colors.white),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date Navigator ────────────────────────────────────────────────
class _DateNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTap;
  final bool isToday;

  const _DateNavigator({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            onTap: onPrev,
            enabled: true,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (isToday)
                    Text(
                      'Tap untuk pilih tanggal',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            onTap: onNext ?? () {},
            enabled: onNext != null,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _NavBtn(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            size: 22,
            color: enabled ? AppColors.primaryDark : AppColors.divider),
      ),
    );
  }
}

// ── Day Summary Card ──────────────────────────────────────────────
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
    final progress = (totalCal / target.calories).clamp(0.0, 1.0);
    final isOver = totalCal > target.calories;
    final remaining =
        isOver ? 0 : target.calories - totalCal;
    final progressColor = isOver ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x082D3436), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalCal',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      'kkal dikonsumsi',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOver ? '+${totalCal - target.calories}' : '$remaining',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isOver
                            ? AppColors.error
                            : AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      isOver ? 'kkal kelebihan' : 'kkal tersisa',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Target: ${target.calories} kkal',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 0),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MacroCol(
                  label: 'Protein',
                  value: totalProtein.toInt(),
                  target: target.protein,
                  color: const Color(0xFF4A90D9),
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.divider),
              Expanded(
                child: _MacroCol(
                  label: 'Karbo',
                  value: totalCarbs.toInt(),
                  target: target.carbs,
                  color: AppColors.accent,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.divider),
              Expanded(
                child: _MacroCol(
                  label: 'Lemak',
                  value: totalFat.toInt(),
                  target: target.fat,
                  color: const Color(0xFFE57373),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCol extends StatelessWidget {
  final String label;
  final int value;
  final int target;
  final Color color;
  const _MacroCol({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value}g',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          '/ ${target}g',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Meal Group ────────────────────────────────────────────────────
class _MealGroup extends StatefulWidget {
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

  @override
  State<_MealGroup> createState() => _MealGroupState();
}

class _MealGroupState extends State<_MealGroup> {
  bool _expanded = true;

  String get _label => switch (widget.mealType) {
        'sarapan' => 'Sarapan',
        'makan_siang' => 'Makan Siang',
        'makan_malam' => 'Makan Malam',
        'snack' => 'Snack',
        _ => widget.mealType,
      };

  IconData get _icon => switch (widget.mealType) {
        'sarapan' => Icons.wb_sunny_outlined,
        'makan_siang' => Icons.light_mode_outlined,
        'makan_malam' => Icons.nightlight_outlined,
        'snack' => Icons.cookie_outlined,
        _ => Icons.restaurant_outlined,
      };

  int get _total => widget.logs.fold(0, (s, l) => s + l.calories);

  @override
  Widget build(BuildContext context) {
    if (widget.logs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x082D3436), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(_icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          '$_total kkal · ${widget.logs.length} item',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Food log tiles
          if (_expanded) ...[
            const Divider(height: 0, indent: 16, endIndent: 16),
            ...widget.logs.map((log) => _FoodLogTile(
                  log: log,
                  onEdit: () => widget.onEdit(log),
                  onDelete: () => widget.onDelete(log.id),
                )),
          ],
        ],
      ),
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLogModel log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodLogTile({
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (log.fromScan)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 11, color: AppColors.accent),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.foodName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${log.calories} kkal',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _MacroTag(
                        label:
                            'P ${log.protein.toInt()}g',
                        color: const Color(0xFF4A90D9)),
                    const SizedBox(width: 4),
                    _MacroTag(
                        label:
                            'K ${log.carbs.toInt()}g',
                        color: AppColors.accent),
                    const SizedBox(width: 4),
                    _MacroTag(
                        label:
                            'L ${log.fat.toInt()}g',
                        color: const Color(0xFFE57373)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 15, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 15, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────
class _EmptyDay extends StatelessWidget {
  final bool isToday;
  final VoidCallback onAdd;
  const _EmptyDay({required this.isToday, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.no_meals_outlined,
                size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak ada log makanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? 'Mulai catat makananmu hari ini'
                : 'Tidak ada catatan pada hari ini',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          if (isToday) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Tambah Makanan',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
