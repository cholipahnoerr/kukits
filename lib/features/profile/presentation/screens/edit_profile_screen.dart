import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _caloriesCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    final user = state is AuthAuthenticated ? state.user : null;

    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _caloriesCtrl = TextEditingController(
        text: user?.nutritionTarget.calories.toString() ?? '2000');
    _proteinCtrl = TextEditingController(
        text: user?.nutritionTarget.protein.toString() ?? '60');
    _carbsCtrl = TextEditingController(
        text: user?.nutritionTarget.carbs.toString() ?? '250');
    _fatCtrl = TextEditingController(
        text: user?.nutritionTarget.fat.toString() ?? '65');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'nutritionTarget': NutritionTarget(
          calories: int.tryParse(_caloriesCtrl.text) ?? 2000,
          protein: int.tryParse(_proteinCtrl.text) ?? 60,
          carbs: int.tryParse(_carbsCtrl.text) ?? 250,
          fat: int.tryParse(_fatCtrl.text) ?? 65,
        ).toMap(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle('Informasi Pribadi'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Nama Lengkap',
                    controller: _nameCtrl,
                    prefixIcon: const Icon(Icons.person_outlined),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Nomor HP',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Alamat',
                    controller: _addressCtrl,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Target Nutrisi Harian'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Kalori (kkal)',
                          controller: _caloriesCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Protein (g)',
                          controller: _proteinCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Karbo (g)',
                          controller: _carbsCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Lemak (g)',
                          controller: _fatCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    label: 'Simpan Perubahan',
                    isLoading: _isSaving,
                    onPressed: () => _save(state.user.uid),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }
}