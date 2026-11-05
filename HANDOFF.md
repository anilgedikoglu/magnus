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

- **2026-11-05 test build'i `10.8.7+261`** (Anıl "test çık"): Codex son davranış incelemesi → BULGU YOK.
  Claude code-reviewer'ın 3 regresyonu + EN tarot kart hatası önceden düzeltilmişti (e1d6d5e8).
  Yönetici "godag" girişindeki gerçek kişisel veri koddan çıkarıldı → `lib/core/utils/admin_gate.dart`
  (nötr profil + `admin_mode` bayrağı; eski cihaz FNV-1a özetiyle tanınır), test `test/admin_gate_test.dart`.

- **Yayın durumu:** Android 261 → Play **Dahili test** (2026-11-05 08:31; üretime/incelemeye gönderilmedi).
  iOS 261 → TestFlight'a YÜKLENDİ (GitHub Actions `.github/workflows/ios-testflight.yml`, run 41975235819,
  ~7 dk; incelemeye gönderilmedi). Codemagic faturası ödenmediği için kapalı; secrets repo'da tanımlı.

## Yarım kalan
- **Gerçek cihazda ilk kez bu build'le denenecek:** yeni zemin (grain + vinyet), filmli görsellerin parlaklığı,
  cam bar, Olumlama'daki çift `GrimoireBackdrop` çapraz geçişinin düşük cihazda kare süresi.
- Dert Ortağı içerik verisinde (200 dert + 1000 tavsiye) İngilizce yok → ayrı görev önerildi.
- Bir sonraki build: `10.8.8+264` (yalnız "test çık" ile).
- Takipsiz geçici dosyalar (`test/_visual_starfield_capture_test.dart`, `test/goldens/`, `AGENTS.md`):
  protect-tests hook silmeyi engelliyor; commit edilmedi.

## Denenip olmayan ve nedeni
- Codex paket 3-4 (kehanet, tarot…) limit yüzünden yarıda kesildi → derleme hataları elle düzeltildi.
- Grain ilk sürümde tek uzunluklu nokta dizisi → RangeError (testle yakalandı, düzeltildi).
- Sepya film: orman/yüz/uzay görsellerini aynı kahverengiye boğuyor → soğuk gümüş film.
- Eski: Hero ile bar taşıma, PopScope geri tuşu, dolu ikonlar, TextPainter rakam, nebula aurora/zeytin.
- `dusuk.cmd flutter.bat ...` arka planda asılı kalır → `dusuk.cmd cmd /c flutter.bat ... < /dev/null`.

## Sıradaki adım
- Anıl'ın `10.8.7+261` cihaz geri bildirimi → ayarlar.
- Anıl cihazda bakınca: film gücü (`FilmedImage.restSaturation/restBrightness`), zemin grain/mum ışığı
  (`GrimoireBackdrop` candle/vignette/grain), menü kartı etiketi, glif seti (`occult_glyphs.dart`).
- "test çık" gelirse: pubspec `10.8.8+264` → AAB (`C:\src\flutter`) + main'e push → Codemagic `ios-release`.
