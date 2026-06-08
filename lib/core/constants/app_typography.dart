import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Plus Jakarta Sans — judul, nama produk, angka besar
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Inter — deskripsi, label, body
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  // JetBrains Mono — angka nutrisi (kalori, protein, karbohidrat, lemak)
  static TextStyle get nutriValue => GoogleFonts.jetBrainsMono(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      );

  static TextStyle get nutriValueSmall => GoogleFonts.jetBrainsMono(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      );

  static TextStyle get nutriLabel => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );
}