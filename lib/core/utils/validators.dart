import '../constants/app_strings.dart';

class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return AppStrings.emailInvalid;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 6) return AppStrings.passwordMin;
    return null;
  }

  static String? Function(String?) confirmPassword(String? original) {
    return (value) {
      if (value == null || value.isEmpty) return AppStrings.fieldRequired;
      if (value != original) return AppStrings.passwordMismatch;
      return null;
    };
  }
}