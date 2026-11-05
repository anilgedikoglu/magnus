// lib/presentation/tarot/deck_deal.dart
//
// Destenin açılış dağıtımı (2026-11-06, Grok/Codex: "kartlar ekranda hazır bekliyor,
// karıştırma/dağıtma anı yok"). Ekran açılınca bütün kartlar soldaki tek bir destede
// durur, sonra soldan sağa sırayla yelpaze gibi açılır; açılırken hafif tık titreşimleri.
// Azaltılmış harekette dağıtma yok (kartlar hemen yerinde).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeckDeal {
  DeckDeal(TickerProvider vsync)
      : ctrl = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 1300)) {
    ctrl.addListener(_tick);
  }

  final AnimationController ctrl;
  static const _ticks = 7;
  int _ticked = 0;

  /// Kart [i]'nin dağıtım ilerlemesi (0 destede → 1 yerinde). İlk ~14 kart sırayla
  /// gecikir (ekranın dışında kalanlar 14. kartla birlikte gelir).
  static double progress(int i, double t) {
    final d = 0.45 * math.min(i, 14) / 14;
    return Curves.easeOutCubic.transform(((t - d) / 0.55).clamp(0.0, 1.0));
  }

  /// İlk karede çağır: azaltılmış harekette hemen bitir, değilse dağıt.
  void start(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      ctrl.value = 1;
    } else {
      ctrl.forward(from: 0);
    }
  }

  bool get dealing => ctrl.isAnimating;

  double left(int i, double overlap) => i * overlap * progress(i, ctrl.value);

  void _tick() {
    final k = (ctrl.value * _ticks).floor();
    if (k > _ticked && k < _ticks) {
      _ticked = k;
      HapticFeedback.selectionClick();
    }
  }

  void dispose() => ctrl.dispose();
}
