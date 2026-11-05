# HANDOFF — Magnus App

> Claude ↔ Codex ↔ diğer oturumlar için güncel devir teslim. Ayrıntılı proje hafızası: `CLAUDE.md`.

## Ne yapıldı (2026-11-05) + değişen dosyalar
- **Sürüm `10.8.10+270`** (main; 267 + kayan yazı, Tavşan dokunuş/günde 1, rüya cihazda, sıfırlama ayrımı, yeni ikonlar). Android → Play **Dahili test**; iOS → TestFlight (GitHub Actions
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
- **267 → 270:** kayan yazı `lib/core/widgets/marquee_text.dart` (Arabam/Kısmetim/Evim
  kutuları; sığmayan ad tek satırda yavaş kayar), Tavşan dokununca çeker (kayıt dokununca) ve günde 1 (hak
  bitince menüde balon), 4 yeni fal ikonu turkuaz palete (ChatGPT). Rüya serbest yorumu HEP cihazda (izin/ağ yok).
  Sıfırlama tek kaynak `lib/data/services/fortune_reset.dart`: Ayarlar > Tüm Falları Sil = alınan fallar (gelen
  kutusu + Tavşan/Kısmetim/Arabam/Evim kayıtları), günlük haklar KALIR; Yönetici > Günlük Hakları Sıfırla = tüm
  günlük haklar + bu dört falın kayıtları.
- **Metin üretimi turu 1 (270 sonrası, main'de, build YOK):** ChatGPT+DeepSeek çapraz üretim/seçimle 100 yeni metin
  (Tavşan, Yana Bana Dair, Durugörü Gelecek, Kahve Sonuç, Kahve Gelişme; TR+EN, koşullu). Skill: `magnus-metin-uretimi`;
  algoritmalar `docs/metin_algoritmalari.md`, kayıt `docs/metin_uretim_log.md`, betikler `scripts/metin_*`.
  Arabam v2 (1.865 model), Evim taşınma kuralları, Kısmetim açıklama havuzları, `VariableReplacer.isEn` (EN ay adları).
- **Metin üretimi turu 2 (build YOK):** 100 metin — Kahve Giriş (749–768), Niyet (179–198), Durugörü Yarın (20–39),
  Faloya (112–131), Durugörü Bugün (93–112). 30 örnek + ÇEŞİTLİLİK kuralı (moda-mod kalıp yasak). DeepSeek'in kalıplı
  Yarın metinleri DeepThink ile sıfırdan yazdırıldı; Durugörü Bugün ilk kez çalışıyor (profil başına 8–9 metin).
  Yeni denetim betiği `scripts/metin_kalip_tara.js`. Ayrıntı ve dersler: `docs/metin_uretim_log.md`.
- **Koşul değeri hatası düzeltildi:** tur 1'de `"yasmax": 25` sayı yazılmıştı → Kahve/Durugörü filtresi TypeError
  verirdi (270'te yayında değildi). Veri metne çevrildi; 11 ekranda okuma tip bağımsız (`fortune_service`, durugoru,
  acigercekler, dertortagi, iching, japonfali, kadercarki, kaderkitabi, biyoritim, olumlama, niyet); koruma testi
  `test/kosul_deger_tipi_test.dart` (boş/eksik koşul ve sayı olmayan yaş da yakalanır). Codex incelemesi yapıldı.
- Testler: 101 geçiyor (`flutter test`); tek kırmızı takipsiz artık `test/_visual_starfield_capture_test.dart`.
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
- DeepSeek'e taslak gösterip "kalıptan kurtar" demek işe yaramadı (iki tur, taslağa yapıştı); çapraz seçim sohbetinde
  revizyon istemek karşı modelin metinlerini kopyalattı → yeni sohbet + DeepThink + taslaksız yazım.

## Sıradaki adım
- Anıl'ın geri bildirimi → düzelt. Bir sonraki build `10.8.11+273`, yalnız "test çık" ile.
- "Bir tur daha" denirse: `docs/metin_uretim_log.md` → "Sıradaki tur adayları" (Kahve Uğurlama, Kahve Bağlama,
  Japon, Kader Kitabı, Kâhinler) + `magnus-metin-uretimi` skill'i.
- Güvenlik (Anıl onayı gerekli): repo herkese açık; git geçmişinde eski kişisel veri ve CLAUDE.md'de imza
  şifreleri var → geçmiş temizliği + anahtarları döndürme önerildi. Uygulamadaki Anthropic anahtarı istemcide
  gömülü → sunucu/proxy önerildi.
