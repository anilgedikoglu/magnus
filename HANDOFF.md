# HANDOFF — Magnus App

> Claude ↔ Codex ↔ diğer oturumlar için güncel devir teslim. Ayrıntılı proje hafızası: `CLAUDE.md`.

## Ne yapıldı (2026-11-04) + değişen dosyalar
- **Kullanıcı Bilgileri ekranı (settings) "yaşayan nebula":** fragment shader ile gökte yavaş dalgalanma,
  bölge bölge alacalı sıcak/soğuk renk değişimi, ışık nefesi, daha koyu + twinkle yıldızlar + kayan yıldız.
  Anıl'ın geri bildirimiyle beyaz aurora perdesi ve haleler kaldırıldı.
  - `shaders/living_nebula.frag` (yeni) + `pubspec.yaml` (`flutter: shaders:`)
  - `lib/core/widgets/living_nebula.dart` (yeni: `LivingNebulaBackground`)
  - `lib/core/widgets/starfield_overlay.dart` (yıldız + kayan yıldız; yedek `SkyDarkenOverlay`)
  - `lib/presentation/settings/settings_screen.dart` (bg → LivingNebulaBackground)
  - `test/living_nebula_test.dart` (3 test, gerçek piksel kontrolü dahil), `test/starfield_overlay_test.dart` (3)
- **Toolchain:** main Flutter 3.41.5 + intl ^0.20.2 istiyor (başka oturum, `0fd1cc89`); `codemagic.yaml` 3.29.2'den
  3.41.5'e hizalandı. Lokal Flutter: `C:\src\flutter`. `C:\flutter` (3.29.2) artık `pub get` çözemez.
- Mimari/değerler/renk dersleri: `CLAUDE.md` → "Kozmik Gökyüzü Katmanı".

## Yarım kalan
- Gerçek cihazda (iPhone/Android, Impeller) görüntü + FPS/ısınma ölçümü YAPILMADI. Doğrulama: flutter_tester (Skia)
  render kareleri + video + PSNR. Android GLES yedeğinde sampler y-flip'i ayrıca kontrol edilmeli (Codex notu).
- Flutter 3.41.5 ile ilk iOS (Codemagic) build'i hiç denenmedi — Podfile/min iOS uyarılarına hazırlıklı ol.
- Mağaza build'i ALINMADI (Anıl "test çık" demeden build yok). Bir sonraki: `10.8.7+261` (main `10.8.6+258`).

## Denenip olmayan ve nedeni
- Aurora kurdeleleri + plus haleler: alpha <0.2'de görünmedi, görününce "tek beyaz perde" diye beğenilmedi → kaldırıldı.
- Palet tinti 0.40: nebulanın tamamı mor ("sabit morluk") → ton döndürmeye geçildi.
- YIQ'de negatif ton dönüşü / teal palet: kırmızı-turuncuyu ZEYTİNE çevirdi → soğuk = pozitif dönüş, teal çıkarıldı.
- Codex taslağı warp `(flow*2-1)*2px`: fbm 0.5±0.15 toplandığı için <1 px (görünmez) → `(flow-0.5)*14`.
- `dusuk.cmd flutter.bat ...` arka planda asılı kaldı (`start` → `cmd /K`) → `dusuk.cmd cmd /c flutter.bat ... < /dev/null`.

## Sıradaki adım
- Anıl cihazda bakınca ayar: `shaders/living_nebula.frag` sabitleri (`WARP_PX`, `HUE_COOL`, `TINT`, `BREATH`, `uDark`)
  ve `living_nebula.dart` `_orbit` hızları. Doğrulama: `build/visual_check/` widget testleri (kare + video).
- "test çık" gelirse: pubspec `10.8.7+261` → AAB (`C:\src\flutter`) + main'e push → Codemagic `ios-release` (3.41.5).
