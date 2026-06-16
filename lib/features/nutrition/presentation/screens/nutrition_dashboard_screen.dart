import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  State<NutritionDashboardScreen> createState() => _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState extends State<NutritionDashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _loadDate(DateTime date) {
    setState(() => _selectedDate = date);
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      final d = date;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      context.read<NutritionBloc>().add(NutritionLoadDay(userId: auth.user.uid, date: key));
    }
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<NutritionBloc>().add(
            NutritionLoadDay(userId: auth.user.uid, date: _dateKey),
          );
    }
  }

  void _showEditTarget(BuildContext context, NutritionTarget current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _EditTargetSheet(current: current),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<NutritionBloc, NutritionState>(
        listenWhen: (prev, curr) => curr.error != null && curr.error != prev.error,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        },
        builder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          final user = authState is AuthAuthenticated ? authState.user : null;
          final target = user?.nutritionTarget ?? const NutritionTarget();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  userName: user?.name ?? '',
                  selectedDate: _selectedDate,
                  isToday: _isToday,
                  onPrevDay: () => _loadDate(_selectedDate.subtract(const Duration(days: 1))),
                  onNextDay: _isToday ? null : () => _loadDate(_selectedDate.add(const Duration(days: 1))),
                  onTune: () => _showEditTarget(context, target),
                  onHistory: () => context.push(RouteNames.foodHistory),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _CalorieRingCard(state: state, target: target),
                    const SizedBox(height: 14),
                    _MacroRow(state: state, target: target),
                    const SizedBox(height: 20),
                    _MealSectionLabel(),
                    const SizedBox(height: 10),
                    ...['sarapan', 'makan_siang', 'makan_malam', 'snack'].map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MealCard(
                          mealType: type,
                          logs: state.logsFor(type),
                          onDelete: (id) =>
                              context.read<NutritionBloc>().add(NutritionDeleteFood(id)),
                          onEdit: (log) => context.push(RouteNames.editFood, extra: log),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addFood),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String userName;
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrevDay;
  final VoidCallback? onNextDay;
  final VoidCallback onTune;
  final VoidCallback onHistory;

  const _Header({
    required this.userName,
    required this.selectedDate,
    required this.isToday,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onTune,
    required this.onHistory,
  });

  String get _dateLabel {
    if (isToday) return 'Hari ini';
    final now = DateTime.now();
    final diff = now.difference(selectedDate).inDays;
    if (diff == 1) return 'Kemarin';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${selectedDate.day} ${months[selectedDate.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrisi Harian',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      if (userName.isNotEmpty)
                        Text(
                          'Halo, ${userName.split(' ').first}!',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                _NavIconBtn(icon: Icons.tune_rounded, onTap: onTune),
                const SizedBox(width: 8),
                _NavIconBtn(icon: Icons.history_rounded, onTap: onHistory),
              ],
            ),
            const SizedBox(height: 14),
            // Date navigator
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.cardBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DateNavBtn(icon: Icons.chevron_left_rounded, onTap: onPrevDay),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _dateLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  _DateNavBtn(
                    icon: Icons.chevron_right_rounded,
                    onTap: onNextDay,
                    disabled: isToday,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryDark),
      ),
    );
  }
}

class _DateNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  const _DateNavBtn({required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled ? Colors.transparent : AppColors.background,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Icon(
          icon,
          size: 20,
          color: disabled ? AppColors.divider : AppColors.primaryDark,
        ),
      ),
    );
  }
}

// ── Calorie Ring Card ─────────────────────────────────────────────
class _CalorieRingCard extends StatelessWidget {
  final NutritionState state;
  final NutritionTarget target;
  const _CalorieRingCard({required this.state, required this.target});

  @override
  Widget build(BuildContext context) {
    final progress = (state.totalCalories / target.calories).clamp(0.0, 1.0);
    final remaining = (target.calories - state.totalCalories).clamp(0, target.calories);
    final isOver = state.totalCalories > target.calories;
    final ringColor = isOver ? AppColors.error : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x082D3436), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(130, 130),
                  painter: _RingPainter(
                    progress: progress,
                    color: ringColor,
                    trackColor: AppColors.divider,
                    strokeWidth: 13,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${state.totalCalories}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'kkal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalorieStat(
                  label: 'Target',
                  value: '${target.calories}',
                  unit: 'kkal',
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 14),
                _CalorieStat(
                  label: isOver ? 'Kelebihan' : 'Tersisa',
                  value: '$remaining',
                  unit: 'kkal',
                  color: isOver ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(height: 14),
                // Progress label
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ringColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(progress * 100).toInt()}% dari target',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _CalorieStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Macro Row ─────────────────────────────────────────────────────
class _MacroRow extends StatelessWidget {
  final NutritionState state;
  final NutritionTarget target;
  const _MacroRow({required this.state, required this.target});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroCard(
            label: 'Protein',
            value: state.totalProtein,
            target: target.protein.toDouble(),
            unit: 'g',
            color: const Color(0xFF4A90D9),
            icon: Icons.fitness_center_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            label: 'Karbo',
            value: state.totalCarbs,
            target: target.carbs.toDouble(),
            unit: 'g',
            color: AppColors.accent,
            icon: Icons.grain_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            label: 'Lemak',
            value: state.totalFat,
            target: target.fat.toDouble(),
            unit: 'g',
            color: const Color(0xFFE57373),
            icon: Icons.water_drop_outlined,
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;
  final IconData icon;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x082D3436), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            '${value.toInt()}$unit',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            '/ ${target.toInt()}$unit',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meal Section Label ────────────────────────────────────────────
class _MealSectionLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Log Makanan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

// ── Meal Card ─────────────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  final String mealType;
  final List<FoodLogModel> logs;
  final void Function(String) onDelete;
  final void Function(FoodLogModel) onEdit;

  const _MealCard({
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

  IconData get _icon => switch (mealType) {
        'sarapan' => Icons.wb_sunny_outlined,
        'makan_siang' => Icons.light_mode_outlined,
        'makan_malam' => Icons.nightlight_outlined,
        'snack' => Icons.cookie_outlined,
        _ => Icons.restaurant_outlined,
      };

  int get _totalCalories => logs.fold(0, (s, l) => s + l.calories);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x082D3436), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 18, color: AppColors.primary),
          ),
          title: Text(
            _label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          subtitle: Text(
            logs.isEmpty
                ? 'Belum ada log'
                : '$_totalCalories kkal · ${logs.length} item',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          children: [
            const Divider(height: 0, indent: 16, endIndent: 16),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Ketuk + untuk menambah makanan',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ...logs.map((log) => _FoodLogTile(log: log, onDelete: onDelete, onEdit: onEdit)),
          ],
        ),
      ),
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLogModel log;
  final void Function(String) onDelete;
  final void Function(FoodLogModel) onEdit;

  const _FoodLogTile({
    required this.log,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          // Food image thumbnail
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: log.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: log.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _FoodImagePlaceholder(fromScan: log.fromScan),
                      errorWidget: (context, url, err) => _FoodImagePlaceholder(fromScan: log.fromScan),
                    )
                  : _FoodImagePlaceholder(fromScan: log.fromScan),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.foodName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${log.portion} · ${log.calories} kkal',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Macro chips
          Row(
            children: [
              _MacroChip(label: 'P', value: log.protein),
              const SizedBox(width: 4),
              _MacroChip(label: 'K', value: log.carbs),
              const SizedBox(width: 4),
              _MacroChip(label: 'L', value: log.fat),
            ],
          ),
          const SizedBox(width: 4),
          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => onEdit(log),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus log?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
        content: Text(
          log.foodName,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              onDelete(log.id);
              Navigator.pop(dialogCtx);
            },
            child: Text('Hapus', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _FoodImagePlaceholder extends StatelessWidget {
  final bool fromScan;
  const _FoodImagePlaceholder({required this.fromScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: fromScan
            ? AppColors.accent.withValues(alpha: 0.10)
            : AppColors.primary.withValues(alpha: 0.08),
      ),
      child: Icon(
        fromScan ? Icons.document_scanner_outlined : Icons.restaurant_outlined,
        size: 20,
        color: fromScan ? AppColors.accent : AppColors.primary,
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        '$label:${value.toInt()}',
        style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Edit Target Sheet ─────────────────────────────────────────────
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
    _calCtrl = TextEditingController(text: '${widget.current.calories}');
    _proteinCtrl = TextEditingController(text: '${widget.current.protein}');
    _carbsCtrl = TextEditingController(text: '${widget.current.carbs}');
    _fatCtrl = TextEditingController(text: '${widget.current.fat}');
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

      if (mounted) {
        context.read<AuthBloc>().add(AuthUserUpdated(auth.user.copyWith(nutritionTarget: newTarget)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Target Nutrisi Harian',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sesuaikan target kalori dan makromu',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _TargetField(ctrl: _calCtrl, label: 'Kalori (kkal)', icon: Icons.local_fire_department_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TargetField(ctrl: _proteinCtrl, label: 'Protein (g)', icon: Icons.fitness_center_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _TargetField(ctrl: _carbsCtrl, label: 'Karbo (g)', icon: Icons.grain_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _TargetField(ctrl: _fatCtrl, label: 'Lemak (g)', icon: Icons.water_drop_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Simpan Target',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  const _TargetField({required this.ctrl, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        prefixIcon: Icon(icon, size: 16),
        isDense: true,
      ),
    );
  }
}
