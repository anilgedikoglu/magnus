# HANDOFF — Magnus App

> Claude ↔ Codex ↔ diğer oturumlar için güncel devir teslim. Ayrıntılı proje hafızası: `CLAUDE.md`
> ("GECE GRİMUARI TASARIM SİSTEMİ", "ANA SEKMELER + CAM ALT BAR", "Kozmik Gökyüzü Katmanı").

## Ne yapıldı (2026-11-04/05) + değişen dosyalar
- **Tüm uygulama "Gece Grimuarı" yeniden tasarımı** (commit 58fb31a5 → 47316fc6): mürekkep zemin, filmli
  görseller, cam kartlar, tek vurgu mum altını, Cinzel/Jost/EB Garamond (pakete gömülü, `assets/google_fonts/`).
  - Çekirdek: `lib/core/constants/{app_colors,app_text_styles,app_theme}.dart`, `lib/core/widgets/`
    (`glass_panel`, `occult_button`, `occult_cards`, `filmed_image`, `grimoire_backdrop`, `occult_glyphs`),
    `lib/core/utils/rich_text_parser.dart` (desatüre renkler + `span()`), `lib/core/l10n/app_strings.dart`.
  - Ekranlar: `lib/presentation/**` hemen hepsi (ana menü, ayarlar + açılır pencereler, gelen kutusu, fal
    detayı `inbox_detail_screen.dart` baştan yazıldı, 28 fal ekranı, onboarding balonları).
  - ~40 İngilizcesiz UI metni AppStrings'e taşındı (TR+EN).
  - Test: `test/grimoire_backdrop_test.dart` (+ mevcut 15 test) — 21/21 geçiyor; `flutter analyze lib` 0 hata.
  - Görsel doğrulama: `build/visual_check/app_screens_capture_test.dart` (gitignored) → `screens/kontak_*`.
- Önceki: cam alt bar + ana sekmeler (`main_tabs.dart`, `glass_tab_bar.dart`), Android geri tuşu düzeltmesi,
  Kullanıcı Bilgileri yaşayan nebula (şimdi doygunluk 0.58).

## Yarım kalan
- **Codex son incelemesi YAPILMADI** (Codex kullanım limiti, 2026-11-05 ~02:56'ya kadar). Claude
  code-reviewer ajanı mantık regresyonu taradı (sonucu commit mesajı / bu dosyada).
- **Gerçek cihazda hiç denenmedi:** yeni zemin (grain + vinyet), filmli görsellerin parlaklığı, cam bar,
  Olumlama'daki çift `GrimoireBackdrop` çapraz geçişinin düşük cihazda kare süresi.
- Dert Ortağı içerik verisinde (200 dert + 1000 tavsiye) İngilizce yok → ayrı görev önerildi.
- Admin "godag" bypass'ında gerçek kişisel veri var (yayınlanan koda giriyor) → ayrı görev önerildi.
- Mağaza build'i ALINMADI (Anıl "test çık" demeden yok). Bir sonraki: `10.8.7+261` (main `10.8.6+258`).
- Takipsiz geçici dosyalar (`test/_visual_starfield_capture_test.dart`, `test/goldens/`, `AGENTS.md`):
  protect-tests hook silmeyi engelliyor; commit edilmedi.

## Denenip olmayan ve nedeni
- Codex paket 3-4 (kehanet, tarot…) limit yüzünden yarıda kesildi → derleme hataları elle düzeltildi.
- Grain ilk sürümde tek uzunluklu nokta dizisi → RangeError (testle yakalandı, düzeltildi).
- Sepya film: orman/yüz/uzay görsellerini aynı kahverengiye boğuyor → soğuk gümüş film.
- Eski: Hero ile bar taşıma, PopScope geri tuşu, dolu ikonlar, TextPainter rakam, nebula aurora/zeytin.
- `dusuk.cmd flutter.bat ...` arka planda asılı kalır → `dusuk.cmd cmd /c flutter.bat ... < /dev/null`.

## Sıradaki adım
- Codex: "Önce HANDOFF.md'yi oku" + `git diff 58fb31a5 HEAD -- lib` için davranış regresyonu incelemesi
  (tercihler/zamanlayıcılar/reklam/inbox/geri tuşu) — özellikle `lib/presentation/kehanet/*`, `tarot/*`,
  `kadercarki`, `askuyumu`, `inbox_detail_screen.dart`.
- Anıl cihazda bakınca: film gücü (`FilmedImage.restSaturation/restBrightness`), zemin grain/mum ışığı
  (`GrimoireBackdrop` candle/vignette/grain), menü kartı etiketi, glif seti (`occult_glyphs.dart`).
- "test çık" gelirse: pubspec `10.8.7+261` → AAB (`C:\src\flutter`) + main'e push → Codemagic `ios-release`.
