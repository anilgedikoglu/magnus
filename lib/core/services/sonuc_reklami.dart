// lib/core/services/sonuc_reklami.dart
//
// Fal sonucu açılmadan hemen önce geçiş reklamı (Anıl'ın kararı, 2026-11-09; reklam.md).
// Gelen kutusuna düşen fallarda fal açılmadan önce, sonucu ekranda gösterenlerde ritüel biter
// bitmez, ritüeli olmayanlarda fal açılırken.
//
// ⚠️ Google Play politikası bu anlardaki düz geçiş reklamını ihlal sayıyor; risk bilerek alındı.
// Uyarı gelirse aynı noktalar atlanabilir reklama (rewarded interstitial) çevrilir; birim hazır
// olana kadar [kSonucOncesiReklam] false: reklam eski yerlerine kendiliğinden döner (reklam.md).

import '../magnus_ses/magnus_hafiza.dart';
import 'ad_service.dart';

const bool kSonucOncesiReklam = true;

/// Reklam kapanınca döner. Hazır reklam yoksa ya da sınır doluysa hemen döner; akış beklemez.
Future<void> sonucOncesiReklam() async {
  if (!kSonucOncesiReklam) return;
  await AdService.instance.maybeShowInterstitial(
    tamamlananFal: MagnusHafiza.aktif?.tamamlananFal ?? 0,
    kapanincaDon: true,
  );
}
