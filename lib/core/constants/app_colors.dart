import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ═══ 2026-11-05: RENKLER ESKİ PALETE DÖNDÜ (Anıl: "yeni renklendirmeyi sevmedim,
  // renklendirmede eskiye dön"; yapı/yerleşim — cam kartlar, Mühürlü, çizgi ikonlar — KALDI).
  // Gece Grimuarı token ADLARI korunur (tüm yeni bileşenler bunları kullanıyor), DEĞERLER
  // eski neon/mor uygulamanın paletinden: koyu lacivert-mor zemin, beyaz metin, pembe vurgu
  // (#FF55FF — eski parıltı/çerçeve rengi), camgöbeği ikincil, neon yeşil "hazır".
  static const Color ink = Color(0xFF0D0A20); //         eski background
  static const Color inkSurface = Color(0xFF140D46); //  eski backgroundSurface
  static const Color inkCard = Color(0xFF1A1040); //     eski backgroundCard
  static const Color inkRaised = Color(0xFF241760); //   seçili yüzey (mor)
  static const Color bone = Color(0xFFFFFFFF); //        birincil metin (eski: saf beyaz)
  static const Color boneDim = Color(0xFFCCCCCC); //     eski textSecondary
  static const Color ash = Color(0xFF9E98BE); //         etiket/meta/pasif (lavanta gri)
  static const Color gold = Color(0xFFFF55FF); //        ana vurgu — eski pembe parıltı
  static const Color silver = Color(0xFF00CCFF); //      ikincil — eski camgöbeği
  static const Color success = Color(0xFF44FF88); //     hazır — eski neon yeşil
  static const Color warning = Color(0xFFE0692D); //     bekleme — eski glowOrange
  static const Color danger = Color(0xFFFF4466); //      hata / silme metni
  static const Color blood = Color(0xFFC80000); //       yıkıcı eylem — eski koyu kırmızı
  static const Color dangerSurface = Color(0xFF4A0012);
  static const Color rim = Color(0x5C7B5ECC); //         kart/cam kenarı — eski mor çerçeve %36
  // Cam: eski mor kart tabanı (#1A1040) — kart %62, seçili %70, okuma %94.
  static const Color glassTint = Color(0x9E1A1040);
  static const Color glassTintSelected = Color(0xB32A1F5E);
  static const Color glassTintReading = Color(0xF0140D46);

  // ─── App background ──────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0A20);
  static const Color backgroundSurface = Color(0xFF140D46);
  static const Color backgroundCard = Color(0xFF1A1040);

  // ─── Unity balon paleti (BubbleColor.asset) — ESKİ DEĞERLER ─────────────────
  static const List<Color> bubble1 = [
    Color(0xFF4835A6), // #4835A6  rgba(0.282,0.208,0.596)
    Color(0xFF3A86CA), // #3A86CA  rgba(0.228,0.525,0.792)
    Color(0xFF2DAAA0), // #2DAAA0  rgba(0.180,0.670,0.597) — fades to transparent
  ];
  static const Color bubbleFrame1 = Color(0xFFFF00DD); // Hot Pink

  static const List<Color> bubble2 = [
    Color(0xFF65420C), // rgba(0.396,0.258,0.047)
    Color(0xFF652D0C), // rgba(0.396,0.176,0.047)
  ];
  static const Color bubbleFrame2 = Color(0xFF2D2DFF); // Deep Blue

  static const List<Color> bubble3 = [
    Color(0xFF140D46), // rgba(0.078,0.048,0.275)
    Color(0xFF130C46),
  ];
  static const Color bubbleFrame3 = Color(0xFF00FF00); // Lime Green

  static const List<Color> bubble4 = [
    Color(0xFFFF00AF), // rgba(1,0,0.686)
    Color(0x00FF00AF), // fades to transparent
  ];
  static const Color bubbleFrame4 = Color(0xFFC80000); // Dark Red

  static const List<Color> bubble5 = [
    Color(0xFF7F9835), // rgba(0.498,0.596,0.208)
    Color(0xFF3A86CA), // rgba(0.228,0.525,0.792)
    Color(0xFF2DAAA0), // rgba(0.180,0.670,0.597)
  ];
  static const Color bubbleFrame5 = Color(0xFFFFFF00); // Yellow

  // Default bubble used for Magnus (Color1)
  static List<Color> get magnusBubble => bubble1;

  // ─── Parıltı renkleri (eski) ────────────────────────────────────────────────
  static const Color glowRed = Color(0xFFE02E2E);
  static const Color glowOrange = Color(0xFFE0692D);
  static const Color glowPurple = Color(0xFFBD2DE0);
  static const Color glowGreen = Color(0xFF67E047);
  static const Color glowBlue = Color(0xFF2D75E0);

  // ─── Text colors ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFF888888);
  static const Color textOnLight = Color(0xFF1A1040);

  // ─── Answer bubble ────────────────────────────────────────────────────────
  static const Color answerBubbleBorder = Color(0xFF6B4FA0);
  static const Color answerBubbleFill = Color(0x334835A6); // Color1 with low alpha

  // ─── UI elements ─────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF2A1F5E);
  static const Color inputBackground = Color(0xFF1E1550);
  static const Color navBarBackground = Color(0xFF100B35);
  static const Color navBarActive = Color(0xFFAA88FF);
  static const Color navBarInactive = Color(0xFF555588);

  // ─── Inbox ────────────────────────────────────────────────────────────────
  static const Color inboxUnread = Color(0xFFAA88FF);
  static const Color inboxRead = Color(0xFF555577);
  static const Color inboxDeleteBackground = Color(0xFFC80000);

  // ─── Planet / astrology accent (Unity) ──────────────────────────────────────
  static const Color astroAccent = Color(0xFFF57C00);
  static const Color astroInner = Color(0xFFFCFF96);
}
