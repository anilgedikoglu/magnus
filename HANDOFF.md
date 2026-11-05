# HANDOFF — Magnus App

> Claude ↔ Codex ↔ diğer oturumlar için güncel devir teslim. Ayrıntılı proje hafızası: `CLAUDE.md`.

## Ne yapıldı (2026-11-05) + değişen dosyalar
- **Sürüm `10.8.9+267`** (main). Android → Play **Dahili test**; iOS → TestFlight (GitHub Actions
  `.github/workflows/ios-testflight.yml`). İncelemeye/üretime GÖNDERİLMEDİ (Anıl: "yalnız test").
- **Görünüm:** renkler eski neon/mor palete döndü (yapı kaldı), gövde Nunito/Raleway, başlıklar Cinzel
  (`AppTextStyles.screenTitle`). İç ekranlar (kutular, pencereler, düğmeler) yeniden tasarım öncesine döndü.
- **Gezinme:** ekranın her yerinden soldan sağa kaydır = geri (`lib/core/widgets/edge_swipe_back.dart`,
  `NoEdgeSwipeBack` ile çark/kazıma alanları hariç). Gelen kutusu hep sağdan.
- **Açılış yasal bilgilendirmesi** 6 sn (`lib/core/widgets/startup_disclaimer.dart`, metin `lib/core/l10n/legal_texts.dart`).
- **Kullanıcı Bilgileri:** satır içi düzenleyici dairelerin yerinde (`settings_screen.dart` `_InlineEditor`), eşit kartlar.
- **Rüya Yorumu serbest metin:** "Rüyamı Yorumla" → 5 sn → pencere. `lib/data/services/dream_interpreter.dart`
  (Claude Haiku, günde 1 çevrimiçi; profil adı maskelenir `{{ISIM}}`; kesik yanıt reddedilir; çevrimdışı şablon yedeği).
- **Yeni fallar (ana menü 3. sayfa):** Tavşan Falı (`presentation/tavsanfali/`, günde 1, aynı gün tekrar açılınca
  bugünün sonucu), Kısmetim Kim? (`kismet_engine.dart`), Arabam Ne? (`araba_engine.dart`, `assets/data/arabam.json`
  264 model), Evim Neresi? (`ev_engine.dart`, `assets/data/evim.json` 281 ilçe/81 il + 29 yurt dışı şehir).
  Hepsi kalıcı deterministik çizelge; kutular geçiş reklamıyla açılır.
- **Codex incelemesi (8 bulgu) düzeltildi:** reklam kapanışı tek sefer + `show()` hatasında içerik açılır
  (`ad_service.dart`), await sonrası `ref` yok, Tavşan tarih en son yazılır, rüya hakkı istekten önce ayrılır,
  Arabam geçmiş aralıkları gizler.
- **267 sonrası (main'de, build YOK):** kayan yazı `lib/core/widgets/marquee_text.dart` (Arabam/Kısmetim/Evim
  kutuları; sığmayan ad tek satırda yavaş kayar), Tavşan dokununca çeker (kayıt dokununca) ve günde 1 (hak
  bitince menüde balon), 4 yeni fal ikonu turkuaz palete (ChatGPT). Rüya serbest yorumu HEP cihazda (izin/ağ yok).
  Sıfırlama tek kaynak `lib/data/services/fortune_reset.dart`: Ayarlar > Tüm Falları Sil = alınan fallar (gelen
  kutusu + Tavşan/Kısmetim/Arabam/Evim kayıtları), günlük haklar KALIR; Yönetici > Günlük Hakları Sıfırla = tüm
  günlük haklar + bu dört falın kayıtları.
- Testler: 89 geçiyor (`flutter test`); tek kırmızı takipsiz artık `test/_visual_starfield_capture_test.dart`.
- Görsel doğrulama: `build/visual_check/yeni_fallar_capture_test.dart --dart-define=CAP_PHASE=yf` (gitignored).

## Yarım kalan
- Anıl'ın 267 cihaz geri bildirimi bekleniyor (özellikle 4 yeni fal + rüya AI).
- Dert Ortağı içerik verisinde İngilizce yok (200 dert + 1000 tavsiye).
- Takipsiz geçici dosyalar (`test/_visual_starfield_capture_test.dart`, `test/goldens/`, `AGENTS.md`):
  protect-tests hook silmeyi engelliyor; commit edilmedi.

## Denenip olmayan ve nedeni
- Codemagic: fatura ödenmediği için build kapalı → iOS GitHub Actions ile.
- Chrome eklentisi 10 MB dosya sınırı → AAB parçalanıp sayfada Blob ile birleştirilerek Play'e yüklenir.
- JS `String.replace` betiklerinde `$'` / `$&` değiştirme kalıbı metni bozar → split/join ya da işlev kullan.
- `dusuk.cmd flutter.bat ...` arka planda asılı kalır → `dusuk.cmd cmd /c flutter.bat ... < /dev/null`.

## Sıradaki adım
- Anıl'ın geri bildirimi → düzelt. Bir sonraki build `10.8.10+270`, yalnız "test çık" ile.
- Güvenlik (Anıl onayı gerekli): repo herkese açık; git geçmişinde eski kişisel veri ve CLAUDE.md'de imza
  şifreleri var → geçmiş temizliği + anahtarları döndürme önerildi. Uygulamadaki Anthropic anahtarı istemcide
  gömülü → sunucu/proxy önerildi.
