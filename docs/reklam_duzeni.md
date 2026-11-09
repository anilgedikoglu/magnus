# Magnus reklam düzeni (güncel: 2026-11-09, gelir odaklı ikinci ayar)

Ürün kararı. Anlaşılmadan değiştirilmesin; gerekçeler AdMob politikalarına ve Magnus'un kendi AdMob verisine dayanır.

## Temel kurallar
- **Ödüllü reklam yalnız kullanıcı açıkça seçince gösterilir.** Önce ödül ve eylem yazılır, iki eşit düğme: izle / vazgeç. Metin yönlendirmez, korkutmaz.
- Ödül yalnız `onUserEarnedReward` gelince verilir. Reklam kapatıldıysa ya da gösterilemediyse ödül yok.
- Hazır reklam yoksa: hak dolduysa eski mesaj; kutu ve Aşk Uyumu genel yorumu ücretsiz açılır. Yüklenmekte olan reklam 2,5 sn beklenir (`AdService.odulluBekle`).
- **Günlük sınırlar reklamdan bağımsızdır** (kehanet dahil): reklam yoksa ya da reddedilirse "yarın gel". Google: reddetmek normal kullanımı engellememeli; sınır reklam olmasa da aynı olduğu için red ceza olmaz. Aşk Uyumu yorumu ve kutular ek içeriktir.
- Ödül belirli olur: +1 hak, falı hemen aç, kutuyu aç, yorumu aç, 3 kehanet.
- **Fal metni ortadan kesilmez.** Temel sonuç hep ücretsizdir; kilitlenen yalnız ek parçadır.
- **Geçiş reklamı yalnız doğal arada:** fal tamamlanıp menüye dönerken ya da okunan faldan çıkarken. Açılışta, içerik/okuma sırasında, her dokunuşta, üst üste YOK. Reddedilen fal (fincan onaylanmadı vb.) sonrası yok.
- Geçiş sınırı (kalıcı): önceki reklamdan (geçiş ya da ödüllü) en az 120 sn sonra, oturumda 3, günde 6. İlk 2 fal tamamlanmadan yok. Dert Ortağı çıkışında yok. Ekranda kalma: gelen kutusuna düşen falda en az 4 sn, sonucu ekranda gösteren falda en az 25 sn.
- Ödüllü sınırlar (kalıcı): hak bitti tür başına 2, günde toplam 6; hemen aç günde 5; kutu/yorum açma günde 8; hepsi toplam günde 15.

## Yerler
| Yer | Biçim | Ödül |
|---|---|---|
| Sonucun sonunda, hak kullanılmışsa: Kahve, Tarot, I-Ching, Japon (fal detayında), Aşk Uyumu, Kader Çarkı, Tavşan, Acı Gerçekler (`BirTaneDaha`) | Düğme → teklif → ödüllü | Fal hemen yeniden açılır |
| Menüde hak bitti (yukarıdakiler + Dert Ortağı) | Teklif → ödüllü | +1 hak |
| Durugörü'de bugün sorulmuş soru | Teklif → ödüllü | Soru yeniden sorulur |
| Gelen kutusunda hazırlanan fal (30 sn'den fazla kaldıysa) | "Reklam izle, hemen aç" → teklif → ödüllü | Fal hemen açılır ve okunur |
| Kısmetim, Arabam, Evim kapalı kutu | Teklif → ödüllü | Kutu(lar) açılır |
| Aşk Uyumu genel uyum yorumu (6 çubuk ve yüzde ücretsiz) | Düğme → teklif → ödüllü | Yorum açılır |
| Kehanet menüsü, günün 4. girişinden sonra | Teklif → ödüllü | 3 giriş |
| Fal tamamlanıp menüye dönüş, okunan faldan çıkış | Geçiş (sınırlarla) | - |

Kader Kitabı günlük ritüel; astroloji, biyoritim, doğum haritası gün boyu aynı metni verdiği için ek hak yok.
Aşk Uyumu yüzdeleri kullanıcı burcu + seçilen burç + güne göre sabittir: aynı gün aynı burca bakan aynı yüzdeyi görür.

## Kullanılmayan biçimler
- **Zorunlu ödüllü:** politika ihlali (eski sürümde vardı); aynı hesaptaki diğer uygulamaları da riske atar.
- **Rewarded interstitial:** Google'da beta; giriş ekranı ve vazgeç zorunlu. Karma geçiş eBGBM'si ₺80'in altında çıkarsa fal gönderim anında geçişin yerine denenir (14 gün veriden sonra).
- **Banner:** tahmini günlük ₺0,5-1,5; yüzen cam bara yakınlık kazara tıklama riski.
- **App Open:** açılışta 6 sn yasal perde var; günde yaklaşık 300 oturum olmadan değmez.
- **Uyumlulaştırma:** bu trafikte kurulum yükünü karşılamaz.

## Veri (AdMob, 2026-10-10 – 11-08, Magnus iOS + Android)
- Ödüllü: 1.106 gösterim, ₺234; eBGBM Android ₺190, iOS ₺278.
- Geçiş: 1.411 yükleme, **0 gösterim**. Kullanıcıların sürümü 10.8.5: reklam açılışta yükleniyor, gösteren çağrı kodda yok; zorunlu ödüllü çalışıyor.
- Hesaptaki diğer uygulamalarda geçiş eBGBM: iOS ₺142-145, Android ₺40 (çocuk uygulaması, Magnus'a uymaz).
- Firebase bağlı olmadığı için kullanıcı sayısı AdMob'da yok; geçiş istekleri günde yaklaşık 47 oturuma işaret ediyor (tahmin).
- Hedef (üretimden 14 gün sonra): ödüllü ≥ 15/gün, geçiş ≥ 25/gün, toplam ≥ ₺6/gün, AdMob politika uyarısı 0.

## Teknik
- Yüklenen reklam 55 dakikadan eskiyse atılır, yenisi istenir (`AdService.reklamOmru`). Uygulamaya dönüşte ve teklif öncesinde eksik reklam yeniden istenir.

## Rıza ve gizlilik
- UMP: her açılışta bilgi güncellenir, gerekirse form; `canRequestAds` olmadan reklam istenmez. Hata olursa reklam akışı bozulmaz.
- iOS: ATT yok, istekler `nonPersonalizedAds: true`, Info.plist'te SKAdNetworkItems.
- AdMob panelindeki GDPR mesajı yayında; Magnus'un iki uygulamasının gizlilik adresi düzeltildi (2026-11-09).
