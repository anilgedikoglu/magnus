# HANDOFF — Magnus App

> Claude ↔ Codex ↔ diğer oturumlar için güncel devir teslim. Ayrıntılı proje hafızası: `CLAUDE.md`.

## Ne yapıldı (2026-11-08 — 294 sonrası, main'de; BUILD BEKLİYOR: `10.8.29+297`, yalnız Anıl "test çık" deyince)
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

## Yarım kalan
- **Build `10.8.29+297`** hazır değil-alınmadı: Anıl'ın "test çık" demesi gerekiyor (294'ü kendi kararımla erken almıştım —
  Anıl uyardı; bir daha "her şey bitince" talimatı olsa bile bitiş anında tek satırla teyit al).
- **ChatGPT oturumu kapalı** (`/api/auth/session` loggedIn:false) — sonraki ChatGPT-yazar turları için Anıl'ın Chrome'da
  chatgpt.com'a giriş yapması gerekiyor (şifre girilmez).

## Denenip olmayan ve nedeni
- ChatGPT yazarı havuzdaki SAHNELERİ farklı kelimelerle geri getiriyor; 5-gram `metin_kalip_tara` yakalamıyor → ajanlar havuzu
  elle okuyup ayıkladı. ChatGPT'ye dönülürse brief'e havuz sahnelerinin "kullanma" listesi eklenmeli.
- Haftalık kullanım sınırı (gece 11'de sıfırlandı) 5 yazar ajanını yarıda kesti; işleri kayıtlı kaldı, `SendMessage` ile
  kaldıkları yerden sürdü (yeni ajan açmaya gerek yok).
- `javascript_tool` büyük `insertText` sonrası bazen 45 sn zaman aşımı veriyor ama mesaj gidiyor; ikinci kontrolle
  `location.pathname` `/c/` ise gönderilmiş say. Gönder düğmesi: `button[aria-label*="önder"]` (eski `send-button` testid yok);
  çıktı: son `<pre>` (mesaj rol öznitelikleri kaldırılmış).

## Sıradaki adım
- Anıl "test çık" derse: `10.8.29+297` — ANA klasörden derle (`git pull` sonrası), parça-birleştir + SHA-256 ile Play Dahili
  test, `gh workflow run "iOS TestFlight" --repo anilgedikoglu/magnus --ref main`.
- Anıl 294/297'de fincan kontrolünü dener; hâlâ geçerse yönetici teşhis satırı (ML Kit etiketleri) ekle.
