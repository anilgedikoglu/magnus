# Magnus reklam düzeni (2026-11-09)

Ürün kararı. Anlaşılmadan değiştirilmesin; gerekçeler AdMob politikalarına dayanır.

## Temel kurallar
- **Ödüllü reklam yalnız kullanıcı açıkça seçince gösterilir.** Önce ödül ve eylem yazılır ("Reklam izle: +1 Kahve Falı hakkı"), iki eşit düğme: izle / vazgeç. Reddetmek normal kullanımı engellemez. Metin yönlendirmez, korkutmaz.
- Ödül yalnız `onUserEarnedReward` gelince verilir. Reklam kapatıldıysa ya da gösterilemediyse ödül yok.
- Hazır reklam yoksa teklif gösterilmez (hak dolduysa eski mesaj; kutularda içerik ücretsiz açılır).
- Rastgele içerik "ödül" diye sunulmaz; ödül belirli olur: +1 hak, falı hemen aç, kutuyu aç.
- **Geçiş reklamı yalnız doğal arada:** fal veya okunan fal kapanıp menüye dönerken. Açılışta, içerik/okuma sırasında, her dokunuşta, üst üste YOK.
- Geçiş sınırı (kalıcı): en az 180 sn aralık, oturumda 2, günde 5. Uygulamada 2 fal tamamlanmadan geçiş yok. Dert Ortağı çıkışında hiç yok.
- Ödüllü sınırlar (kalıcı): hak bitti +1 tür başına 1, günde toplam 3; hemen aç günde 3; kutu açma günde 6; hepsi toplam günde 10.

## Yerler
| Yer | Biçim |
|---|---|
| Hak bitti (Kahve, Tarot, Durugörü, Dert Ortağı, Acı Gerçekler, Aşk Uyumu) | Teklif penceresi → ödüllü → +1 hak ve fal açılır |
| Gelen kutusunda hazırlanan fal kartı | Teklif penceresi → ödüllü → fal hemen hazır |
| Kısmetim, Arabam, Evim kapalı kutu | Teklif penceresi → ödüllü → o kişi/dönemin kutuları açılır |
| Fal ekranından menüye dönüş, okunan faldan çıkış | Geçiş (sınırlarla) |

Japon Falı, I-Ching, Kader Çarkı, Tavşan ve Kader Kitabı: havuz küçük ya da günlük ritüel, ek hak yok.

## Rıza ve gizlilik
- UMP: her açılışta bilgi güncellenir, gerekirse form; `canRequestAds` olmadan reklam istenmez. Hata olursa reklam akışı bozulmaz.
- iOS: ATT yok, istekler `nonPersonalizedAds: true`, Info.plist'te SKAdNetworkItems.
- AdMob panelinde GDPR mesajı oluşturulmalı (uygulama dışı adım).
