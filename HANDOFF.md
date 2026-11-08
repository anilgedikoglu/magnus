# HANDOFF — Magnus App

> Claude ↔ Codex ↔ diğer oturumlar için güncel devir teslim. Ayrıntılı proje hafızası: `CLAUDE.md`.

## Ne yapıldı (2026-11-08 — `10.8.32+300` ÇIKTI: Android Play Dahili test 20:41 + iOS TestFlight run 42505401195; 297 de aynı gün 17:26)
Hepsi commit + push + main'e FF. Tam test paketi 209/210 (tek kırmızı: commit'lenmemiş scratch
`test/_visual_starfield_capture_test.dart`). Ad taraması (lib+assets) temiz, tüm `assets/data/*.json` geçerli.

- **Ana menü chat 3 sn kuralı** (Anıl: "chat menü açıldığı anda açılıyor, 3 sn sonra dedik"). İki kök neden:
  (1) her açılışta 6 sn'lik yasal perde (`StartupDisclaimer`) menünün ÜSTÜNDE; 3 sn sayacı perdenin arkasında doluyordu →
  `StartupDisclaimer.perdeAcik` (ValueNotifier) eklendi, `home_screen.dart` `_acilisBandiniPlanla` sayacı perde TAMAMEN
  kalkınca başlatır. (2) fal gönderip menüye dönünce eklenen balon bandı ANINDA indiriyordu → `_donusBandiniPlanla` (3 sn);
  menüden çıkmadan karta dokunuşa cevap (hak bitti) `_tapPop` ile anında. Test: `test/home_band_timing_test.dart` (3 senaryo,
  gerçek MagnusApp, sahte saat + 16 ms kare adımı — tek büyük pump Ticker animasyonunu ilerletmez).
- **Kahve seçim butonu + foto yuvası vurgusu** (Anıl: "ikonlar oval ama highlight oval değil"): çerçeve `decoration`'da
  görselin ALTINDA kalıyordu; görsel köşede çerçeveyi örtüyordu → `foregroundDecoration`. 5x zoom ile doğrulandı
  (`build/visual_check/kahve_kose_test.dart`, `goldens/kahve_kose_zoom.png`).
- **Kahve fincan kontrolü** (Anıl: "hâlâ çalışmıyor"): sıkı kontrol (ML Kit etiketi var + fincan yok → reddet) 14:28'de
  commit'lendi, 291 build'i 13:52'de alınmıştı → 291'de YOK, 294'te VAR. Anıl'a 294'ü yükleyip denemesi söylendi.
  294'te de geçerse: yönetici modunda foto başına ML Kit etiketlerini gösteren teşhis satırı eklenmeli.
- **Dert Ortağı** kaynak TR: s034 "Eklemlerim", k049 "Herkes bir işe girdi" (a014 doğruydu, dokunulmadı).
- **Metin turları 28–42 TAMAMLANDI → +1500 metin, toplam 5199** (`docs/metin_uretim_log.md`). Tur 28–32 ChatGPT yazar;
  ChatGPT oturumu düştüğü için 33–42 Claude yazar. Hepsinde Claude ajanı seçer/denetler/çevirir, `ekle` + tur_kontrol ana
  oturum sırayla. Düzen: `scratchpad/turlar/SONLANDIRMA_TALIMATI.md`, `CLAUDE_YAZAR_TALIMATI.md`, `ekle_tur.js`
  (meta'dan dosya/anahtar okuyup ekler + `build/visual_check/tur_kontrol.json` yazar).

- **Tur 33–42 ikinci göz denetimi BİTTİ (1000/1000):** ChatGPT önerdi, hakem ajanı kabul/düzelt/red verdi. Son partilerde
  sistematik: ChatGPT "-abilir" ile yumuşatıp dokuyu siliyor → önerilerin yaklaşık yarısı aynen geçmedi. Hakem notlarında kalan
  tekrarlar (kâhin iskeletleri, motivasyonda kehanet paragrafı, kahve karşılamada eski havuzdaki sabit konu adları) dokunulmadı.
- **Ana menü tek düzen** (`menu_layout.dart`): Favoriler 3×2 + Diğer Türler büyük ikonlu 27 kart; rastgele düzen kalktı,
  büyük 3 kart hâlâ açılışta değişiyor.
- **Yüzen bar:** sekmede `Navigator.push` ile açılan detay (gelen kutusu → fal) bar dokunuşuyla kapanır (`closeMainTabsOverlays`).
- **Ayarlar > BİLDİRİMLER:** lamba sürgüsü `lib/core/widgets/lamp_toggle.dart` + `shaders/lamp_toggle.frag`; yerel "falın hazır"
  bildirimi `core/services/notification_service.dart`, `shell/notification_sync.dart` (sunucu yok, unlockAt'e zamanlanır; varsayılan kapalı).
  Referans karşılaştırma: `build/visual_check/lamp_compare_test.dart` (dinlenme kareleri SSIM 0.92–0.94; imleç/kadraj farkı dahil).

- **300'e giren (297 sonrası):** Kehanet menüsü 5 kartı ekran yüksekliğine göre boyutlanır, kaydırma yok
  (`kehanet_menu_screen.dart`, test `test/kehanet_menu_fit_test.dart`). Bildirimler varsayılan AÇIK: sistem izni ilk fal
  gönderilince bir kez istenir (`askOnce`, prefs `bildirim_izni_soruldu`), reddedilirse düğme kapanır. Lamba sürgüsü 1/3 boyut
  (93 pt), dokunma alanı en az 48 pt (`_touchPad`). Ana menü: "ana menüsü karşında" balonu kaldırıldı, yalnız mesaj; karşılamalar
  105 metin yenilendi (altın/Plus/eski özellikler gitti), gün-vakit-kişi koşulları `greeting_filter.dart`, `{{ziyaret}}` değişkeni.
  Arabam her açılışta bulanık arama; Evim harita yerine 16 bulanık ev (`assets/images/evim/ev_01..16.jpg`, ChatGPT). Kader Kitabı:
  sonraki sayfa varsa sağ sayfada ok.

- **300 sonrası main'de (build bekliyor):** Arabam motoru v4 (`araba_engine.dart`, şema 4 → eski çizelgeler yenilenir): sonraki araba
  ~%73-80 üst sınıf (profil/markaya göre; kesin değil), yıl tabanı (10+ yıl sınıf 3, 18+ sınıf 4, 26+ sınıf 5), aralıklar çoğu 3-6 yıl,
  aynı araba en çok 10 yıl ve son aralıkta devam yok, aynı model ailesi tekrarsız, lüks sınıfta yaygınlık etkisi az (Porsche/Ferrari çıkar),
  15+ yıl sonrası yalnız marka (`displayName`) ve uzak yıllarda art arda aynı marka yok. Havuz: 57 marka, 1865 model.
  **LG paneli** `lib/core/widgets/liquid_glass_panel.dart` ("LG yap" = alt bar camı, daha az saydam; `glass_lens.frag` artık köşe yarıçapı alır).
  Evim popup'ları LG, dikeyde uzun (küçük ekranda uzamaz), yıl şeridinin arkasında dönen tekerlek (`_YearDrumPainter`), giriş tek satır, Geç yok.
  Lamba düğmesi CAM önizlemesi ölçüsünde tam kapsül (`kGlassBarHeight`), sürgü yarım en: açık sol yarı, kapalı sağ yarı; taban hep koyu.

## Yarım kalan
- `test/_visual_starfield_capture_test.dart` + `test/goldens/` yanlışlıkla main'e girdi; silmeyi protect-tests hook'u engelledi, Anıl'ın kararı bekleniyor.
- **⚠️ Lamba sürgüsünün LİSANSI YOK:** Zsolt Kacso'nun "Glass Light Toggle" demosunun (lisanssız) shader/fizik çevirisi. Dahili test
  dışında (üretim/App Store) çıkmadan yazardan izin alınmalı ya da kod özgün yazılmalı.
- Bildirimler gerçek cihazda henüz denenmedi (Android derlemesi geçti, iOS CI'da derlenecek). Codex benzerlik teyidi yapılamadı
  (haftalık sınır 11 Kas 21:56'da açılır).

## Denenip olmayan ve nedeni
- 2026-11-08: ChatGPT girişinden ~10 dk sonra, 5 sekme AYNI ANDA yeniden yüklenip 40–45 KB mesaj gönderilince oturum
  düştü (tur 32'de de yoğun paralel kullanımda düşmüştü). Olası neden: sekmeler oturum belirtecini aynı anda yeniliyor.
  → Tek sekme, sekme yüklemeleri arasında bekleme. Codex haftalık sınırda (11 Kas 21:56'ya kadar), Gemini anahtarı yerel değil.
- ChatGPT yazarı havuzdaki SAHNELERİ farklı kelimelerle geri getiriyor; 5-gram `metin_kalip_tara` yakalamıyor → ajanlar havuzu
  elle okuyup ayıkladı. ChatGPT'ye dönülürse brief'e havuz sahnelerinin "kullanma" listesi eklenmeli.
- Haftalık kullanım sınırı (gece 11'de sıfırlandı) 5 yazar ajanını yarıda kesti; işleri kayıtlı kaldı, `SendMessage` ile
  kaldıkları yerden sürdü (yeni ajan açmaya gerek yok).
- `javascript_tool` büyük `insertText` sonrası bazen 45 sn zaman aşımı veriyor ama mesaj gidiyor; ikinci kontrolle
  `location.pathname` `/c/` ise gönderilmiş say. Gönder düğmesi: `button[aria-label*="önder"]` (eski `send-button` testid yok);
  çıktı: son `<pre>` (mesaj rol öznitelikleri kaldırılmış).

## Sıradaki adım
- Anıl 297'de bildirim düğmesini gerçek cihazda dener (açınca izin, kilitli fal hazır olunca bildirim, dokununca gelen kutusu).
- Anıl 300'de giriş mesajlarını, Arabam/Evim aramasını, Kader Kitabı okunu dener.
- Sonraki build `10.8.35+303`, yalnız Anıl "test çık" deyince: ANA klasörden derle (`git pull` sonrası), parça-birleştir + SHA-256 ile
  Play Dahili test, `gh workflow run "iOS TestFlight" --repo anilgedikoglu/magnus --ref main`.
- Anıl 294/297'de fincan kontrolünü dener; hâlâ geçerse yönetici teşhis satırı (ML Kit etiketleri) ekle.
