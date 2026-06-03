import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthRegisterRequested(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(RouteNames.home);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Buat Akun Baru',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bergabung dengan komunitas gaya hidup sehat',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: AppStrings.fullName,
                      controller: _nameCtrl,
                      prefixIcon: const Icon(Icons.person_outlined),
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: AppStrings.email,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: AppStrings.password,
                      controller: _passwordCtrl,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: AppStrings.confirmPassword,
                      controller: _confirmCtrl,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      validator: (_) =>
                          Validators.confirmPassword(_passwordCtrl.text)(_confirmCtrl.text),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      label: AppStrings.register,
                      isLoading: state is AuthLoading,
                      onPressed: () => _submit(context),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.hasAccount),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Text(
                            AppStrings.login,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}