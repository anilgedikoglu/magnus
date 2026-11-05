// lib/core/widgets/glass_tint.dart
//
// Cam alt barın saydamlık ayarı (Anıl, 2026-11-05: "transparensi miktarı bu ayar videosunun
// ortasındaki kadar olsun; ayarlardan alt kompartmanın transparensisi aynen bu efektle, bu
// oranlarda değişebilsin"). iOS 26 Liquid Glass "Şeffaf ↔ Renkli" kaydırıcısının ekran
// kaydından ÖLÇÜLDÜ (Haritalar arama alanı, 30 fps, 13 nokta):
//   • Her karede cam içi = k·(en şeffaf hâl) + c (en küçük kareler, R²≈1).
//   • En şeffaf hâlin kendisi arkaya göre: 0.61·arka + 45 (cam içi/dışı yazı parlaklığından).
//   • Mutlak: geçirgenlik k_abs = 0.61·k, eklenen ışık c_abs = 45·k + c →
//     tint opaklığı α = 1 − k_abs, tint gri seviyesi = c_abs / α.
// Gidişat (opaklık): 0 (şeffaf) α 0.39 → 0.5 α 0.75 → 1 (renkli) α 0.95.
//
// 2026-11-05 gece (Anıl: "tam aynısı değilse önce onu aynısı yap"; Codex: "bizim merkez açık
// gri, Instagram koyu"): ORAN iOS kaydırıcısından, camın RENGİ Instagram barından ölçüldü
// (iki ekran görüntüsü, gri zemin + bordo panel: cam = 0.20·arka + (12, 13, 16.5) →
// α 0.80, tint (15, 16, 21)). Varsayılan ortada sonuç: 0.25·arka + (11, 12, 16) ≈ Instagram.

import 'package:flutter/painting.dart';

/// Varsayılan: kaydırıcının ortası (videodaki ortadaki hâl).
const double kGlassTintDefault = 0.5;

/// (kaydırıcı, k göreli, c göreli) — videodan ölçülen noktalar.
const List<(double, double, double)> _kTable = [
  (0.00, 1.000, 0.0),
  (0.10, 0.925, 4.8),
  (0.16, 0.844, 10.1),
  (0.24, 0.722, 18.4),
  (0.32, 0.615, 25.7),
  (0.43, 0.477, 35.4),
  (0.51, 0.407, 40.6),
  (0.60, 0.317, 40.5),
  (0.67, 0.254, 41.1),
  (0.74, 0.202, 41.7),
  (0.81, 0.157, 42.4),
  (0.89, 0.110, 43.6),
  (1.00, 0.090, 43.9),
];

const double _kClearTransmit = 0.61;

/// Instagram iOS 26 barının cam rengi (ölçüm: c / α = (12, 13, 16.5) / 0.80).
const (int, int, int) _kTint = (15, 16, 21);

/// Kaydırıcı değeri (0 şeffaf … 1 renkli) → camın tint rengi (alfa = opaklık).
Color glassTintColor(double value) {
  final s = value.clamp(0.0, 1.0);
  var i = 0;
  while (i < _kTable.length - 2 && s > _kTable[i + 1].$1) {
    i++;
  }
  final (s0, k0, c0) = _kTable[i];
  final (s1, k1, c1) = _kTable[i + 1];
  final t = s1 == s0 ? 0.0 : (s - s0) / (s1 - s0);
  final k = k0 + (k1 - k0) * t;
  final c = c0 + (c1 - c0) * t;
  final transmit = _kClearTransmit * k;
  final alpha = 1 - transmit;
  // Renk: Instagram camı (koyu, hafif soğuk). c (iOS'un eklediği ışık) yalnız oranı kurar.
  assert(c >= 0);
  return Color.fromARGB((alpha * 255).round(), _kTint.$1, _kTint.$2, _kTint.$3);
}
