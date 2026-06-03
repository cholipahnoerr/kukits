import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    // Save to food library for future use
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil disimpan ke log nutrisi!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.scanState.result;
    final image = widget.scanState.imageFile;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Scan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.foodName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Estimasi: ${result.portion}',
                    style:
                        const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NutrientBadge(
                        label: 'Kalori',
                        value: '${result.calories}',
                        unit: 'kkal',
                        color: AppColors.primary,
                      ),
                      _NutrientBadge(
                        label: 'Protein',
                        value: result.protein.toStringAsFixed(1),
                        unit: 'g',
                        color: Colors.blue,
                      ),
                      _NutrientBadge(
                        label: 'Karbo',
                        value: result.carbs.toStringAsFixed(1),
                        unit: 'g',
                        color: Colors.orange,
                      ),
                      _NutrientBadge(
                        label: 'Lemak',
                        value: result.fat.toStringAsFixed(1),
                        unit: 'g',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_saved) ...[
            DropdownButtonFormField<String>(
              value: _mealType,
              decoration: const InputDecoration(
                labelText: 'Simpan sebagai',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'sarapan', child: Text('Sarapan')),
                DropdownMenuItem(
                    value: 'makan_siang', child: Text('Makan Siang')),
                DropdownMenuItem(
                    value: 'makan_malam', child: Text('Makan Malam')),
                DropdownMenuItem(value: 'snack', child: Text('Snack')),
              ],
              onChanged: (v) => setState(() => _mealType = v!),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saveToLog,
              child: const Text('Simpan ke Log Nutrisi'),
            ),
          ] else
            Card(
              color: AppColors.primary,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Tersimpan ke log nutrisi!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
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

class _NutrientBadge extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutrientBadge({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(unit, style: TextStyle(fontSize: 11, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
