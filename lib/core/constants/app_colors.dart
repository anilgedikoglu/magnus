import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── App background ──────────────────────────────────────────────────────
  // Unity Color3 base: #140D46 (near-black dark purple)
  static const Color background = Color(0xFF0D0A20);
  static const Color backgroundSurface = Color(0xFF140D46);
  static const Color backgroundCard = Color(0xFF1A1040);

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

  // ─── Planet / astrology accent (from Unity: #F57C00) ─────────────────────
  static const Color astroAccent = Color(0xFFF57C00);
  static const Color astroInner = Color(0xFFFCFF96);
}
