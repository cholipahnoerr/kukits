import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
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
    _caloriesCtrl = TextEditingController(text: '${user?.nutritionTarget.calories ?? 2000}');
    _proteinCtrl = TextEditingController(text: '${user?.nutritionTarget.protein ?? 60}');
    _carbsCtrl = TextEditingController(text: '${user?.nutritionTarget.carbs ?? 250}');
    _fatCtrl = TextEditingController(text: '${user?.nutritionTarget.fat ?? 65}');
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

  Future<void> _save(UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final newTarget = NutritionTarget(
      calories: int.tryParse(_caloriesCtrl.text) ?? 2000,
      protein: int.tryParse(_proteinCtrl.text) ?? 60,
      carbs: int.tryParse(_carbsCtrl.text) ?? 250,
      fat: int.tryParse(_fatCtrl.text) ?? 65,
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'nutritionTarget': newTarget.toMap(),
      });
      if (mounted) {
        context.read<AuthBloc>().add(AuthUserUpdated(
              currentUser.copyWith(
                name: _nameCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                address: _addressCtrl.text.trim(),
                nutritionTarget: newTarget,
              ),
            ));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil berhasil disimpan')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = state.user;
          return Column(
            children: [
              _TopBar(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _AvatarSection(user: user),
                      const SizedBox(height: 20),
                      _FormCard(
                        step: '1',
                        title: 'Informasi Pribadi',
                        children: [
                          CustomTextField(
                            label: 'Nama Lengkap',
                            controller: _nameCtrl,
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            validator: Validators.required,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Nomor HP',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Alamat',
                            controller: _addressCtrl,
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FormCard(
                        step: '2',
                        title: 'Target Nutrisi Harian',
                        children: [
                          CustomTextField(
                            label: 'Kalori (kkal)',
                            controller: _caloriesCtrl,
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.local_fire_department_outlined, size: 20),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Protein (g)',
                                  controller: _proteinCtrl,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.fitness_center_rounded, size: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Karbo (g)',
                                  controller: _carbsCtrl,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.grain_rounded, size: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Lemak (g)',
                                  controller: _fatCtrl,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.water_drop_outlined, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _NutritionHint(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : () => _save(user),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            'Simpan Perubahan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profil',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Perbarui informasi akunmu',
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
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final UserModel user;
  const _AvatarSection({required this.user});

  String get _initials {
    final parts = user.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
            ),
            child: ClipOval(
              child: user.photoUrl != null
                  ? Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Fallback(initials: _initials),
                    )
                  : _Fallback(initials: _initials),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final String initials;
  const _Fallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String step;
  final String title;
  final List<Widget> children;
  const _FormCard({required this.step, required this.title, required this.children});

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
      padding: const EdgeInsets.all(16),
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
                      fontSize: 13,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 0),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _NutritionHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, size: 15, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nilai default: 2000 kkal · 60g protein · 250g karbo · 65g lemak',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.primaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
