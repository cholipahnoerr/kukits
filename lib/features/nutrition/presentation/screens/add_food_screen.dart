import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final FoodLogModel? existing; // non-null = edit mode
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
      // Show per-serving values in the fields
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

  String _fmt(double v) =>
      v == 0 ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1));

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
      protein: double.parse(
          (baseProtein * _servings).toStringAsFixed(1)),
      carbs:
          double.parse((baseCarbs * _servings).toStringAsFixed(1)),
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
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Makanan' : 'Tambah Makanan'),
        actions: [
          if (!_isEdit)
            TextButton.icon(
              onPressed: _pickFromLibrary,
              icon: const Icon(Icons.bookmark_outline, size: 18),
              label: const Text('Tersimpan'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nama Makanan *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mealType,
              decoration:
                  const InputDecoration(labelText: 'Waktu Makan'),
              items: const [
                DropdownMenuItem(
                    value: 'sarapan', child: Text('Sarapan')),
                DropdownMenuItem(
                    value: 'makan_siang', child: Text('Makan Siang')),
                DropdownMenuItem(
                    value: 'makan_malam', child: Text('Makan Malam')),
                DropdownMenuItem(value: 'snack', child: Text('Snack')),
              ],
              onChanged: (v) => setState(() => _mealType = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caloriesCtrl,
              decoration: const InputDecoration(
                labelText: 'Kalori per porsi *',
                suffixText: 'kkal',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if (int.tryParse(v) == null) return 'Harus angka';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Servings stepper
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Jumlah Porsi',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
                _ServingStepper(
                  value: _servings,
                  onChanged: (v) => setState(() => _servings = v),
                ),
              ],
            ),
            if (_caloriesCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Total: $_totalCalories kkal',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              'Makronutrisi per porsi (opsional)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Protein', suffixText: 'g'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _carbsCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Karbo', suffixText: 'g'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _fatCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Lemak', suffixText: 'g'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServingStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ServingStepper(
      {required this.value, required this.onChanged});

  String get _label => value == value.roundToDouble()
      ? '${value.toInt()} porsi'
      : '$value porsi';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > 0.5
              ? () => onChanged(
                  double.parse((value - 0.5).toStringAsFixed(1)))
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primary,
        ),
        SizedBox(
          width: 72,
          child: Text(
            _label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        IconButton(
          onPressed: value < 10
              ? () => onChanged(
                  double.parse((value + 0.5).toStringAsFixed(1)))
              : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

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
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari makanan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SavedFoodModel>>(
              stream: _repo.watchSavedFoods(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_outlined,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 8),
                          const Text(
                            'Gagal memuat koleksi makanan.\nPastikan Firestore sudah dikonfigurasi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final foods = (snapshot.data ?? [])
                    .where((f) =>
                        _query.isEmpty ||
                        f.foodName
                            .toLowerCase()
                            .contains(_query))
                    .toList();

                if (foods.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_border,
                            size: 48,
                            color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          _query.isEmpty
                              ? 'Belum ada makanan tersimpan.\nScan makanan dulu untuk menyimpannya.'
                              : 'Tidak ditemukan',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: foods.length,
                  itemBuilder: (context, i) {
                    final food = foods[i];
                    return ListTile(
                      title: Text(food.foodName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        '${food.caloriesPerServing} kkal/porsi',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
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
