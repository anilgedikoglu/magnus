# Magnus metin üretimi — tur kaydı

> `magnus-metin-uretimi` skill'i. Her tur = 5 kompartman × 20 metin = 100 metin (ChatGPT'den çapraz seçilmiş 10 +
> DeepSeek'ten çapraz seçilmiş 10). Ayrıntılı algoritma: `docs/metin_algoritmalari.md`.
> Araçlar: `scripts/metin_turu_hazirla.js` (brief + 10 örnek + 20 kitle), `scripts/metin_capraz_hazirla.js` (çapraz
> seçim dosyaları), `scripts/metin_birlestir.js aday|ekle` (kitle→koşul, yer tutucu düzeltme, ekleme),
> `scripts/metin_ceviri_hazirla.js brief|bol` (İngilizce çeviri, ChatGPT).

## Tur 1 — 2026-11-05 (toplam 100 metin)

| Kompartman | Dosya / anahtar | Eşleştirici | Eklenen id | Kaynak |
|---|---|---|---|---|
| Tavşan Falı | `tavsanfali.json` › `tavsanfali` | M5 (ham anahtar) | 121–140 | ChatGPT 10 (DeepSeek seçti) + DeepSeek 10 (ChatGPT seçti) |
| Yana – Bana Dair | `yana.json` › `bana_dair` | M4 (Türkçe değer) | 69–88 | aynı |
| Durugörü – Gelecek | `durugoru_gno.json` › `durugoru_gno` | M1 | 47–66 | aynı |
| Kahve – Sonuç | `kahve_sonuc.json` › `sonuclar` | M1 + fal_konusu | 399–418 | aynı |
| Kahve – Gelişme | `kahve_gelisme.json` › `gelismeler` | M1 + fal_konusu | 419–438 | aynı |

Notlar:
- Kitle dağılımı: ~%25 koşulsuz, geri kalanı cinsiyet / medeni durum / meslek / yaş (25 altı, 40 üstü) tek ya da çift koşul.
- DeepSeek uzun çıktıda (Kahve Gelişme) 15. metinde kesildi → "15-20'yi ayrı ver" ile tamamlandı.
- Yan düzeltme: Yana eşleştiricisinde `akademisyen` artık yalnız akademisyene, `kendi işini yapıyor` → `kendiisi`,
  `iş arıyor`/`çalışmıyor` eklendi (`yana_screen.dart`).

## Tur 2 — 2026-11-05 (toplam 100 metin; 30 örnek + ÇEŞİTLİLİK kuralı ilk kez)

| Kompartman | Dosya / anahtar | Eşleştirici | Eklenen id | Kaynak |
|---|---|---|---|---|
| Kahve – Giriş | `kahve_giris.json` › `girisler` | M1 + fal_konusu | 749–768 | ChatGPT 10 + DeepSeek 10 (çapraz) |
| Niyet | `niyet.json` › `niyet` | M3 (etiket değeri, yaş yok) | 179–198 | aynı |
| Durugörü – Yarın | `durugoru_yno.json` › `durugoru_yno` | M1 | 20–39 | ChatGPT 10 (20–29) + DeepSeek 10 (30–39, aşağıya bak) |
| Faloya | `faloya.json` › `faloya` | M7 (hepsi koşulsuz) | 112–131 | aynı |
| Durugörü – Bugün | `durugoru_bno.json` › `durugoru_bno` | M1, saat koşulu YOK | 93–112 | ChatGPT 10 + DeepSeek 10 |

Notlar (dersler → skill'e işlendi):
- **DeepSeek moda-mod kalıba düşüyor:** Yarın'daki 10 metninin 7'si "Öğleye doğru → Öğleden sonra → Akşamüstü → Akşam →
  Tavsiyem: yarın…" iskeletiydi; iki revizyon turu (taslak gösterilerek) düzeltmedi — taslağa yapışıyor, revizyon
  brief'indeki örnek kelimeyi bile körü körüne ekledi ("ofis toplantısında kasadaki genç"). Çözüm: **taslak göstermeden,
  DeepThink açık, yeni sohbette** aynı 10 kitle × 2 varyant sıfırdan yazdırıldı; ChatGPT kitle başına 1 seçti → 30–39.
- **Çapraz seçim sohbetinde revizyon = kopya:** Bugün revizyonunu seçim yaptığı sohbette isteyince DeepSeek, aynı sohbette
  gördüğü ChatGPT metinlerinin açılışlarını aldı (mor kapaklı defter, ekranda üç pencere…). Revizyon/yeniden yazım hep
  YENİ sohbette ve karşı modelin metinleri görünmeden.
- **Ölü havuz için koşulsuz kotası:** Bugün havuzu boştu (eski 92 metnin hepsi saat koşullu); çapraz seçim yalnız 1 koşulsuz
  metin almıştı → Claude denetimi ChatGPT'nin 4 koşulsuz + 2 eksik kitle (ev hanımı, emekli) metnini aldı, kitle tekrarı
  olan ve DeepSeek'in ödünç aldığı ChatGPT metinlerini çıkardı. Sonuç: profil başına 8–9 metin (önce 0).
- **"belki X, belki Y" belirsizliği:** Kahve Giriş'te 8 metin (havuz ortalaması 0,08/metin iken 2–4) → tek somut olaya
  indirildi (TR+EN). Kahve #761 içerik "eşinle" diyordu, koşula `medeni durum=evli` eklendi.
- **Sayısal koşul hatası (tur 1'den):** `"yasmax": 25` sayı yazılmıştı; Kahve (`fortune_service`) ve Durugörü `as String`
  okuyup TypeError fırlatırdı → fal sessizce düşerdi. 9 kayıt metne çevrildi, 8 ekranda okuma tip bağımsız yapıldı,
  `test/kosul_deger_tipi_test.dart` koruma testi, `metin_birlestir.js` artık "25" yazar. (270'te yayında değildi.)
- Yeni araç: `scripts/metin_kalip_tara.js` — Tavsiyem / saat zinciri / belki listesi / {{harf}} aşırılığı / tekrar açılış /
  havuzla ve birbirleriyle ortak 5-gram. Faloya gibi sabit çerçeveyi havuzdan öğrenip yok sayar.

## Sıradaki tur adayları (öncelik sırası)
1. Kahve – Uğurlama (143) · 2. Kahve – Bağlama (250) · 3. Japon Falı (27, uzun metin) · 4. Kader Kitabı (229, M2)
5. Kâhinler (her kâhin ayrı) · 6. Yana – Yaşama Dair (110) · 7. Kahve – Karşılama · 8. Durugörü – Bugün (2. tur, havuz hâlâ küçük: 20)
