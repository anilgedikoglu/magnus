// lib/core/widgets/odul_teklifi.dart
//
// Ödüllü reklam teklif penceresi (docs/reklam_duzeni.md): ekranın ortasında, sıvı cam, başlık + ödülün
// açık yazısı, EŞİT iki düğme (Reklam izle / Vazgeç). Reddetmek normal kullanımı engellemez;
// metin yönlendirmez. Yalnız kullanıcı "Reklam izle" derse reklam başlar; true YALNIZ ödül
// kazanıldıysa döner (kapatma/hata/hazır değil → false).
//
// Azaltılmış hareket: pencere animasyonsuz açılır/kapanır. Kök navigatörde açılır: yüzen bar
// düğmelerin üstüne binmez, kendiliğinden gizlenir (FloatingBarRouteObserver).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/ad_pacing.dart';
import '../services/ad_service.dart';
import 'liquid_glass_panel.dart';
import 'occult_button.dart';

/// Teklif penceresini gösterir; kullanıcı izleyip ödülü kazanırsa true.
/// Admin modunda pencere/reklam yok, ödül doğrudan verilir (true).
Future<bool> odulTeklifiGoster(
  BuildContext context, {
  required OdulTuru tur,
  String? falTuru,
  required String baslik,
  required String aciklama,
  required String izleEtiketi,
  required String vazgecEtiketi,
  AdService? servis,
}) async {
  final ads = servis ?? AdService.instance;
  if (ads.adsDisabled) return true;
  final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  final izle = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x99000000),
    transitionDuration: reduce ? Duration.zero : const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => OdulTeklifiSayfasi(
      baslik: baslik,
      aciklama: aciklama,
      izleEtiketi: izleEtiketi,
      vazgecEtiketi: vazgecEtiketi,
    ),
    transitionBuilder: (_, anim, __, child) {
      if (reduce) return child;
      final e = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: e,
        child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(e), child: child),
      );
    },
  );
  if (izle != true) return false;
  return ads.showRewardedFor(tur, falTuru: falTuru);
}

/// Sayfanın kendisi (testte doğrudan kurulabilsin diye ayrı).
class OdulTeklifiSayfasi extends StatelessWidget {
  const OdulTeklifiSayfasi({
    super.key,
    required this.baslik,
    required this.aciklama,
    required this.izleEtiketi,
    required this.vazgecEtiketi,
  });

  final String baslik;
  final String aciklama;
  final String izleEtiketi;
  final String vazgecEtiketi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            type: MaterialType.transparency,
            child: LiquidGlassPanel(
              key: const ValueKey('odulTeklifiPaneli'),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(baslik, textAlign: TextAlign.center, style: AppTextStyles.ritualTitle),
            ),
            const SizedBox(height: 10),
            Text(
              aciklama,
              textAlign: TextAlign.center,
              style: AppTextStyles.uiLabel.copyWith(color: AppColors.boneDim, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OccultButton.secondary(
                    label: vazgecEtiketi,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OccultButton.secondary(
                    label: izleEtiketi,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tür bazlı kısayollar: metinleri AppStrings'ten alır.
extension OdulTeklifiKisayol on WidgetRef {
  /// Hak bitti: "+1 [fal] hakkı".
  Future<bool> hakBittiTeklifi(BuildContext context, String falTuru) {
    final s = read(l10nProvider);
    return odulTeklifiGoster(
      context,
      tur: OdulTuru.hakBitti,
      falTuru: falTuru,
      baslik: s.adExtraRightTitle,
      aciklama: s.adExtraRightBody(s.fortuneDisplayName(falTuru)),
      izleEtiketi: s.adWatch,
      vazgecEtiketi: s.adDecline,
    );
  }

  /// Gelen kutusunda hazırlanan fal: "falı hemen aç".
  Future<bool> hemenAcTeklifi(BuildContext context) {
    final s = read(l10nProvider);
    return odulTeklifiGoster(
      context,
      tur: OdulTuru.hemenAc,
      baslik: s.adOpenNowTitle,
      aciklama: s.adOpenNowBody,
      izleEtiketi: s.adWatch,
      vazgecEtiketi: s.adDecline,
    );
  }

  /// Kapalı kutu: [aciklama] kişi/dönem/tek kutu metni; [tek] ise başlık da tekil.
  Future<bool> kutuAcTeklifi(BuildContext context, String aciklama, {bool tek = false}) {
    final s = read(l10nProvider);
    return odulTeklifiGoster(
      context,
      tur: OdulTuru.kutuAc,
      baslik: tek ? s.adOpenBoxSingleTitle : s.adOpenBoxTitle,
      aciklama: aciklama,
      izleEtiketi: s.adWatch,
      vazgecEtiketi: s.adDecline,
    );
  }
}
