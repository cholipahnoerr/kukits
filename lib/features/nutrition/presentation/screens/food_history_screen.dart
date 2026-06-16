import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/nutrition_repository.dart';
import '../../domain/food_log_model.dart';

// ── Data helpers ──────────────────────────────────────────────────

class _DayData {
  final DateTime date;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int items;

  const _DayData({
    required this.date,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.items = 0,
  });

  bool get hasData => items > 0;

  _DayData merge(FoodLogModel log) => _DayData(
        date: date,
        calories: calories + log.calories,
        protein: protein + log.protein,
        carbs: carbs + log.carbs,
        fat: fat + log.fat,
        items: items + 1,
      );
}

class _WeekData {
  final List<_DayData> days;
  const _WeekData(this.days);

  int get avgCalories {
    final active = days.where((d) => d.hasData).toList();
    if (active.isEmpty) return 0;
    return active.map((d) => d.calories).reduce((a, b) => a + b) ~/ active.length;
  }
}

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── Screen ────────────────────────────────────────────────────────

class FoodHistoryScreen extends StatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen> {
  bool _isWeekly = true;
  late Stream<List<FoodLogModel>> _stream;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      final uid = auth.user.uid;
      if (_userId != uid) {
        _userId = uid;
        _stream = NutritionRepository().watchHistory(uid, days: _isWeekly ? 7 : 30);
      }
    }
  }

  void _setPeriod(bool weekly) {
    if (_isWeekly == weekly) return;
    setState(() {
      _isWeekly = weekly;
      if (_userId != null) {
        _stream = NutritionRepository().watchHistory(_userId!, days: weekly ? 7 : 30);
      }
    });
  }

  List<_DayData> _buildDayList(List<FoodLogModel> logs, int days) {
    final map = <String, _DayData>{};
    for (int i = days - 1; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      map[_key(d)] = _DayData(date: d);
    }
    for (final log in logs) {
      if (map.containsKey(log.date)) {
        map[log.date] = map[log.date]!.merge(log);
      }
    }
    return map.values.toList();
  }

  List<_WeekData> _toWeeks(List<_DayData> days) {
    final weeks = <_WeekData>[];
    for (int i = 0; i < days.length; i += 7) {
      final chunk = days.sublist(i, (i + 7).clamp(0, days.length));
      weeks.add(_WeekData(chunk));
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return const SizedBox.shrink();

    final user = auth.user;
    final days = _isWeekly ? 7 : 30;
    final target = user.nutritionTarget.calories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopBar(),
          Expanded(
            child: StreamBuilder<List<FoodLogModel>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final dayList = _buildDayList(snap.data ?? [], days);
                final weeks = _toWeeks(dayList);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _PeriodToggle(
                        isWeekly: _isWeekly,
                        onChanged: _setPeriod,
                      ),
                      const SizedBox(height: 16),
                      _SummaryCard(days: dayList, target: target),
                      const SizedBox(height: 16),
                      _CalorieChart(
                        isWeekly: _isWeekly,
                        dayList: dayList,
                        weeks: weeks,
                        target: target,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Detail Harian',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...dayList.reversed.map((d) => _DayRow(day: d, target: target)),
                    ],
                  ),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(4, 0, 20, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: AppColors.primaryDark,
              onPressed: () => context.pop(),
            ),
            Text(
              'Riwayat Nutrisi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period Toggle ─────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final bool isWeekly;
  final ValueChanged<bool> onChanged;
  const _PeriodToggle({required this.isWeekly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _Tab(label: '7 Hari', isSelected: isWeekly, onTap: () => onChanged(true)),
          _Tab(label: '30 Hari', isSelected: !isWeekly, onTap: () => onChanged(false)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<_DayData> days;
  final int target;
  const _SummaryCard({required this.days, required this.target});

  @override
  Widget build(BuildContext context) {
    final active = days.where((d) => d.hasData).toList();
    final avgCal = active.isEmpty
        ? 0
        : active.map((d) => d.calories).reduce((a, b) => a + b) ~/ active.length;
    final avgProtein = active.isEmpty
        ? 0.0
        : active.map((d) => d.protein).reduce((a, b) => a + b) / active.length;
    final avgCarbs = active.isEmpty
        ? 0.0
        : active.map((d) => d.carbs).reduce((a, b) => a + b) / active.length;
    final avgFat = active.isEmpty
        ? 0.0
        : active.map((d) => d.fat).reduce((a, b) => a + b) / active.length;
    final hitTarget = active
        .where((d) => d.calories >= target * 0.8 && d.calories <= target * 1.1)
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata Kalori',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$avgCal',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5, left: 4),
                          child: Text(
                            'kkal/hari',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Capai Target',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$hitTarget',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: active.isEmpty
                              ? Colors.white54
                              : hitTarget > active.length / 2
                                  ? const Color(0xFF6BCB77)
                                  : const Color(0xFFFF6B6B),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 3),
                        child: Text(
                          '/ ${active.length} hari',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Row(
            children: [
              _MacroAvg(label: 'Protein', value: avgProtein, color: const Color(0xFF4A90D9)),
              _MacroAvg(label: 'Karbo', value: avgCarbs, color: AppColors.accent),
              _MacroAvg(label: 'Lemak', value: avgFat, color: const Color(0xFFE57373)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroAvg extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MacroAvg({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}g',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }
}

// ── Calorie Chart ─────────────────────────────────────────────────

class _CalorieChart extends StatelessWidget {
  final bool isWeekly;
  final List<_DayData> dayList;
  final List<_WeekData> weeks;
  final int target;

  const _CalorieChart({
    required this.isWeekly,
    required this.dayList,
    required this.weeks,
    required this.target,
  });

  Color _barColor(_DayData d) {
    if (!d.hasData) return AppColors.divider;
    if (d.calories > target * 1.1) return const Color(0xFFE57373);
    if (d.calories >= target * 0.8) return AppColors.primary;
    return AppColors.accent.withValues(alpha: 0.7);
  }

  Color _weekColor(_WeekData w) {
    if (w.avgCalories == 0) return AppColors.divider;
    if (w.avgCalories > target * 1.1) return const Color(0xFFE57373);
    if (w.avgCalories >= target * 0.8) return AppColors.primary;
    return AppColors.accent.withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final maxY = (target * 1.4).toDouble();

    final barGroups = isWeekly
        ? dayList.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.calories.toDouble().clamp(0, maxY),
                  color: _barColor(e.value),
                  width: 28,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            );
          }).toList()
        : weeks.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.avgCalories.toDouble().clamp(0, maxY),
                  color: _weekColor(e.value),
                  width: 48,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            );
          }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              children: [
                Text(
                  'Kalori per ${isWeekly ? 'Hari' : 'Minggu (rata-rata)'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Spacer(),
                _LegendDot(color: AppColors.primary, label: 'Normal'),
                const SizedBox(width: 10),
                _LegendDot(color: const Color(0xFFE57373), label: 'Lebih'),
              ],
            ),
          ),
          ClipRect(
            child: SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: barGroups,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: target.toDouble(),
                      color: AppColors.primary.withValues(alpha: 0.4),
                      strokeWidth: 1.5,
                      dashArray: [5, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => 'Target',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        String label;
                        if (isWeekly) {
                          if (i < 0 || i >= dayList.length) {
                            return const SizedBox.shrink();
                          }
                          final raw = DateFormat('E', 'id').format(dayList[i].date);
                          label = raw.length > 3 ? raw.substring(0, 3) : raw;
                        } else {
                          if (i < 0 || i >= weeks.length) {
                            return const SizedBox.shrink();
                          }
                          label = 'M${i + 1}';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: (target / 2).toDouble(),
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Day Row ───────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final _DayData day;
  final int target;
  const _DayRow({required this.day, required this.target});

  bool get _isToday => _key(day.date) == _key(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ratio = day.hasData ? (day.calories / target).clamp(0.0, 1.5) : 0.0;
    final isOver = day.calories > target * 1.1;
    final isHit = !isOver && day.calories >= target * 0.8;

    final barColor = isOver
        ? const Color(0xFFE57373)
        : isHit
            ? AppColors.primary
            : AppColors.accent.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isToday
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE', 'id').format(day.date),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _isToday ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: _isToday ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Text(
                  DateFormat('d MMM', 'id').format(day.date),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day.hasData ? '${day.calories} kkal' : '— kkal',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: day.hasData
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '/ $target',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation(
                        day.hasData ? barColor : AppColors.divider),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (!day.hasData)
            const Icon(Icons.remove_rounded, size: 16, color: AppColors.textSecondary)
          else if (isHit)
            const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary)
          else if (isOver)
            const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFFE57373))
          else
            const Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.accent),
        ],
      ),
    );
  }
}
