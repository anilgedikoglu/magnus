# Magnus metin üretimi — tur kaydı

> `magnus-metin-uretimi` skill'i. Her tur = 5 kompartman × 20 metin = 100 metin (ChatGPT'den çapraz seçilmiş 10 +
> DeepSeek'ten çapraz seçilmiş 10). Ayrıntılı algoritma: `docs/metin_algoritmalari.md`.
> Araçlar: `scripts/metin_turu_hazirla.js` (brief + 10 örnek + 20 kitle), `scripts/metin_capraz_hazirla.js` (çapraz
> seçim dosyaları), `scripts/metin_birlestir.js aday|ekle` (kitle→koşul, yer tutucu düzeltme, ekleme),
> `scripts/metin_ceviri_hazirla.js brief|bol` (İngilizce çeviri, ChatGPT).

## 🎯 HEDEF ve İLERLEME (Anıl, 2026-11-05: "örnek ver, metin al" döngüsü, app genelinde 4.000–5.000 ilave metin)
- **Toplam eklenen: 2029** (tur 1: 100, tur 2: 100, tur 3: 138, tur 4: 160, tur 5: 140, tur 6: 140, tur 7: 140, tur 8: 180, tur 9: 160, tur 10: 140, tur 11: 174, tur 12: 157, tur 13: 140, tur 14: 160) — her tur sonunda güncelle.
- Ölçek: kısa bölmede (≤350 kr) model başına 40 yaz / karşı model 20 seç (`adet: 40`); uzunlarda 20/10.
- Kuyruk (sıradaki turlar; tükenince 2. tura dön): Kahve Bağlama · Kahve Gelişme (2) · Kahve Sonuç (2) · Kahve Karşılama ·
  Yana Yaşama Dair · Yana Bana Dair (2) · Tavşan (2) · Niyet (2) · Faloya (2) · Durugörü Yarın (2) · Durugörü Gelecek (2) ·
  Kâhin Derun · Kâhin Khaleesi · Kâhin Uraz · Olumlama · Motivasyon · Özlü Söz · Acı Gerçekler · Kader Çarkı (6 bölme) ·
  Günlük Astroloji (bölümler) · Karşılamalar · Japon Falı (uzun, 10'luk parçalar) · I-Ching (uzun).
- Magnus taktikleri (cold reading, altın örnekler, iskelet/tümleç, kişiselleştirme…) skill'deki tabloda; her brief'e girer.

## Gece dersleri (2026-11-06, tur 11–17)
- **Geçici sohbet (`chatgpt.com/?temporary-chat=true`)**: normal "Yeni sohbet" kutusunda başka işin uzun taslağı
  duruyordu (dokunulmadı). Geçici sohbetin kutusu boş açılıyor; yazım/seçim/çeviri orada yapıldı. Sekme başlığı ilk
  mesajı yansıttığı için `document.title='w15_derun'` gibi kısa ad verildi (araç çıktısı şişmesin).
- **Toplu yükleme**: tek gizli `<input multiple>`'a 10-15 dosya bir `file_upload` ile verilip `localStorage`'a
  (`claude_metin_<ad>`) yazıldı; her sekme metni oradan alıp `.ProseMirror`'a `insertText` + `button[aria-label="Gönder"]`
  (testid yok; durdur = `aria-label="Durdur"`). Async IIFE `{}` döndürür → üst düzey `await` kullan.
- **Ön çeviri** (`scripts/metin_on_ceviri.js`): Codex sınırda beklerken ChatGPT çıktılarının TAMAMI seçimden önce
  çevrildi; seçim gelince `uygula` ile eşlenir. Seçim sonrası çeviri beklemesi ortadan kalkar.
- **ChatGPT oturumu 02:15'te düştü** (yeni yüklenen sayfa "Oturum aç" gösterdi, `/api/auth/session` boş). Açık ve önceden
  yüklenmiş sekmeler bellekteki oturumla çalışmaya devam etti → bu sekmelerde sayfa YENİLEMEDEN aynı sohbete "Şimdi
  yeni bir görev: …" diye ek mesaj yazıldı. Parola girilmedi (yasak); oturum açmak Anıl'da.

## Tur 13–14 — 2026-11-06 gece (300 metin; ChatGPT + Codex)

| Kompartman | Dosya / anahtar | Eklenen id |
|---|---|---|
| Karşılama – günün 1. açılışı | `karsilamalar.json` › `karsilamalar` (ziyaret 1) | 620–659 |
| Karşılama – 6.+ ziyaret | `karsilamalar.json` › `karsilamalar` (ziyaret 6) | 660–699 |
| Kâhin Likia | `kahinler.json` › `kahinler.likia` | likia_63–likia_82 |
| Kâhin Yousuf | `kahinler.json` › `kahinler.yousuf` | yousuf_63–yousuf_82 |
| Günlük Astroloji – Yorum | `gunlukastroloji.json` › `astroyorum` | 100–119 |
| Tavşan Falı | `tavsanfali.json` › `tavsanfali` | 221–260 |
| Niyet | `niyet.json` › `niyet` | 279–318 |
| Yana – Bana Dair | `yana.json` › `bana_dair` | 169–208 |
| Kahve – Sonuç | `kahve_sonuc.json` › `sonuclar` | 459–478 |
| Kahve – Gelişme | `kahve_gelisme.json` › `gelismeler` | 479–498 (Codex seçimi 04:37; 1 "tıbbi sonuç değil" ibaresi çıkarıldı) |

## Tur 11–12 — 2026-11-06 gece (331 metin; ChatGPT + Codex, ikinci geçiş)

| Kompartman | Dosya / anahtar | Eklenen id |
|---|---|---|
| Kahve – Uğurlama | `kahve_ugurlama.json` › `ugurlamalar` | 184–223 |
| Yana – Yaşama Dair | `yana.json` › `yasama_dair` | 151–190 |
| Kahve – Bağlama | `kahve_baglama.json` › `baglamalar` | 291–330 |
| Faloya | `faloya.json` › `faloya` | 172–205 (34: ChatGPT'nin tarih açılışlı metinleri "aynı açılış" kuralıyla 14'e indi) |
| Durugörü – Gelecek | `durugoru_gno.json` › `durugoru_gno` | 87–106 |
| Kahve – Karşılama | `kahve_akarsilama.json` › `karsilamalar` | 387–426 |
| Durugörü – Yarın | `durugoru_yno.json` › `durugoru_yno` | 60–79 |
| Olumlama | `olumlamalar.json` › `olumlamalar` | 555–592 (38: 2 yakın tekrar elendi) |
| Acı Gerçekler | `acigercekler.json` › `acigercekler` | ag113–ag151 (39: 1 yakın tekrar elendi) |
| Kâhin Uraz | `kahinler.json` › `kahinler.uraz` | uraz_44–uraz_63 |

Notlar: Claude denetimi Kahve Karşılama'daki 4 "tıbbi teşhis değildir/sembolik yorum" ibaresini çıkardı (istenmeyen not
kuralı), Gelecek #14'te dil bilgisi, Faloya EN #19'da eksik çerçeve satırı düzeltildi. ChatGPT seçimleri ve çeviriler
geçici sohbette (normal "Yeni sohbet" kutusunda başka işin taslağı var; dokunulmadı). Codex 01:41'de kullanım sınırına
takıldı (04:35'e kadar).

## Tur 5–6 — 2026-11-05 (sürüyor; ChatGPT + Codex)

| Kompartman | Dosya / anahtar | Eklenen id |
|---|---|---|
| Kahve – Karşılama | `kahve_akarsilama.json` › `karsilamalar` | 347–386 |
| Yana – Yaşama Dair | `yana.json` › `yasama_dair` | 111–150 |
| Kâhin Derun | `kahinler.json` › `kahinler.derun` | derun_34–53 |
| Kâhin Khaleesi | `kahinler.json` › `kahinler.khaleesi` | khaleesi_32–51 |
| Kâhin Uraz | `kahinler.json` › `kahinler.uraz` | uraz_24–43 |
| Kahve – Giriş | `kahve_giris.json` › `girisler` | 769–788 |
| Durugörü – Yarın | `durugoru_yno.json` › `durugoru_yno` | 40–59 |
| Durugörü – Gelecek | `durugoru_gno.json` › `durugoru_gno` | 67–86 |

## Tur 7–12 — 2026-11-05 akşam (sürüyor; ChatGPT + Codex, dosya eki sınırında içerik metin olarak)

| Kompartman | Dosya / anahtar | Eklenen id |
|---|---|---|
| Olumlama | `olumlamalar.json` › `olumlamalar` (M2 ham anahtar) | 515–554 |
| Acı Gerçekler | `acigercekler.json` › `acigercekler` | ag073–ag112 |
| Tavşan Falı | `tavsanfali.json` › `tavsanfali` | 181–220 |
| Niyet | `niyet.json` › `niyet` | 239–278 |
| Kâhin Likia | `kahinler.json` › `kahinler.likia` | likia_43–62 |
| Günlük Astroloji – Yorum | `gunlukastroloji.json` › `astroyorum` | 80–99 |
| Karşılama – 2./3./4. ziyaret | `karsilamalar.json` › `karsilamalar` (ziyaret 2-4) | 460–579 |
| Durugörü – Bugün | `durugoru_bno.json` › `durugoru_bno` | 131–150 |
| Motivasyon | `motivasyonlar.json` › `motivasyonlar` | 81–100 |
| Yana – Bana Dair | `yana.json` › `bana_dair` | 129–168 |
| Kahve – Gelişme | `kahve_gelisme.json` › `gelismeler` | 459–478 |
| Kâhin Derun | `kahinler.json` › `kahinler.derun` | derun_54–73 |
| Kâhin Khaleesi | `kahinler.json` › `kahinler.khaleesi` | khaleesi_52–71 |
| Kader Kitabı | `kaderkitabi.json` › `kaderkitabi` (M2) | 270–309 |
| Karşılama – 5. ziyaret | `karsilamalar.json` › `karsilamalar` (ziyaret 5) | 580–619 |
| Kâhin Yousuf | `kahinler.json` › `kahinler.yousuf` | yousuf_43–62 |
| Kahve – Sonuç | `kahve_sonuc.json` › `sonuclar` | 439–458 |
| Kahve – Giriş | `kahve_giris.json` › `girisler` | 789–808 |
| Kahve – Bağlama | `kahve_baglama.json` › `baglamalar` | 251–290 |
| Faloya (3) | `faloya.json` › `faloya` | 132–171 |

Not: Codex kullanım sınırı 18:10'da doldu (18:33'te açıldı) — Uraz, Giriş, Yarın, Gelecek Codex adımları ertelendi. Özlü Söz bilinçli olarak üretilmiyor (gerçek kişilere uydurma alıntı riski).

## Tur 4 — 2026-11-05 (160 metin; ilk tam ChatGPT + Codex turu)

| Kompartman | Dosya / anahtar | Eşleştirici | Eklenen id | Kaynak |
|---|---|---|---|---|
| Tavşan Falı (2) | `tavsanfali.json` › `tavsanfali` | M5 | 141–180 | ChatGPT 20 (Codex seçti) + Codex 20 (ChatGPT seçti) |
| Niyet (2) | `niyet.json` › `niyet` | M3 | 199–238 | aynı |
| Yana – Bana Dair (2) | `yana.json` › `bana_dair` | M4 | 89–128 | aynı |
| Kahve – Sonuç (2) | `kahve_sonuc.json` › `sonuclar` | M1 + konu | 419–438 | ChatGPT 10 + Codex 10 |
| Kahve – Gelişme (2) | `kahve_gelisme.json` › `gelismeler` | M1 + konu | 439–458 | ChatGPT 10 + Codex 10 |

## Tur 3 — 2026-11-05 (138 metin; cold reading + altın örnekler + kişiselleştirme; DeepSeek→Codex geçişi)

| Kompartman | Dosya / anahtar | Eşleştirici | Eklenen id | Kaynak |
|---|---|---|---|---|
| Durugörü – Bugün (2) | `durugoru_bno.json` › `durugoru_bno` | M1 | 113–130 | ChatGPT 10 (Codex seçti) + DeepSeek 8 (ChatGPT seçti; tekrarlılar elendi) |
| Kahve – Uğurlama | `kahve_ugurlama.json` › `ugurlamalar` | M1 + konu | 144–183 | ChatGPT 20 (Codex) + DeepSeek 20 (ChatGPT) |
| Kader Kitabı | `kaderkitabi.json` › `kaderkitabi` | M2 (ham anahtar) | 230–269 | ChatGPT 20 (Codex) + DeepSeek 20 (ChatGPT) |
| Kâhin Likia | `kahinler.json` › `kahinler.likia` | koşulsuz | likia_23–42 | ChatGPT 10 (Codex) + DeepSeek 10 (ChatGPT) |
| Kâhin Yousuf | `kahinler.json` › `kahinler.yousuf` | koşulsuz | yousuf_23–42 | ChatGPT 10 (Codex) + Codex 10 (ChatGPT) |

Notlar: DeepSeek brief'teki cold-reading örnek ifadelerini 20 metne aynen serpiştirdi (42 ortak 5-gram) → `metin_secim_temizle.js` eklendi; DeepSeek eşzamanlılığı ~2. Anıl: DeepSeek yerine Codex+ChatGPT. Kader Kitabı'nın ESKİ 25 koşullu metni ölü (`medeni durum=ilişkisi yok` biçimi; ekran `medeni_durum=iliskisi_yok` arar) — yeni metinler doğru biçimde.

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
