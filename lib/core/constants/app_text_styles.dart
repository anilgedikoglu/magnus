import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Magnus chat bubbles (Nunito — matches app theme, clean & legible) ─────
  static TextStyle get bubbleText => GoogleFonts.nunito(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.6,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bubbleTextSmall => GoogleFonts.nunito(
        fontSize: 13,
        color: AppColors.textPrimary,
        height: 1.6,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get answerText => GoogleFonts.nunito(
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.3,
        fontWeight: FontWeight.w600,
      );

  // ─── Magnus name / branding (AngillaTattoo) ───────────────────────────────
  static const TextStyle magnusLabel = TextStyle(
    fontFamily: 'AngillaTattoo',
    fontSize: 14,
    color: AppColors.navBarActive,
    letterSpacing: 1.2,
  );

  // ─── Screen titles (Cinzel — elegant, mystical serif) ─────────────────────
  static TextStyle get title => GoogleFonts.cinzel(
        fontSize: 22,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get onboardingQuestion => GoogleFonts.cinzel(
        fontSize: 17,
        color: AppColors.textPrimary,
        height: 1.6,
        fontWeight: FontWeight.w500,
      );

  // ─── UI text (Nunito — clean, rounded, highly legible) ───────────────────
  static TextStyle get inboxTitle => GoogleFonts.nunito(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      );

  static TextStyle get inboxDescription => GoogleFonts.nunito(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.6,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get inboxMeta => GoogleFonts.nunito(
        fontSize: 11,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w500,
      );

  // ─── Fortune card content (Raleway — elegant, full Turkish support) ──────
  static TextStyle get cardText => GoogleFonts.raleway(
        fontSize: 17,
        color: AppColors.textPrimary,
        height: 1.85,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  // Helper: pick bubble text style by length (matches Unity logic)
  static TextStyle bubbleTextForLength(int length) {
    return length > 400 ? bubbleTextSmall : bubbleText;
  }
}
