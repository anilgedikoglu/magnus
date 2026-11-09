// lib/core/widgets/bir_tane_daha.dart
//
// Sonucun sonunda "Reklam izle, bir tane daha" düğmesi (docs/reklam_duzeni.md).
// Yalnız bugünkü hak kullanılmışsa ve teklif yapılabiliyorsa görünür. Kullanıcı reklamı izleyip ödülü
// kazanırsa o türün günlük tarihi silinir ve [sonra] çalışır (varsayılan: ana menüye dönüp falı açar).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/providers.dart';
import '../services/ad_pacing.dart';
import '../services/ad_service.dart';
import 'occult_button.dart';

/// Fal ekranı bu sonuçla kapanınca ana menü aynı falı yeniden açar.
const String kBirTaneDaha = 'bir_tane_daha';

class BirTaneDaha extends ConsumerStatefulWidget {
  const BirTaneDaha({
    super.key,
    required this.falTuru,
    required this.hakAnahtari,
    this.etiket,
    this.sonra,
  });

  final String falTuru;

  /// Türün "bugün aldın" tarihini tutan prefs anahtarı.
  final String hakAnahtari;

  /// Düğme yazısı; boşsa "Reklam izle, bir tane daha".
  final String? etiket;

  final void Function(BuildContext context)? sonra;

  @override
  ConsumerState<BirTaneDaha> createState() => _BirTaneDahaState();
}

class _BirTaneDahaState extends ConsumerState<BirTaneDaha> {
  bool _hakKullanildi = false;
  bool _mesgul = false;

  @override
  void initState() {
    super.initState();
    _kontrol();
  }

  Future<void> _kontrol() async {
    final prefs = await SharedPreferences.getInstance();
    final bugun = DateTime.now().toIso8601String().substring(0, 10);
    if (mounted && prefs.getString(widget.hakAnahtari) == bugun) {
      setState(() => _hakKullanildi = true);
    }
  }

  Future<void> _dokun() async {
    if (_mesgul) return;
    final ads = AdService.instance;
    if (!ads.odulMumkun(OdulTuru.hakBitti, falTuru: widget.falTuru)) return;
    _mesgul = true;
    try {
      // Düğme eylemi ve ödülü açıkça yazıyor; ek pencere yok, reklam doğrudan başlar.
      final kazandi = await ads.showRewardedFor(OdulTuru.hakBitti, falTuru: widget.falTuru);
      if (!kazandi) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(widget.hakAnahtari); // ekran kapanmış olsa da hak verilir
      if (!mounted) return;
      final sonra = widget.sonra;
      if (sonra != null) {
        sonra(context);
      } else {
        context.pop(kBirTaneDaha);
      }
    } finally {
      _mesgul = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ads = AdService.instance;
    final s = ref.watch(l10nProvider);
    return ValueListenableBuilder<bool>(
      valueListenable: ads.odulluHazir,
      builder: (_, __, ___) {
        if (!_hakKullanildi || !ads.odulTeklifiHazir(OdulTuru.hakBitti, falTuru: widget.falTuru)) {
          return const SizedBox.shrink();
        }
        return OccultButton.secondary(
          label: widget.etiket ?? s.adOneMore,
          icon: Icons.play_arrow_rounded,
          onTap: _dokun,
        );
      },
    );
  }
}
