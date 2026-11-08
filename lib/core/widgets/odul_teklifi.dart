// lib/core/widgets/odul_teklifi.dart
//
// Ödüllü reklam teklif penceresi (docs/reklam_duzeni.md): alt sayfa, sıvı cam, başlık + ödülün
// açık yazısı, EŞİT iki düğme (Reklam izle / Vazgeç). Reddetmek normal kullanımı engellemez;
// metin yönlendirmez. Yalnız kullanıcı "Reklam izle" derse reklam başlar; true YALNIZ ödül
// kazanıldıysa döner (kapatma/hata/hazır değil → false).
//
// Azaltılmış hareket: sayfa animasyonsuz açılır/kapanır. Alt sayfa bir PopupRoute olduğu için
// yüzen bar kendiliğinden gizlenir (FloatingBarRouteObserver).

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
  final izle = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000),
    elevation: 0,
    useSafeArea: false,
    sheetAnimationStyle: reduce ? const AnimationStyle(duration: Duration.zero, reverseDuration: Duration.zero) : null,
    builder: (_) => OdulTeklifiSayfasi(
      baslik: baslik,
      aciklama: aciklama,
      izleEtiketi: izleEtiketi,
      vazgecEtiketi: vazgecEtiketi,
    ),
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
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
      child: LiquidGlassPanel(
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

  /// Kapalı kutu: [aciklama] kişi/dönem/tek kutu metni.
  Future<bool> kutuAcTeklifi(BuildContext context, String aciklama) {
    final s = read(l10nProvider);
    return odulTeklifiGoster(
      context,
      tur: OdulTuru.kutuAc,
      baslik: s.adOpenBoxTitle,
      aciklama: aciklama,
      izleEtiketi: s.adWatch,
      vazgecEtiketi: s.adDecline,
    );
  }
}
