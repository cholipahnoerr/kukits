import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

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

  DateTime _getMonday(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _monthLabel() {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final now = DateTime.now();
    return '${months[now.month]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(monthLabel: _monthLabel()),
          _WeekTabBar(
            tabController: _tabController,
            weekDates: _weekDates,
            todayStr: _todayStr,
            days: _days,
          ),
          Expanded(
            child: BlocBuilder<PlannerBloc, PlannerState>(
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: _weekDates.map((date) {
                    final plans = state.plansForDate(date);
                    return _DayPlanView(
                      date: date,
                      plans: plans,
                      isToday: date == _todayStr,
                      onAddMeal: () => context.push(RouteNames.addMeal, extra: date),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          RouteNames.addMeal,
          extra: _weekDates[_tabController.index],
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String monthLabel;
  const _Header({required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal Planner',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Progress ring for week completion
            BlocBuilder<PlannerBloc, PlannerState>(
              builder: (context, state) {
                final total = state.plans.length;
                final done = state.plans.where((p) => p.isDone).length;
                final pct = total > 0 ? (done / total * 100).round() : 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '$done/$total selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      if (total > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Text(
                            '$pct%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week Tab Bar ──────────────────────────────────────────────────
class _WeekTabBar extends StatelessWidget {
  final TabController tabController;
  final List<String> weekDates;
  final String todayStr;
  final List<String> days;

  const _WeekTabBar({
    required this.tabController,
    required this.weekDates,
    required this.todayStr,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: false,
        dividerHeight: 0,
        indicator: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: weekDates.asMap().entries.map((e) {
          final dt = DateTime.parse(e.value);
          final isToday = e.value == todayStr;
          return Tab(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(days[dt.weekday - 1]),
                const SizedBox(height: 2),
                Text(
                  '${dt.day}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isToday)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Day Plan View ─────────────────────────────────────────────────
class _DayPlanView extends StatelessWidget {
  final String date;
  final List<MealPlanModel> plans;
  final bool isToday;
  final VoidCallback onAddMeal;

  const _DayPlanView({
    required this.date,
    required this.plans,
    required this.isToday,
    required this.onAddMeal,
  });

  Map<String, List<MealPlanModel>> get _grouped {
    final map = <String, List<MealPlanModel>>{};
    for (final type in ['sarapan', 'makan_siang', 'makan_malam', 'snack']) {
      map[type] = plans.where((p) => p.mealType == type).toList();
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return _EmptyDay(isToday: isToday, onAdd: onAddMeal);
    }

    final grouped = _grouped;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        if (isToday) _TodayBanner(plans: plans),
        if (isToday) const SizedBox(height: 14),
        ...['sarapan', 'makan_siang', 'makan_malam', 'snack'].map((type) {
          final typePlans = grouped[type] ?? [];
          if (typePlans.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MealGroup(mealType: type, plans: typePlans),
          );
        }),
      ],
    );
  }
}

class _TodayBanner extends StatelessWidget {
  final List<MealPlanModel> plans;
  const _TodayBanner({required this.plans});

  @override
  Widget build(BuildContext context) {
    final done = plans.where((p) => p.isDone).length;
    final total = plans.length;
    final allDone = done == total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'Semua selesai!' : 'Hari ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  allDone
                      ? 'Hebat! Kamu konsisten hari ini 🌿'
                      : '$done dari $total rencana makan selesai',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${total > 0 ? (done / total * 100).round() : 0}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meal Group ────────────────────────────────────────────────────
class _MealGroup extends StatelessWidget {
  final String mealType;
  final List<MealPlanModel> plans;

  const _MealGroup({required this.mealType, required this.plans});

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

  @override
  Widget build(BuildContext context) {
    final doneCount = plans.where((p) => p.isDone).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x082D3436), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Text(
                  '$doneCount/${plans.length}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: doneCount == plans.length
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0, indent: 14, endIndent: 14),
          // Plan tiles
          ...plans.map((plan) => _PlanTile(plan: plan)),
        ],
      ),
    );
  }
}

// ── Plan Tile ─────────────────────────────────────────────────────
class _PlanTile extends StatelessWidget {
  final MealPlanModel plan;
  const _PlanTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlannerBloc>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Checkbox custom
          GestureDetector(
            onTap: () => bloc.add(PlannerToggleDone(plan.id, !plan.isDone)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: plan.isDone ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: plan.isDone ? AppColors.primary : AppColors.cardBorder,
                  width: 2,
                ),
              ),
              child: plan.isDone
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Menu info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.menuName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: plan.isDone ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: plan.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      plan.reminderTime,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Reminder toggle
          GestureDetector(
            onTap: () => bloc.add(
              PlannerToggleReminder(plan.id, plan, !plan.isReminderOn),
            ),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: plan.isReminderOn
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: plan.isReminderOn ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                plan.isReminderOn
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_outlined,
                size: 16,
                color: plan.isReminderOn ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Delete
          GestureDetector(
            onTap: () => _confirmDelete(context, bloc),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PlannerBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus rencana?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          plan.menuName,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              bloc.add(PlannerDeleteMeal(plan.id));
              Navigator.pop(context);
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Day ─────────────────────────────────────────────────────
class _EmptyDay extends StatelessWidget {
  final bool isToday;
  final VoidCallback onAdd;

  const _EmptyDay({required this.isToday, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isToday ? 'Belum ada rencana hari ini' : 'Belum ada rencana',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan menu makan untuk\nmemulai rencanamu',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Tambah Menu'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
