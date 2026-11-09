# Magnus reklam defteri

Hangi reklamı nereye koyduğumuzun ve bunun geliri artırıp azaltmadığının kaydı. Kurallar ve gerekçeler için `docs/reklam_duzeni.md`. Her reklam değişikliği buraya satır olarak girer; kontrol tarihi gelince "Sonuç" doldurulur.

## Nasıl ölçülür

- **Gelir:** AdMob → Raporlar → kırılım `Uygulama` + `Reklam biçimi` + `Uygulama sürümü`. Bakılacaklar: tahmini kazanç, gösterim, eBGBM, istek, eşleşme oranı. Android ve iOS ayrı.
- **Tutma:** Play Console "Elde tutma" ve kaldırma sayısı; App Store Connect "Elde tutma" (1. ve 7. gün).
- **Karşılaştırma:** üretime çıktıktan sonraki 14 gün, önceki 14 güne göre. Toplam kazançla birlikte tutma da düşmediyse değişiklik başarılı sayılır.
- **Sınır:** Her biçim için tek reklam birimi var, AdMob'da yerleşim bazında ayrım yapılamıyor; Firebase bağlı değil. Bu yüzden bundan sonra **her sürümde tek grup reklam değişikliği** çıkılır. Birkaç değişiklik aynı sürümde çıktıysa sonuç gruba yazılır, tek tek ayrılamaz.
- Günde yaklaşık 47 oturumda küçük farklar gürültüdür. %20'nin altındaki farktan kesin sonuç çıkarılmaz.

## Başlangıç verisi (AdMob, 2026-10-10 – 2026-11-08, yayındaki sürüm 10.8.5)

| Biçim | İstek | Gösterim | Kazanç | eBGBM |
|---|---|---|---|---|
| Ödüllü | - | 1.106 (Android 829, iOS 277) | ₺234 | Android ₺190, iOS ₺278 |
| Geçiş | 1.411 | 0 | ₺0 | - |

Tutma verisi henüz alınmadı; 312 üretime çıkmadan önce Play Console'dan yazılmalı.

## Değişiklik defteri

Kontrol tarihi = üretime çıkış + 14 gün. Test kanalındaki sürümler gelir ölçümüne girmez.

| No | Tarih | Sürüm | Yer | Değişiklik | Beklenti | Üretime çıkış | Kontrol | Sonuç |
|---|---|---|---|---|---|---|---|---|
| 1 | 2026-11-09 | 306-309 | Tüm uygulama | Zorunlu ödüllü kalktı; ödüllü yalnız isteğe bağlı (hak bitti, hemen aç, kutular, kehanet, bir tane daha) | Ödüllü gösterim başta düşebilir, politika riski kalkar | | | |
| 2 | 2026-11-09 | 306-309 | Fal çıkışları | Geçiş reklamı ilk kez gösteriliyor (90 sn, oturum 3, gün 6, ikinci faldan itibaren) | Geçiş gösterimi 0'dan ≥25/güne | | | |
| 3 | 2026-11-09 | 312 | Fal türlerinden geri tuşuyla menüye dönüş | Geçiş KALDIRILDI (sonucu ekranda gösteren tüm türler). Sahibin kararı: gezinirken reklam kullanıcıyı kaçırır | Geçiş gösterimi azalır, tutma korunur | | | |
| 3a | 2026-11-09 | 312 | Sonuçtan hemen önce | **Düz geçiş** reklamı (sahibin kararı, politika riski bilerek alındı). Gelen kutusu falı açılmadan, ritüel bitince, ritüelsiz falda açılırken. Karşılığında fal gönderilince ve okunan faldan çıkışta geçiş kapandı | Merak en yüksekken gösterim artar; tutma izlenecek, politika uyarısı izlenecek | | | |
| 4 | 2026-11-09 | 312 | I-Ching, Japon sonu | "Bir tane daha" ödüllü düğmesi eklendi | Ödüllü gösterim artar | | | |
| 5 | 2026-11-09 | 312 | Teklif penceresi | Alttan yerine ekranın ortasında | Teklif kabul oranı artabilir | | | |

## Güncel yerleşim (312)

`G` geçiş, `Ö` ödüllü, `-` reklam yok.

| Nokta | Reklam |
|---|---|
| Uygulama açılışı, yasal perde, arka plandan dönüş, sekme geçişi | - |
| Menüde hak bitti | Ö +1 |
| Menüden ritüelsiz türe dokunuş (Astroloji, AstroTakvim, Biyoritim, Doğum Haritası, Motivasyon, Olumlama, Özlü Söz, Kader Kitabı), fal açılmadan | G |
| Gelen kutusu: fal hazırlanıyor, 60 sn'den fazla kaldı | Ö hemen aç (izleyene ek geçiş yok) |
| Gelen kutusu: hazır, okunmamış fala dokunuş, fal açılmadan | G |
| Tekrar okunan fal, fal okuma, fal gönderilince menüye dönüş, okunan faldan ya da fal türünden geri tuşuyla çıkış | - |
| Fal detayı sonu (kahve, tarot, I-Ching, Japon; hak kullanılmışsa) | Ö bir tane daha |
| Dert Ortağı: yükleme bitti, derman gösterilmeden | G |
| Kader Çarkı: çark durdu, sonuçtan önce | G; sonuç sonu Ö |
| Tavşan: animasyon bitti, nottan önce | G; not sonu Ö |
| Aşk Uyumu: bekleme bitti, sonuçtan önce | G; sonu Ö başka burç |
| Acı Gerçekler: nabız bitti, kağıt yanmadan önce (yazı yanan kağıtla açılıyor) | G; sonu Ö |
| Kısmetim, Arabam, Evim: arama bitti, sonuçtan önce | G; kapalı kutu Ö |
| Faloya, Maganda, Tamua, Yana, her kahin: ritüel bitti, cevaptan önce | G |
| Niyet: kazıma açıldı, metinden önce · Rüya serbest metin: perde bitti, sonuçtan önce | G |
| Kehanet menüsü: günde 3 giriş, sonra +3 | Ö |

Sınırlar: geçişten 90 sn, ödüllüden 120 sn sonra; oturumda 3, günde 6, ilk falın çıkışında yok. Ödüllü toplam günde 15.

## ⚠️ Bilerek alınan politika riski (2026-11-09)

Sonuçtan hemen önceki düz geçiş reklamı, [Google Play Reklam Politikası](https://support.google.com/googleplay/android-developer/answer/9857753?hl=en)'nın ihlal örneklerine giriyor (düğmeye basıldıktan sonra iş gerçekleşmeden; içerik başlangıcında). Üç yapay zekâ da karşı çıktı; sahibi riski kabul etti.

**Uyarı, politika e-postası ya da AdMob sınırlaması gelirse hemen:** aynı noktalar atlanabilir reklama çevrilir (rewarded interstitial: önce kısa giriş ekranı, ödül yazılı, "Atla" düğmesi; atlayan fala geçer). Bunun için iki platformda rewarded interstitial reklam birimi açılır, `lib/core/services/sonuc_reklami.dart` içindeki `sonucOncesiReklam` değişir. Birim hazır olana kadar acil çözüm `kSonucOncesiReklam = false`: reklam eski yerlerine (fal gönderilince, okunan faldan çıkınca) döner.

## Bilerek yapılmayanlar

- **Okuma ve ritüel ortası:** kullanıcı bir işe odaklanmışken reklam yok.
- **Gönder'e basınca:** fal gönderimi kesilmez.
- **Fal türlerinden geri tuşuyla çıkışta geçiş:** üç yapay zekâ önerdi, sahip reddetti; kullanıcı daha uygulamayı gezerken reklam yiyip kaçar.
- **Sınırları yükseltmek/düşürmek:** Gemini 75 sn, 4/oturum, 8/gün; DeepSeek 2/oturum, 5/gün önerdi; ChatGPT mevcut sınırları korudu. Veri gelene kadar değişmedi.
- **Kahinlere Sor'da kahin başına ödüllü:** yalnız DeepSeek önerdi; ChatGPT aynı girişte sınırsız kullanımın korunmasını söyledi.

## Dış görüş (2026-11-09; ChatGPT, DeepSeek, Gemini; her nokta tek tek soruldu)

Üçü de (sahip bu görüşün bir kısmını reddetti; yukarıya bakın): açılış, karta dokunuş, sonuçtan hemen önce, okuma ortası, sekme ve arka plan dönüşünde geçiş yok; hak bitti, hemen aç, fal sonu, kapalı kutular, Kehanet +3 ve başka burçta ödüllü; fal bitip menüye dönüşte geçiş. Gelir sırası tahminidir, ödüllü kabul oranı ölçülmeden hesaplanamaz. Codex kullanım sınırındaydı (11 Kasım 21:56).

## Sonraki kontrol

312 üretime çıkınca "Üretime çıkış" ve "Kontrol" sütunlarını doldur. Kontrol gününde AdMob ve tutma sayılarını "Sonuç"a yaz.
