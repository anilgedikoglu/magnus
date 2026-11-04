import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ═══ 2026-11 "GECE GRİMUARI" TASARIM SİSTEMİ ═══════════════════════════════
  // Anıl: "daha az renkli, ciddi, ürpertici, koyu, liquid glass". Yön: gece kapanmış
  // bir gözlemevinin okuma odası — mürekkep siyahı, isli cam, kemik beyazı, TEK mum
  // altını (Codex denetimi + sanat yönetmeni sentezi). Ayrıntı: CLAUDE.md "GECE GRİMUARI".
  // KURAL: Yeni ekran/öğe bu tokenları kullanır; neon (FF55FF, FF44FF, DD00EE, 00E5FF,
  // 44FF88, FFE800…) YOK. Renk yalnız dokunulunca / kader "hazır" olunca gelir.
  static const Color ink = Color(0xFF07080B); //         mürekkep — ana zemin
  static const Color inkSurface = Color(0xFF111216); //  is — sheet / dialog / iz tabanı
  static const Color inkCard = Color(0xFF17181C); //     opak kart tabanı
  static const Color inkRaised = Color(0xFF202126); //   seçili nötr yüzey
  static const Color bone = Color(0xFFE8E2D6); //        kemik — birincil metin (saf beyaz YOK)
  static const Color boneDim = Color(0xFFB8B3A9); //     ikincil metin
  static const Color ash = Color(0xFF8D8A93); //         kül — etiket/meta/pasif (5.9:1)
  static const Color gold = Color(0xFFC2A46B); //        mum altını — TEK ana vurgu (8.4:1)
  static const Color silver = Color(0xFF939EAD); //      soğuk gümüş — ikincil kozmik detay
  static const Color success = Color(0xFF7FAF8E); //     hazır (Anıl: "yeşil badge yeterli")
  static const Color warning = Color(0xFFC9A26A); //     bekleme
  static const Color danger = Color(0xFFC98A86); //      hata / silme METNİ (okunur gül)
  static const Color blood = Color(0xFFA8443D); //       kurumuş kan — yıkıcı eylem kenarı,
  //                                                     düşük değer barı; KÜÇÜK METİNDE YOK (3.4:1)
  static const Color dangerSurface = Color(0xFF3A2224);
  static const Color rim = Color(0x29E8E2D6); //         nötr cam kenarı (kemik %16)
  // Cam: alt barla aynı #1C1C1E ailesi (tek cam dili). Kart %62, seçili %70, okuma %94.
  static const Color glassTint = Color(0x9E1C1C1E);
  static const Color glassTintSelected = Color(0xB3242428);
  static const Color glassTintReading = Color(0xF01C1C1E);

  // ─── App background ──────────────────────────────────────────────────────
  // (Eski: koyu mor #0D0A20 / #140D46 / #1A1040 → Gece Grimuarı kömürü)
  static const Color background = ink;
  static const Color backgroundSurface = inkSurface;
  static const Color backgroundCard = inkCard;

  // ─── Bubble gradients (from Unity BubbleColor.asset) ─────────────────────
  // Color1: Purple → Blue → Teal
  static const List<Color> bubble1 = [
    Color(0xFF4835A6), // #4835A6  rgba(0.282,0.208,0.596)
    Color(0xFF3A86CA), // #3A86CA  rgba(0.228,0.525,0.792)
    Color(0xFF2DAAA0), // #2DAAA0  rgba(0.180,0.670,0.597) — fades to transparent
  ];
  static const Color bubbleFrame1 = Color(0xFFFF00DD); // Hot Pink

  // Color2: Dark Brown / Gold
  static const List<Color> bubble2 = [
    Color(0xFF65420C), // rgba(0.396,0.258,0.047)
    Color(0xFF652D0C), // rgba(0.396,0.176,0.047)
  ];
  static const Color bubbleFrame2 = Color(0xFF2D2DFF); // Deep Blue

  // Color3: Near-black Dark Purple (flat)
  static const List<Color> bubble3 = [
    Color(0xFF140D46), // rgba(0.078,0.048,0.275)
    Color(0xFF130C46),
  ];
  static const Color bubbleFrame3 = Color(0xFF00FF00); // Lime Green

  // Color4: Hot Pink (semi-transparent)
  static const List<Color> bubble4 = [
    Color(0xFFFF00AF), // rgba(1,0,0.686)
    Color(0x00FF00AF), // fades to transparent
  ];
  static const Color bubbleFrame4 = Color(0xFFC80000); // Dark Red

  // Color5: Olive Green → Blue → Cyan
  static const List<Color> bubble5 = [
    Color(0xFF7F9835), // rgba(0.498,0.596,0.208)
    Color(0xFF3A86CA), // rgba(0.228,0.525,0.792)
    Color(0xFF2DAAA0), // rgba(0.180,0.670,0.597)
  ];
  static const Color bubbleFrame5 = Color(0xFFFFFF00); // Yellow

  // Default bubble used for Magnus (Color1)
  static List<Color> get magnusBubble => bubble1;

  // ─── Glow effect colors ───────────────────────────────────────────────────
  static const Color glowRed = Color(0xFFE02E2E);
  static const Color glowOrange = Color(0xFFE0692D);
  static const Color glowPurple = Color(0xFFBD2DE0);
  static const Color glowGreen = Color(0xFF67E047);
  static const Color glowBlue = Color(0xFF2D75E0);

  // ─── Text colors ──────────────────────────────────────────────────────────
  static const Color textPrimary = bone; // eski: saf beyaz
  static const Color textSecondary = boneDim;
  static const Color textMuted = ash;
  static const Color textOnLight = Color(0xFF1A1040);

  // ─── Answer bubble ────────────────────────────────────────────────────────
  static const Color answerBubbleBorder = rim; // eski: mor
  static const Color answerBubbleFill = glassTint; // eski: mor alpha

  // ─── UI elements ─────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF30343C);
  static const Color inputBackground = Color(0xFF101319);
  static const Color navBarBackground = inkSurface;
  static const Color navBarActive = bone;
  static const Color navBarInactive = ash;

  // ─── Inbox ────────────────────────────────────────────────────────────────
  static const Color inboxUnread = gold;
  static const Color inboxRead = ash;
  static const Color inboxDeleteBackground = dangerSurface;

  // ─── Planet / astrology accent (from Unity: #F57C00) ─────────────────────
  static const Color astroAccent = Color(0xFFF57C00);
  static const Color astroInner = Color(0xFFFCFF96);
}
