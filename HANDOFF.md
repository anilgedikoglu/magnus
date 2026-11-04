# HANDOFF — Magnus App

> Claude ↔ Codex ↔ diğer oturumlar için güncel devir teslim. Ayrıntılı proje hafızası: `CLAUDE.md`.

## Ne yapıldı (2026-11-04/05) + değişen dosyalar
- **Cam alt bar (iOS 26 Liquid Glass) + ana sekmeler:** Ana Menü / Kullanıcı Bilgileri / Gelen Kutusu artık
  rota değil SEKME (`/home` → `MainTabsScreen`). Bar 5 eşit slot: Bilgisayar · Ev1 · Ev2 · Ev3 · Zarf; hepsi
  beyaz çizgi vektör glif (monitör + zarf ChatGPT'ye çizdirildi → SVG → Path; ev rakamları da çizgi path).
  Kapsül yayla kayar; ana menüde swipe ile sayfa değişince Ev1↔Ev3 arasında kayar. Eski pembe butonlar,
  Settings "Ana Menü" ve Inbox "Geri Git" (sekme içinde) kalktı.
  - `lib/presentation/shell/main_tabs.dart` (yeni), `lib/core/widgets/glass_tab_bar.dart` (yeni)
  - `lib/app.dart`, `lib/presentation/shell/app_shell.dart`, `home_screen.dart`, `settings_screen.dart`,
    `inbox_screen.dart`, `astrology_screen.dart`, `tarot_result_screen.dart`, `lib/core/l10n/app_strings.dart`
  - Testler: `test/main_tabs_test.dart` (gerçek go_router ile geri tuşu dahil), `test/glass_tab_bar_test.dart`
- **Android geri tuşu düzeltmesi:** go_router 13.2.5 `popRoute` PopScope'u atlıyordu (sekmedeyken uygulama
  kapanırdı) → `ChildBackButtonDispatcher`. `GoRoute.onExit` go() ile de tetiklendiği için KULLANILMADI.
- Önceki: Kullanıcı Bilgileri "yaşayan nebula" shader + yıldızlar (bkz. CLAUDE.md "Kozmik Gökyüzü Katmanı");
  Codemagic Flutter 3.41.5'e hizalandı (main toolchain).

## Yarım kalan
- **Gerçek cihazda hiç denenmedi:** cam bar blur/performans (animasyonlu nebula üstünde BackdropFilter),
  sekme geçişleri, Android geri tuşu (özellikle predictive back / Android 16), klavye davranışı.
- Ev1/Ev2/Ev3 ↔ gerçek HomeScreen PageView senkronu yalnız kodla + sahte sayfalı testle doğrulandı
  (gerçek HomeScreen Hive/servis istiyor; widget testine alınmadı).
- Flutter 3.41.5 ile ilk iOS (Codemagic) build'i hiç denenmedi.
- Mağaza build'i ALINMADI (Anıl "test çık" demeden yok). Bir sonraki: `10.8.7+261` (main `10.8.6+258`).
- Worktree'de takipsiz geçici dosyalar (`test/_visual_starfield_capture_test.dart`, `test/goldens/`):
  protect-tests hook silmeyi engelliyor; Anıl elle silebilir. Commit edilmedi.

## Denenip olmayan ve nedeni
- Hero ile barı rota geçişlerinde taşımak: `go('/inbox')` dal değişiminde uçuş yok, pop+push örtüşür → ortak kapsayıcı.
- `PopScope` ile sekme geri tuşu: go_router 13.2.5'te çalışmıyor (yukarıda).
- Dolu (beyaz dolgulu) aktif ikonlar: Anıl "kaba" buldu → yalnız çizgi; aktif = kapsül.
- TextPainter ile ev rakamı: test fontu kutu basıyor + platform fontuna bağımlı → çizgi path rakam.
- Nebula: aurora kurdeleleri/plus haleler, %40 mor tint, YIQ negatif dönüş (zeytin) — ayrıntı CLAUDE.md.
- `dusuk.cmd flutter.bat ...` arka planda asılı kalır → `dusuk.cmd cmd /c flutter.bat ... < /dev/null`.

## Sıradaki adım
- Anıl cihazda bakınca: cam yoğunluğu (`glass_tab_bar.dart` tint `0x8C1C1C1E`, blur σ20), ikon boyutu (27),
  kapsül rengi; nebula ayarları `shaders/living_nebula.frag`.
- "test çık" gelirse: pubspec `10.8.7+261` → AAB (`C:\src\flutter`) + main'e push → Codemagic `ios-release` (3.41.5).
