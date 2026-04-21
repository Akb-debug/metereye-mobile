import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary       = Color(0xFF2563EB); // bleu
  static const Color secondary     = Color(0xFF10B981); // vert
  static const Color background    = Color(0xFFF0F4F8); // fond général
  static const Color surface       = Color(0xFFFFFFFF); // cartes
  static const Color alertRed      = Color(0xFFEF4444);
  static const Color alertOrange   = Color(0xFFF59E0B);
  static const Color alertGreen    = Color(0xFF10B981);
  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor   = Color(0xFFE2E8F0);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.nunito(
    fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static TextStyle heading2 = GoogleFonts.nunito(
    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle body = GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle caption = GoogleFonts.nunito(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}

class AppTheme {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 2),
      )
    ],
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.background,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
      hintStyle: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary.withOpacity(0.5)),
    ),
  );
}
