
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Gövde: Inter (2026-11: Nunito yuvarlak/oyuncu → ciddi, okunur; latin-ext Türkçe) ─
  static TextStyle get bubbleText => GoogleFonts.ebGaramond(
        fontSize: 17,
        color: AppColors.textPrimary,
        height: 1.6,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bubbleTextSmall => GoogleFonts.ebGaramond(
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.6,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get answerText => GoogleFonts.jost(
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

  // ─── UI metni (Inter) ──────────────────────────────────────────────────────
  static TextStyle get inboxTitle => GoogleFonts.jost(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      );

  static TextStyle get inboxDescription => GoogleFonts.jost(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.6,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get inboxMeta => GoogleFonts.jost(
        fontSize: 11,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w500,
      );

  // ─── Fal okuma metni (EB Garamond — grimuar; koyu zeminde 500 ağırlık parlamasın) ─
  static TextStyle get cardText => GoogleFonts.ebGaramond(
        fontSize: 17,
        color: AppColors.textPrimary.withValues(alpha: 0.92),
        height: 1.55,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      );

  // ═══ 2026-11 GECE GRİMUARI tipografi ölçeği (sanat yönetmeni + Codex) ═══════
  // Cinzel YALNIZ başlık / kart etiketi / donut etiketi (12dp altı ve gövdede YOK).
  // Cinzel küçük harfleri kapitalik çizer → metni karışık harfle yaz; toUpperCase()
  // KULLANMA (Türkçe i/İ'yi bozar). UI: Jost. Uzun okuma: EB Garamond.

  /// Ekran başlığı — Cinzel 18 w600, harf aralığı 3, kemik.
  static TextStyle get screenTitle => GoogleFonts.cinzel(
        fontSize: 18, color: AppColors.bone, fontWeight: FontWeight.w600, letterSpacing: 3.0);

  /// Büyük ritüel başlığı — Cinzel 26 w500.
  static TextStyle get ritualTitle => GoogleFonts.cinzel(
        fontSize: 26, color: AppColors.bone, fontWeight: FontWeight.w500,
        letterSpacing: 0.6, height: 1.2);

  /// Menü/seçim kartı etiketi — Cinzel 12.5 w600, harf aralığı 1.4.
  static TextStyle get cardLabel => GoogleFonts.cinzel(
        fontSize: 12.5, color: AppColors.bone, fontWeight: FontWeight.w600, letterSpacing: 1.4);

  /// Bölüm etiketi — Jost 11 w500, geniş aralık, kül (önüne 12px altın çizgi: OccultSectionLabel).
  static TextStyle get sectionLabel => GoogleFonts.jost(
        fontSize: 11, color: AppColors.ash, fontWeight: FontWeight.w500, letterSpacing: 2.2);

  /// Buton / UI etiketi — Jost 15 w500.
  static TextStyle get uiLabel => GoogleFonts.jost(
        fontSize: 15, color: AppColors.bone, fontWeight: FontWeight.w500, letterSpacing: 0.4);

  /// Değer (ör. profil kartı değeri) — Jost 16 w500.
  static TextStyle get value => GoogleFonts.jost(
        fontSize: 16, color: AppColors.bone, fontWeight: FontWeight.w500);

  /// Meta / tarih / yardımcı — Jost 12, kül.
  static TextStyle get meta => GoogleFonts.jost(
        fontSize: 12, color: AppColors.ash, fontWeight: FontWeight.w400, letterSpacing: 0.1);

  /// Uzun okuma (fal metni) — EB Garamond 17 w500, satır 1.55.
  static TextStyle get reading => cardText;

  /// Yüzde/tarih için sabit genişlikli rakamlar.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  // Helper: pick bubble text style by length (matches Unity logic)
  static TextStyle bubbleTextForLength(int length) {
    return length > 400 ? bubbleTextSmall : bubbleText;
  }
}
