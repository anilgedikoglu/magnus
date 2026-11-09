# Magnus reklam düzeni (güncel: 2026-11-09, gelir odaklı ayar)

Ürün kararı. Anlaşılmadan değiştirilmesin; gerekçeler AdMob politikalarına ve Magnus'un kendi AdMob verisine dayanır.

## Temel kurallar
- **Ödüllü reklam yalnız kullanıcı açıkça seçince gösterilir.** Önce ödül ve eylem yazılır ("Reklam izle: +1 Kahve Falı hakkı"), iki eşit düğme: izle / vazgeç. Reddetmek normal kullanımı engellemez. Metin yönlendirmez, korkutmaz.
- Ödül yalnız `onUserEarnedReward` gelince verilir. Reklam kapatıldıysa ya da gösterilemediyse ödül yok.
- Hazır reklam yoksa teklif gösterilmez (hak dolduysa eski mesaj; kutularda içerik ücretsiz açılır).
- Rastgele içerik "ödül" diye sunulmaz; ödül belirli olur: +1 hak, falı hemen aç, kutuyu aç.
- **Geçiş reklamı yalnız doğal arada:** fal veya okunan fal kapanıp menüye dönerken. Açılışta, içerik/okuma sırasında, her dokunuşta, üst üste YOK.
- Geçiş sınırı (kalıcı): önceki reklamdan (geçiş ya da ödüllü) en az 120 sn sonra, oturumda 3, günde 6. Uygulamada 2 fal tamamlanmadan geçiş yok. Dert Ortağı çıkışında hiç yok.
- Ödüllü sınırlar (kalıcı): hak bitti +1 tür başına 2, günde toplam 6; hemen aç günde 5; kutu açma günde 8; hepsi toplam günde 15.

## Yerler
| Yer | Biçim |
|---|---|
| Hak bitti (Kahve, Tarot, Dert Ortağı, Acı Gerçekler, Aşk Uyumu, I-Ching, Japon Falı, Tavşan, Kader Çarkı) | Teklif penceresi → ödüllü → +1 hak ve fal açılır |
| Durugörü'de bugün sorulmuş soru (kendi ekranında) | Teklif penceresi → ödüllü → o soru yeniden sorulur |
| Gelen kutusunda hazırlanan fal kartı (30 sn'den fazla kaldıysa) | Kartta "Reklam izle, hemen aç" işareti → teklif → ödüllü → fal hemen hazır |
| Kısmetim, Arabam, Evim kapalı kutu | Teklif penceresi → ödüllü → o kişi/dönemin kutuları açılır |
| Fal ekranından menüye dönüş, okunan faldan çıkış | Geçiş (sınırlarla) |

Kader Kitabı günlük ritüel; astroloji, biyoritim, doğum haritası gün boyu aynı metni verdiği için ek hak yok.

## Kullanılmayan biçimler
- **Banner:** gelirin küçük kısmını getirir, yüzen cam barla çakışır.
- **App Open:** açılışta yasal bilgilendirme ve ritüel var; elde kullanıcı verisi olmadan elde tutma riski alınmadı. 30 günlük veriden sonra yeniden değerlendirilir.
- **Uyumlulaştırma:** bu trafikte getirisi kurulum yükünü karşılamaz.

## Veri (AdMob, 2026-10-10 – 11-08, Magnus iOS + Android, eski mağaza sürümleri)
- Ödüllü: 1.106 gösterim, ₺234; eBGBM Android ₺190, iOS ₺278.
- Geçiş: 1.411 yükleme, **0 gösterim**. Kullanıcıların sürümü 10.8.5: reklam açılışta yükleniyor, gösteren çağrı kodda yok.
- Hesaptaki diğer uygulamalarda geçiş eBGBM: iOS ₺142-145, Android ₺40.
- Firebase bağlı olmadığı için kullanıcı sayısı AdMob'da yok; geçiş istekleri günde yaklaşık 47 oturuma işaret ediyor (tahmin).

## Teknik
- Yüklenen reklam 55 dakikadan eskiyse atılır, yenisi istenir (`AdService.reklamOmru`). Uygulamaya dönüşte ve teklif öncesinde eksik reklam yeniden istenir.

## Rıza ve gizlilik
- UMP: her açılışta bilgi güncellenir, gerekirse form; `canRequestAds` olmadan reklam istenmez. Hata olursa reklam akışı bozulmaz.
- iOS: ATT yok, istekler `nonPersonalizedAds: true`, Info.plist'te SKAdNetworkItems.
- AdMob panelindeki GDPR mesajı yayında; Magnus'un iki uygulamasının gizlilik adresi düzeltildi (2026-11-09).
