import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../nutrition/data/saved_food_repository.dart';
import '../../../nutrition/domain/food_log_model.dart';
import '../../../nutrition/domain/saved_food_model.dart';
import '../../../nutrition/presentation/bloc/nutrition_bloc.dart';
import '../../../nutrition/presentation/bloc/nutrition_event.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';

class ScanResultScreen extends StatefulWidget {
  final ScannerSuccess scanState;
  const ScanResultScreen({super.key, required this.scanState});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  String _mealType = 'sarapan';
  bool _saved = false;

  void _saveToLog() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    final result = widget.scanState.result;
    final log = FoodLogModel(
      id: const Uuid().v4(),
      userId: auth.user.uid,
      date: FoodLogModel.todayDate(),
      mealType: _mealType,
      foodName: result.foodName,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
      portion: result.portion,
      fromScan: true,
      createdAt: DateTime.now(),
    );

    context.read<NutritionBloc>().add(NutritionAddFood(log));
    context.read<ScannerBloc>().add(const ScannerReset());

    SavedFoodRepository().saveFood(SavedFoodModel(
      id: '',
      userId: auth.user.uid,
      foodName: result.foodName,
      caloriesPerServing: result.calories,
      proteinPerServing: result.protein,
      carbsPerServing: result.carbs,
      fatPerServing: result.fat,
      createdAt: DateTime.now(),
    ));

    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.scanState.result;
    final image = widget.scanState.imageFile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Image hero with back button overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                child: Image.file(
                  image,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient overlay bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ),
              // Back button
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x142D3436),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ),
              // AI badge bottom-left of image
              Positioned(
                bottom: 14,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Hasil AI',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name + portion
                  Text(
                    result.foodName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        'Estimasi: ${result.portion}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Nutrisi grid
                  _NutrientGrid(result: result),
                  const SizedBox(height: 20),
                  // Divider
                  const Divider(),
                  const SizedBox(height: 16),
                  // Save section
                  if (!_saved) ...[
                    Text(
                      'Simpan ke Log Nutrisi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MealTypePicker(
                      selected: _mealType,
                      onChanged: (v) => setState(() => _mealType = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saveToLog,
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: Text(
                          'Simpan ke Log',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: Text(
                          'Scan Ulang',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    _SavedBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nutrient Grid ─────────────────────────────────────────────────
class _NutrientGrid extends StatelessWidget {
  final dynamic result;
  const _NutrientGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kalori — full width card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '${result.calories}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'kkal',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total Kalori',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Makro — 3 cards
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                label: 'Protein',
                value: result.protein.toStringAsFixed(1),
                unit: 'g',
                color: const Color(0xFF4A90D9),
                icon: Icons.fitness_center_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroCard(
                label: 'Karbo',
                value: result.carbs.toStringAsFixed(1),
                unit: 'g',
                color: AppColors.accent,
                icon: Icons.grain_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroCard(
                label: 'Lemak',
                value: result.fat.toStringAsFixed(1),
                unit: 'g',
                color: const Color(0xFFE57373),
                icon: Icons.water_drop_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
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

// ── Meal Type Picker ──────────────────────────────────────────────
class _MealTypePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MealTypePicker({required this.selected, required this.onChanged});

  static const _options = [
    ('sarapan', 'Sarapan', Icons.wb_sunny_outlined),
    ('makan_siang', 'Siang', Icons.light_mode_outlined),
    ('makan_malam', 'Malam', Icons.nightlight_outlined),
    ('snack', 'Snack', Icons.cookie_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (value, label, icon) = opt;
        final isSelected = selected == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: value == 'snack' ? 0 : 8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primaryDark : AppColors.cardBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Saved Banner ──────────────────────────────────────────────────
class _SavedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tersimpan!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Makanan berhasil ditambahkan ke log nutrisimu.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(
              'Scan Makanan Lain',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
