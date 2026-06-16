import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/saved_food_repository.dart';
import '../../domain/food_log_model.dart';
import '../../domain/saved_food_model.dart';
import '../bloc/nutrition_bloc.dart';
import '../bloc/nutrition_event.dart';

class AddFoodScreen extends StatefulWidget {
  final String? initialMealType;
  final FoodLogModel? existing;
  const AddFoodScreen({super.key, this.initialMealType, this.existing});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  late String _mealType;
  double _servings = 1;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _mealType = e.mealType;
      _servings = e.servings;
      _nameCtrl.text = e.foodName;
      _caloriesCtrl.text = (e.calories / e.servings).round().toString();
      _proteinCtrl.text = _fmt(e.protein / e.servings);
      _carbsCtrl.text = _fmt(e.carbs / e.servings);
      _fatCtrl.text = _fmt(e.fat / e.servings);
    } else {
      _mealType = widget.initialMealType ?? 'sarapan';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => v == 0
      ? ''
      : (v == v.roundToDouble()
          ? v.toInt().toString()
          : v.toStringAsFixed(1));

  int get _totalCalories =>
      ((int.tryParse(_caloriesCtrl.text) ?? 0) * _servings).round();

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    final baseCal = int.parse(_caloriesCtrl.text);
    final baseProtein = double.tryParse(_proteinCtrl.text) ?? 0;
    final baseCarbs = double.tryParse(_carbsCtrl.text) ?? 0;
    final baseFat = double.tryParse(_fatCtrl.text) ?? 0;

    final log = FoodLogModel(
      id: _isEdit ? widget.existing!.id : const Uuid().v4(),
      userId: auth.user.uid,
      date: _isEdit ? widget.existing!.date : FoodLogModel.todayDate(),
      mealType: _mealType,
      foodName: _nameCtrl.text.trim(),
      calories: (baseCal * _servings).round(),
      protein: double.parse((baseProtein * _servings).toStringAsFixed(1)),
      carbs: double.parse((baseCarbs * _servings).toStringAsFixed(1)),
      fat: double.parse((baseFat * _servings).toStringAsFixed(1)),
      portion: _servings == _servings.roundToDouble()
          ? '${_servings.toInt()} porsi'
          : '$_servings porsi',
      servings: _servings,
      fromScan: _isEdit ? widget.existing!.fromScan : false,
      createdAt: _isEdit ? widget.existing!.createdAt : DateTime.now(),
    );

    if (_isEdit) {
      context.read<NutritionBloc>().add(NutritionUpdateFood(log));
    } else {
      context.read<NutritionBloc>().add(NutritionAddFood(log));
    }
    Navigator.pop(context);
  }

  void _pickFromLibrary() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FoodLibrarySheet(
        userId: auth.user.uid,
        onSelected: (food) {
          setState(() {
            _nameCtrl.text = food.foodName;
            _caloriesCtrl.text = food.caloriesPerServing.toString();
            _proteinCtrl.text = _fmt(food.proteinPerServing);
            _carbsCtrl.text = _fmt(food.carbsPerServing);
            _fatCtrl.text = _fmt(food.fatPerServing);
            _servings = 1;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopBar(isEdit: _isEdit, onLibrary: _isEdit ? null : _pickFromLibrary),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Card 1: nama + waktu makan
                  _FormCard(
                    step: '1',
                    title: 'Info Makanan',
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.primaryDark),
                        decoration: InputDecoration(
                          labelText: 'Nama Makanan',
                          prefixIcon: const Icon(
                              Icons.restaurant_outlined,
                              size: 18,
                              color: AppColors.textSecondary),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 46),
                          labelStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Waktu Makan',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      _MealTypePicker(
                        selected: _mealType,
                        onChanged: (v) => setState(() => _mealType = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Card 2: kalori + porsi
                  _FormCard(
                    step: '2',
                    title: 'Kalori & Porsi',
                    children: [
                      TextFormField(
                        controller: _caloriesCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 14, color: AppColors.primaryDark),
                        decoration: InputDecoration(
                          labelText: 'Kalori per porsi',
                          suffixText: 'kkal',
                          prefixIcon: const Icon(
                              Icons.local_fire_department_outlined,
                              size: 18,
                              color: AppColors.textSecondary),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 46),
                          labelStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (int.tryParse(v) == null) return 'Harus angka';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Jumlah Porsi',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          _ServingStepper(
                            value: _servings,
                            onChanged: (v) =>
                                setState(() => _servings = v),
                          ),
                        ],
                      ),
                      if (_caloriesCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calculate_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Total: ',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              Text(
                                '$_totalCalories kkal',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Card 3: makronutrisi
                  _FormCard(
                    step: '3',
                    title: 'Makronutrisi (opsional)',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MacroField(
                              controller: _proteinCtrl,
                              label: 'Protein',
                              icon: Icons.fitness_center_rounded,
                              color: const Color(0xFF4A90D9),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MacroField(
                              controller: _carbsCtrl,
                              label: 'Karbo',
                              icon: Icons.grain_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MacroField(
                              controller: _fatCtrl,
                              label: 'Lemak',
                              icon: Icons.water_drop_outlined,
                              color: const Color(0xFFE57373),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Per porsi dalam gram (g)',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: Icon(
                        _isEdit
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _isEdit ? 'Simpan Perubahan' : 'Tambah ke Log',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isEdit;
  final VoidCallback? onLibrary;
  const _TopBar({required this.isEdit, this.onLibrary});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
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
                      isEdit ? 'Edit Makanan' : 'Tambah Makanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      isEdit
                          ? 'Perbarui data makanan'
                          : 'Catat makanan ke log nutrisi',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (onLibrary != null)
                TextButton.icon(
                  onPressed: onLibrary,
                  icon: const Icon(Icons.bookmark_outline_rounded, size: 16),
                  label: Text(
                    'Tersimpan',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form Card ─────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final String step;
  final String title;
  final List<Widget> children;
  const _FormCard(
      {required this.step, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                    color: AppColors.primaryDark, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    step,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 0),
          const SizedBox(height: 14),
          ...children,
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
              duration: const Duration(milliseconds: 160),
              margin: EdgeInsets.only(right: value == 'snack' ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.cardBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 17,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
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

// ── Serving Stepper ───────────────────────────────────────────────
class _ServingStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _ServingStepper({required this.value, required this.onChanged});

  String get _label => value == value.roundToDouble()
      ? '${value.toInt()} porsi'
      : '$value porsi';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            enabled: value > 0.5,
            onTap: () => onChanged(
                double.parse((value - 0.5).toStringAsFixed(1))),
          ),
          SizedBox(
            width: 72,
            child: Text(
              _label,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            enabled: value < 10,
            onTap: () => onChanged(
                double.parse((value + 0.5).toStringAsFixed(1))),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});

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
            size: 18,
            color: enabled ? AppColors.primary : AppColors.divider),
      ),
    );
  }
}

// ── Macro Field ───────────────────────────────────────────────────
class _MacroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  const _MacroField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.jetBrainsMono(
          fontSize: 13, color: AppColors.primaryDark),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'g',
        prefixIcon: Icon(icon, size: 16, color: color),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        labelStyle: GoogleFonts.inter(
            fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Food Library Sheet ────────────────────────────────────────────
class _FoodLibrarySheet extends StatefulWidget {
  final String userId;
  final ValueChanged<SavedFoodModel> onSelected;
  const _FoodLibrarySheet(
      {required this.userId, required this.onSelected});

  @override
  State<_FoodLibrarySheet> createState() => _FoodLibrarySheetState();
}

class _FoodLibrarySheetState extends State<_FoodLibrarySheet> {
  final _searchCtrl = TextEditingController();
  final _repo = SavedFoodRepository();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bookmark_outline_rounded,
                      size: 16, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'Makanan Tersimpan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.primaryDark),
              decoration: InputDecoration(
                hintText: 'Cari makanan...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textSecondary),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 46),
              ),
              onChanged: (v) =>
                  setState(() => _query = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 0),
          Expanded(
            child: StreamBuilder<List<SavedFoodModel>>(
              stream: _repo.watchSavedFoods(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LibraryError(
                      message: snapshot.error.toString());
                }

                final foods = (snapshot.data ?? [])
                    .where((f) =>
                        _query.isEmpty ||
                        f.foodName.toLowerCase().contains(_query))
                    .toList();

                if (foods.isEmpty) {
                  return _LibraryEmpty(hasQuery: _query.isNotEmpty);
                }

                return ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: foods.length,
                  separatorBuilder: (context, i) =>
                      const Divider(height: 0, indent: 56),
                  itemBuilder: (context, i) {
                    final food = foods[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: food.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: food.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => _SavedFoodPlaceholder(),
                                errorWidget: (context, url, err) => _SavedFoodPlaceholder(),
                              )
                            : _SavedFoodPlaceholder(),
                      ),
                      title: Text(
                        food.foodName,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark),
                      ),
                      subtitle: Text(
                        '${food.caloriesPerServing} kkal / porsi',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20, color: AppColors.textSecondary),
                      onTap: () {
                        widget.onSelected(food);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedFoodPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.restaurant_outlined,
          size: 18, color: AppColors.primary),
    );
  }
}

class _LibraryEmpty extends StatelessWidget {
  final bool hasQuery;
  const _LibraryEmpty({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              hasQuery ? 'Tidak ditemukan' : 'Belum ada makanan tersimpan',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark),
              textAlign: TextAlign.center,
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 6),
              Text(
                'Scan makanan dulu untuk menyimpannya ke koleksi',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  final String message;
  const _LibraryError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 40, color: AppColors.error),
            const SizedBox(height: 10),
            Text(
              'Gagal memuat koleksi makanan',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
