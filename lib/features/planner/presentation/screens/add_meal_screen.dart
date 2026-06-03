import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/meal_plan_model.dart';
import '../bloc/planner_bloc.dart';
import '../bloc/planner_event.dart';

class AddMealScreen extends StatefulWidget {
  final String date;
  const AddMealScreen({super.key, required this.date});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _menuCtrl = TextEditingController();
  String _mealType = 'sarapan';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  void dispose() {
    _menuCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    final timeStr =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    final plan = MealPlanModel(
      id: const Uuid().v4(),
      userId: auth.user.uid,
      date: widget.date,
      mealType: _mealType,
      menuName: _menuCtrl.text.trim(),
      reminderTime: timeStr,
      createdAt: DateTime.now(),
    );

    context.read<PlannerBloc>().add(PlannerAddMeal(plan));
    Navigator.pop(context);
  }

  String _formatDate(String date) {
    final d = DateTime.parse(date);
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Rencana Makan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tanggal: ${_formatDate(widget.date)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _menuCtrl,
              decoration: const InputDecoration(labelText: 'Nama Menu *'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mealType,
              decoration: const InputDecoration(labelText: 'Waktu Makan'),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Waktu Pengingat'),
              subtitle: Text(
                '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              trailing: TextButton(
                onPressed: _pickTime,
                child: const Text('Ubah'),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
