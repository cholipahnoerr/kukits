import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/meal_plan_model.dart';
import '../bloc/planner_bloc.dart';
import '../bloc/planner_event.dart';

class AddMealScreen extends StatefulWidget {
  final String date;
  final MealPlanModel? editPlan;
  const AddMealScreen({super.key, required this.date, this.editPlan});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _menuCtrl;
  late String _mealType;
  late TimeOfDay _reminderTime;

  bool get _isEdit => widget.editPlan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.editPlan;
    _menuCtrl = TextEditingController(text: plan?.menuName ?? '');
    _mealType = plan?.mealType ?? 'sarapan';
    if (plan != null) {
      final parts = plan.reminderTime.split(':');
      _reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      _reminderTime = const TimeOfDay(hour: 7, minute: 0);
    }
  }

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

    if (_isEdit) {
      final updated = widget.editPlan!.copyWith(
        menuName: _menuCtrl.text.trim(),
        mealType: _mealType,
        reminderTime: timeStr,
      );
      context.read<PlannerBloc>().add(PlannerUpdateMeal(updated));
    } else {
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
    }
    Navigator.pop(context);
  }

  String _formatDate(String date) {
    final d = DateTime.parse(date);
    const months = [
      '',
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopBar(date: _formatDate(widget.date), isEdit: _isEdit),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Menu name card
                  _FormCard(
                    step: '1',
                    title: 'Nama Menu',
                    child: TextFormField(
                      controller: _menuCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.primaryDark),
                      decoration: InputDecoration(
                        labelText: 'Nama makanan / menu',
                        prefixIcon: const Icon(Icons.restaurant_menu_outlined,
                            size: 18, color: AppColors.textSecondary),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 46),
                        labelStyle: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Meal type card
                  _FormCard(
                    step: '2',
                    title: 'Waktu Makan',
                    child: _MealTypePicker(
                      selected: _mealType,
                      onChanged: (v) => setState(() => _mealType = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Reminder time card
                  _FormCard(
                    step: '3',
                    title: 'Waktu Pengingat',
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.alarm_rounded,
                                  size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengingat makan',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                'Ubah',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isEdit ? 'Simpan Perubahan' : 'Simpan Rencana',
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
  final String date;
  final bool isEdit;
  const _TopBar({required this.date, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
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
                      isEdit ? 'Edit Rencana Makan' : 'Tambah Rencana Makan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
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
  final Widget child;
  const _FormCard(
      {required this.step, required this.title, required this.child});

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
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 0),
          const SizedBox(height: 14),
          child,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.background,
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
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
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
