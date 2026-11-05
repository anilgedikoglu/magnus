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

## Sıradaki tur adayları (öncelik sırası)
1. Kahve – Giriş (748, en çok çeşit gereken açılış sembolü) · 2. Kahve – Uğurlama (143) · 3. Kahve – Bağlama (250)
4. Niyet (178, M3) · 5. Japon Falı (27, uzun metin) · 6. Faloya (koşulsuz! M7) · 7. Kader Kitabı (229, M2)
8. Durugörü – Yarın (19) · 9. Durugörü – Bugün (önce saatmin/saatmax hatası düzeltilmeli) · 10. Kâhinler (her kâhin ayrı)
