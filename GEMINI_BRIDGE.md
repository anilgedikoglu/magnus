# Gemini Danışma ve İş Birliği Rehberi (GEMINI_BRIDGE.md)

> Codex gibi ikinci bir bağımsız beyin. Mimari karar, karmaşık algoritma, teknik doğrulama ve
> iki denemede çözülemeyen hatalarda Gemini'ye danış, sonucu sentezle.

## Gemini'nin uzmanlık alanları
1. **Mimari & State:** karmaşık durum yönetimi, offline-first, yerel şema, servis katmanı optimizasyonu.
2. **Algoritma & mantık:** matematik, veri boru hattı, oyun/mekanik mantığı, performans veri yapıları.
3. **Büyük refactor & hata analizi:** çok dosyaya yayılan teknik borç, derleme/terminal hatası kök neden.
4. **Kod inceleme & güvenlik:** temiz kod, edge case, yarış koşulu (race condition).
5. **Gereksinim parçalama:** soyut özelliği sıralı, yürütülebilir mikro adımlara bölme.

## Tetikleme kuralları (Claude)
- **Otomatik danış:** mimari karar öncesi, kritik refactor öncesi, ya da bir hatayı 2 denemede çözemeyince.
- **Format:** hangi dosya/katman · mevcut kısıt + hedef çıktı · varsa tam hata logu / kod bloğu.
- **Uygulama:** gelen plan/öneriyi entegre et, test et, süreci yürüt. Rubber-stamp değil; çelişirse kendi gerekçenle seç.

## ⚙️ Nasıl çağrılır — DOĞRUDAN REST (CLI DEĞİL)
`@google/gemini-cli` (v0.67) bu makinede headless'ta GÜVENİLMEZ: OAuth "free tier" artık kapalı
(IneligibleTierError) ve API-key moduna alsan bile kabuk açılışı yavaş + 503'lerde backoff-retry'a
takılıp asılıyor (>90 sn). Bu yüzden **doğrudan Generative Language REST API** kullanılır (hızlı).

- **Auth:** API key (Google AI Studio, proje 384789621872). **Repoya/koda YAZILMAZ.** Anıl'ın key'i
  oturumda inline verilir; kalıcı için `GEMINI_API_KEY` ortam değişkeni (setx/`~/.gemini/.env` bu
  ortamda engelli → Anıl elle set edebilir). `~/.gemini/settings.json` → `security.auth.selectedType = gemini-api-key`.
- **Çağrı (Bash):**
  ```bash
  curl -s -m 90 -X POST \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$GEMINI_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"contents":[{"parts":[{"text":"<SORU>"}]}],"generationConfig":{"maxOutputTokens":1200}}'
  ```
  Uzun danışmada metni dosyadan ver (`-d @body.json`); yanıtı `.candidates[0].content.parts[0].text`'ten al.
- **⚠️ maxOutputTokens CÖMERT olsun (≥800):** bu modeller gizli "thinking" bütçesi harcar; 10-20 verirsen
  metin BOŞ döner (düşünme bütçesinde biter, `candidatesTokenCount` görünür ama text yok).
- **Model seçimi / fallback:** birincil `gemini-3.5-flash` (✓ 200). 503 "high demand" / 429 rate-limit
  gelirse sırayla dene: `gemini-3.8-flash`, `gemini-3.1-pro-preview`, `gemini-3.5-flash-lite`.
  `gemini-2.5-flash` = 404 (yeni key'lere kapalı), `gemini-pro-latest`/`-flash-latest` sık 429/503.
  Model listesi: `GET .../v1beta/models?key=...`.
- **Güvenlik hook'ları:** `echo $KEY` ve `.env` yazımı engellidir (doğru). Key'i yalnız curl URL'inde
  inline kullan; echo'lama, repoya yazma.
- **Veri kuralı:** repo'daki yayınlanmamış kod Gemini'ye (Google API) GÖNDERİLEBİLİR (DeepSeek web'in
  aksine); yine de sır/anahtar/kişisel veri gönderme.

## Durum (2026-11-06)
Kurulum tamam: key geçerli, auth `gemini-api-key`, REST erişilebilir, `gemini-3.5-flash` gerçek yanıt
veriyor (finishReason STOP). CLI yolu terk edildi. İlk danışma konusu: ana menü chat bandının scroll-bağlı
mimariden 5 sn'lik pop-up'a geçişi (devam eden iş).
