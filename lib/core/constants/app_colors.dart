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

  // ─── Eski Unity balon paleti (BubbleColor.asset) — 2026-11 Gece Grimuarı eşlemesi ──
  // Adlar korunur (onboarding sohbeti, tarot seçimleri, astroloji butonları kullanıyor);
  // DEĞERLER artık koyu cam + tek vurgu. Eski değerler: mor→mavi→teal #4835A6/#3A86CA/
  // #2DAAA0 + pembe çerçeve #FF00DD; kahve #65420C; mor #140D46; pembe #FF00AF; zeytin
  // #7F9835. Gövde = cam gradyanı, çerçeve = seçim/odak rengi (çoğunlukla mum altını).
  static const List<Color> bubble1 = [
    Color(0xFF2A2A2F),
    Color(0xFF222226),
    Color(0xFF1C1C1F),
  ];
  static const Color bubbleFrame1 = gold;

  static const List<Color> bubble2 = [Color(0xFF2A241B), Color(0xFF221D16)]; // sıcak is
  static const Color bubbleFrame2 = Color(0xFF8C8578);

  static const List<Color> bubble3 = [inkCard, inkSurface];
  static const Color bubbleFrame3 = Color(0xFF8C8578);

  static const List<Color> bubble4 = [Color(0xFF2A2024), Color(0x002A2024)]; // kan isi
  static const Color bubbleFrame4 = blood;

  static const List<Color> bubble5 = [
    Color(0xFF24262A),
    Color(0xFF1E2024),
    Color(0xFF1A1B1E),
  ];
  static const Color bubbleFrame5 = silver;

  // Default bubble used for Magnus (Color1)
  static List<Color> get magnusBubble => bubble1;

  // ─── Eski parıltı renkleri → anlamlı tokenlar (neon yok) ────────────────────
  static const Color glowRed = blood;
  static const Color glowOrange = warning;
  static const Color glowPurple = silver;
  static const Color glowGreen = success;
  static const Color glowBlue = silver;

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

  // ─── Planet / astrology accent (eski Unity: #F57C00 / #FCFF96 → altın ailesi) ─────
  static const Color astroAccent = gold;
  static const Color astroInner = Color(0xFFE8D6A8);
}
