# Magnus — fal türlerinin metin seçme algoritmaları (2026-11-05)

> `magnus-metin-uretimi` skill'inin başvuru belgesi. Kaynak: koddan çıkarım (Explore ajanı, salt-okur).
> Yeni metin yazarken: kompartman görevi, uzunluk, yer tutucu ve KOŞUL ETİKETİ biçimi buradan.

## 0. Genel
- Çalışma anında yapay zekâ ile metin yazan tür YOK (Yüz Falı yalnız fotoğrafı sınıflandırır; metin JSON'dan).
  Rüya Yorumu Dart cümle havuzları (`dream_interpreter.dart`). Kısmetim/Arabam/Evim simülasyon motoru (yazılacak
  metin kompartmanı değil). Kullanılmayan dosyalar: `coffee_words.json`, `coffee_fortune.json`, `tarot.json`,
  `tarot_single_texts_{ask,dilek,sans}.json`, `ozlusoz_motivasyon.json`.
- Metin `metin`, İngilizcesi `metin_en` (yalnız EN dilde ve doluysa kullanılır).
- Yer tutucular `VariableReplacer.replace` (`lib/core/utils/variable_replacer.dart`); tanınmayan `{{...}}` SİLİNİR.
  - Cinsiyet: `{{data, cinsiyet=erkek, X | cinsiyet=kadin, Y | cinsiyet=belirtmek_istemiyorum, Z}}` — **`kadin` ASCII**
    yaz (`kadın` hiç eşleşmez → ilk seçenek basılır). `lgbt` yok.
  - Boşluksuz: `{{sayi,2,6}}`, `{{sabit_sayi,2,6}}`; `{{yil_N}}`/`{{gunsayi_N}}` yalnız `-?\d+` (**`{{yil_+1}}` bozuk** → `{{yil_1}}`).
    `{{ay_N}}`, `{{ay_+N}}`, `{{gun_N}}`, `{{yas_N}}`, `{{mevsim_N}}` ± kabul eder. `{{kelime, A | B}}` ve `{{data, …}}`
    anahtar kelimeden hemen sonra virgül ister. `{{randomtarih, 15, 50}}` boşluklu olabilir.
  - `{{gun_0}}` = haftanın günü ADI; ayın günü için `{{gunsayi_0}}`.
  - HEP BOŞ: `{{yukselen}}`, `{{ayburcu}}`, `{{zaman}}`, `{{sesliharf}}`, `{{isimsin}}`, `{{isimdin}}`, `{{saat kac}}`,
    `{{gözrengisoru}}`, `{{arabalar}}`, `{{pahalisaat}}`, `{{dogum sehrili}}`, `{{dogum saati}}`, `{{fizikierkek}}`,
    `{{gun,-7}}`, `{{yıl_N}}`; `{{soyisim}}` çoğu zaman boş.
  - ÇALIŞAN: `{{isim}}`, `{{isime}}`, `{{isimi}}`, `{{isimden}}`, `{{isimcigim}}`, `{{isim hanim/bey}}`, `{{harf}}`,
    `{{sabit_harf}}`, `{{isimilk|iki|son}}`, `{{yas}}`, `{{yas_N}}`, `{{burc}}`, `{{burc_ilkHarfBuyuk}}`, `{{rastgeleburc}}`,
    `{{meslek}}`, `{{medeni_durum}}`, `{{dogum gunu}}`, `{{dogum ayi}}`, `{{dogum yili}}`, `{{dogum ayi yazi}}`,
    `{{kullanici sehri}}`, `{{kullanici sehrinde}}`, `{{nereli}}`, `{{ay_N}}`, `{{gelecek_ay}}`, `{{gecen_ay}}`,
    `{{simdiki_ay}}`, `{{gun_N}}`, `{{gunsayi_N}}`, `{{yil_N}}`, `{{mevsim_N}}`, `{{randomtarih,a,b}}`,
    `{{saat, sabah|öğle|ikindi|akşam|gece}}`, `{{tam saat}}`, `{{saat kac yazi}}`, `{{kelime, A|B}}`,
    `{{sabitkelime, A|B}}`, `{{sayi,a,b}}`, `{{sabit_sayi,a,b}}`, `{{fiziki}}`, `{{kadinisim}}`, `{{erkekisim}}`,
    `{{xgundur}}`, `{{havadurumu sicaklik}}`, `{{kelimecins, erkek_X|kadin_Y}}`, `{{medenidurum, evli_X|bekar_Y}}`.
  - İşaretleme: `<color=yellow>`, `<color=#hex>`, `<b>`, `<i>`, `\r`, `\n\n`; `<sprite=N>` yalnız 0,5,7,10,23,73,79
    (AstroTakvim ayrıca 40,86,93,100). Kader Kitabı'nda `||` boşluğa çevrilir.

## 1. Profil sözlüğü ve EŞLEŞTİRİCİLER (etiket biçimi türe göre değişir!)
Ham değerler: cinsiyet `erkek|kadin|belirtmek_istemiyorum`; meslek `evhanimi, calismiyor, isariyor, ogrenci,
akademisyen, kendiisi, kamusektoru, ozelsektoru, emekli`; medeni `iliskisi_yok, platonik, iliski_var, flort, karisik,
yeni_ayrilmis, nisanli, evli, ayri_yasiyor, bosanmis, dul` (onboarding: iliskisi_yok, iliski_var, nisanli, evli,
bosanmis, dul, ayri_yasiyor); burç Türkçe; yaş int.
`toVariableMap`: `cinsiyet`=ham; `meslek`=etiket (Öğrenci, Kamu Sektörü, Özel Sektör, Ev Hanımı, Çalışmıyor, İş Arıyor,
Kendi İşini Yapıyor, Akademisyen, Emekli); `medeni_durum`=etiket (Bekar, Evli, İlişkisi Var…);
`medeni durum` (boşluklu)=varlık biçimi (ilişkisi yok, platonik, ilişkisi var, flört halinde, karmaşık, yeni ayrılmış,
nişanlı, evli, ayrı yaşıyor, boşanmış, dul).

| Eşleştirici | Türler | Kural | Yazılacak etiket |
|---|---|---|---|
| **M1** `fortune_service.dart:59-92` | Kahve, Tarot, El Falı, Durugörü (`_uygun`) | değişken içinde VEYA, değişkenler arası VE; küçük harf; yasmin/yasmax sayı; bilinmeyen değişken REDDEDER | `cinsiyet`: erkek/kadin · `meslek`: öğrenci, kamu sektörü, özel sektör, akademisyen, ev hanımı, çalışmıyor, emekli (iş arıyor/kendi işini yapıyor ÖLÜ: İ küçültme) · `medeni durum` (boşluklu): varlık biçimi · `yasmin/yasmax` |
| **M2** | Acı Gerçekler, Dert Ortağı, Biyoritim, Kader Kitabı (+yasmin/yasmax, iliski_durumu var/yok), Olumlama (+iliski_durumu) | ham anahtar, tam eşleşme, hepsi VE | `cinsiyet=kadin/erkek`, `medeni_durum=<ham>`, `meslek=<ham>` |
| **M3** Niyet | büyük/küçük harf duyarlı, hepsi VE; yas YOK | `cinsiyet=erkek/kadin`, `meslek=Öğrenci` (etiket), `medeni durum=evli` |
| **M4** Yana | değişken içinde VEYA; bilinmeyen GEÇER | `cinsiyet` kadin/erkek; `medeni_durum` Türkçe varlık değeri (evli, ilişkisi yok, ilişkisi var, nişanlı, boşanmış, dul, platonik, flört halinde, karmaşık, yeni ayrılmış); `meslek` Türkçe etiket (öğrenci, kamu sektörü, özel sektör…); yasmin/yasmax |
| **M5** Tavşan | ham anahtar, değişken içinde VEYA, küçük harf; bilinmeyen yok sayılır | `cinsiyet`, `medeni_durum=<ham>`, `meslek=<ham>` |
| **M6** Kader Çarkı | koşullar fiilen yok sayılır; değişken haritası yalnız isim/cinsiyet/medeni/meslek | yer tutucu: yalnız {{isim}}, tarih/saat, kelime, sayi, fiziki |
| **M7** Faloya | yalnız koşulsuz metinler gösterilir | koşul KOYMA |

## 2. Kahve Falı — 6 kompartman (M1 + fal_konusu)
Sıra: `kahve_akarsilama.json.karsilamalar` → `kahve_giris.json.girisler` → `kahve_baglama.json.baglamalar` →
`kahve_gelisme.json.gelismeler` → `kahve_sonuc.json.sonuclar` → `kahve_ugurlama.json.ugurlamalar`, her birinden 1, `\n\n`.
Seçim: M1 → `fal_konusu` (genel/ask/kariyer/saglik; seçilen konu yoksa genel; "genel" için 15 basamaklı merdiven) →
no-repeat `kahve_${bolum}_${konu}_shown_ids`. Şema `{id, metin, metin_en, kosullar, fal_konusu:[…]}`.

| Kompartman | n | ort. karakter | görev |
|---|---|---|---|
| karşılama | 346 | 307 | selam, falı sunma |
| giriş | 748 | 631 | fincanda görülen İLK sembol |
| bağlama | 250 | 165 | 1-2 cümlelik köprü |
| gelişme | 418 | 1119 | ana semboller + öngörüler, çoğu `{{ay_N}}`/`{{sayi}}` tarihli |
| sonuç | 398 | 623 | fincanın dibine yakın semboller + sonuç |
| uğurlama | 143 | 217 | veda, çoğu "\n\nMagnus" ile biter |
Üslup: Magnus birinci tekil ("görüyorum", "gözüme çarptı"), "sen"e, sıcak, hafif esprili, telve imgeleri.

## 3. Tarot
- Klasik 3 kart: `tarot_texts.json.tarot_metinleri` `{id, pozisyon: gecmis|simdi|gelecek, kart, ters, metin, kosullar, metin_en}`;
  her (pozisyon,kart,ters) için 1 metin. Yeni: düz kart adı (`Adalet`) + `ters:true` (Ters ön eki/numara YOK). M1.
- Tek kart: `tarot_single_texts.json.tarot_single_metinleri` `{tur: ask|dilek|sans, kart:"<JsonAd> 1", …}`; kart başına tür başına 1.

## 4. Günlük Astroloji (`gunlukastroloji.json`)
10 bölüm sırayla birer metin: giris(2) → astroyorum(77, ~1131, `{{burc}}`,`{{isim}}`) → astrogununsozu(45) →
astrogununayeti(45) → astrogununhadisi(50) → astroeglencelibilgi(66) → astrokesif(40) → astrogununismi(45) →
astrogununyemegi(31) → astroveda(4). Gün boyu aynı; yeni gün no-repeat. Koşul YOK SAYILIR.

## 5. Biyoritim (`biyoritim.json`)
b1(7) → b2a duygusal / b2b fiziksel / b2c entelektüel / b3a aşk şansı / b3b para şansı (her biri `0-25|25-50|50-75|75-100`
aralık alt anahtarı, ~50/aralık, 80-144 kr) → b4 çakra(59) → b5 Çin takvimi(60, `{{burc_ilkHarfBuyuk}}`). M2.

## 6. Doğum Haritası — `ana` + bolum1(31) + bolum2(30) + bolum3(33) + `son1`; tek cümlelik günlük öngörü (~95 kr); koşul yok sayılır.
## 7. AstroTakvim — transit(90)/transit_tarihli(30)/maneviyat/guzellik/saglik(90)/aktivite(88); deterministik gün indeksi; `{metin, metin_en}` id yok.
## 8. Motivasyon — `motivasyonlar.json.motivasyonlar` 80; gün boyu aynı; ~530 kr, aforizmatik paragraflar, `{{isim}}`.
## 9. Olumlama — `olumlamalar.json.olumlamalar` 514; M2 (etiket: `medeni_durum=evli`, `cinsiyet=kadin`, `meslek=ogrenci`); ~98 kr, birinci tekil, `<color=yellow><b>…</b></color>`.
## 10. Özlü Sözler — 655; günde 10'lu oturum; ~122 kr tırnaklı aforizma.
## 11. Acı Gerçekler — 72 (`id` string); M2; ~296 kr, kişisiz sert yaşam gerçekleri, yer tutucu yok.
## 12. Kader Kitabı — 229; M2 (+yasmin/yasmax, iliski_durumu); ~279 kr, `||` ile ayrılmış iki aforizma.
## 13. I-Ching (37, ~2510 kr) / Japon Falı (27, ~2724 kr, markdown başlıklı Omikuji) — gelen kutusuna; no-repeat.

## 14. Durugörü — 3 soru (M1, değişken adı küçültülür)
- Bugün `durugoru_bno.json.durugoru_bno` 92 — **BOZUK**: hepsinde saatmin/saatmax → havuz boş. Yeni Bugün metnine saat koşulu KOYMA.
- Yarın `durugoru_yno.json.durugoru_yno` 19 (~867 kr).
- Gelecek `durugoru_gno.json.durugoru_gno` 46 (~517 kr): "Geleceğine odaklandığımda, seni {{ay_5}} ayında … görüyorum {{isim}}".
Üslup: Magnus somut sahneler "görür", bazen "Magnuskop".

## 15. Dert Ortağı — `dertortagi.json.dertler.{genel,ask,saglik,kariyer}` 50'şer `{id:"g001", metin(~30 kr dert), kosullar, dermanlar:[5]}`; metin_en YOK; M2.
## 16. Kader Çarkı — `kadercarki_{alev(130)|hayvan(32)|kure(31)|renk(31)|tas(31)|zar(49)}.json`; M6 (koşul yok sayılır, yer tutucu kısıtlı).

## 17. Kehanet grubu
- **Faloya** 111 (yalnız 47 koşulsuz görünür, M7); ~354 kr; "Merhaba {{isim}}.\n\nVarlıklar fısıldıyor...\n\nGeleceğine dair bir öngörüm var.\n\nÖnümüzdeki {{sayi,1,28}} {{ay_2}} tarihinde, …".
- **Kâhinler** `kahinler.json.kahinler.{derun(33), khaleesi(31), likia(22), uraz(23, "siz"), yousuf(22)}` — her kâhinin kendi kişiliği; koşul yok.
- **Maganda** `sorular`(36)/`cevaplar`(36); cevap `\n\n` ile bölünüp tek paragraf gösterilir (soru eşleşmesi BOZUK).
- **Niyet** 178; M3; ~214 kr gelecek zaman kehanet; `{{kelime}}`, `{{sayi}}`.
- **Tamua** `tamua.{olacak, olacakh, olacakl, olmayacak, olmayacakh, olmayacakl}`; `ses_index` ses dosyası gerektirir (yeni metin ekleme zor).
- **Yana** `yana.json.bana_dair`(68, tur:"bana", ~320 kr, "Magnuskop'u 3 sene sonrası için ayarladığımda, seni … görüyorum {{isim}}") ve `yasama_dair`(110, ~358 kr, dünyanın geleceği); M4.
- **El Falı** `elfali.json` genel_degerlendirme(64) + 10 hat × 4 yüzde aralığı; metin_en yok. **Yüz Falı** öznitelik bazlı havuzlar; metin_en yok.

## 18. Aşk Uyumu — `askuyumu.json` bars.{ask,aile,maddi,ten,vizyon,iletisim}.{0-25..75-100} (~30/aralık, 67-115 kr, "siz/ikiniz") + uyum.{evli(60), iliskisivar(48), iliskisiyok(36)} burç başına (~1000 kr).
## 19. Tavşan Falı — `tavsanfali.json.tavsanfali` 120; M5; 97-142 kr; "{{isim}}, <zaman> <somut olay>. <devamı>."
## 20. Numeroloji — deterministik sayı metinleri (genel/bugun/yil × 7 bölüm × 1-9).
## 21. Ana menü karşılama — `karsilamalar.json` ilk_giris / ozel_gunler(29) / karsilamalar(ziyaret 1-6) / biliyormuydun(33).

## 22. Bilinen hatalar (metin yazarken/etiketlerken dikkat)
1. `cinsiyet=kadın` (ı) ve `lgbt` hiç eşleşmez → `kadin` yaz.
2. Durugörü "Bugün" havuzu boş (saatmin/saatmax).
3. Ters tarot kartları başka kartın metnini alır (`kart:"TersX"`).
4. Faloya koşullu metni göstermez; Kader Çarkı koşulları yok sayar.
5. Maganda cevabı soruyu dikkate almaz.
6. Değişken adı yazımı eşleştiriciye göre değişir (tablo §1).
7. `{{yil_+N}}` ve boşluklu `{{sayi, a, b}}` boş basılır.
