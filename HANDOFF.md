# HANDOFF — Magnus App

> Claude ↔ Codex ↔ diğer oturumlar için güncel devir teslim. Ayrıntılı proje hafızası: `CLAUDE.md`.

## Ne yapıldı (2026-11-06 — FOTO ÖN KONTROL: fincan/el/yüz; main'e push, BUILD ALINMADI)
Anıl: kahve/el/yüz fallarına, gönderilen foto gerçekten fincan/el/yüz mü anlayan OFFLINE ön kontrol. Değilse
"Ben bu fotoğraftan bir X göremiyorum, karışıklık olmuş olabilir mi?" uyarısı; fal başlamaz, günlük hak tüketilmez.
- **Yeni: `lib/data/services/photo_subject_detector.dart`** — `PhotoSubjectDetector.uygunMu(path, FotoKonu{yuz,el,fincan})`.
  ENSEMBLE (HOŞGÖRÜLÜ — yalnız EMİN olunca false; hata/belirsizlik→true, asla çökmez):
  (1) ML Kit yüz tespiti `FaceLandmarks.durumu()` (yeni, üç-durumlu: bulundu/yok/kullanilamaz),
  (2) ML Kit görüntü etiketleme `ImageLabels.etiketler()` (yeni, `image_labels.dart`; Hand/Nail, Coffee/Cup/Cappuccino,
  Selfie/Hair/Beard/Mouth/Ear...), (3) YCbCr ten oranı (`image` paketi).
  - yuz: yüz bulundu → kabul; güçlü yüz etiketi → kabul; el/fincan etiketi → ret; yüz YOK (tespit çalıştı) → **ret**
    (kapının amacı; portre selfie'de ML Kit accurate güvenilir; etiket yedeği + "Tekrar Dene" yanlış-reddi hafifletir).
  - el: Hand/Nail etiketi → kabul; fincan etiketi → ret; **bol ten (≥0.35) → kabul (yüz de kadrajdaysa bile, Codex)**;
    yüz var + az ten → ret (selfie); ten≥0.12 kabul; ten<0.03 → ret.
  - fincan: Coffee/Cup etiketi → kabul (en güçlü); yüz bulundu → ret; Hand/yüz etiketi → ret; ten≥0.55 → ret (son çare).
  - **Ten maskesi gri/beyaz HARİÇ** (Codex: eski maskede gri fincan/masa/duvar ten sayılıyordu): cr≥137 + r>b+12.
- **ML Kit sürüm hizalama (pubspec):** `google_mlkit_face_detection` 0.13.2 → **0.13.0 SABİT** + yeni
  `google_mlkit_image_labeling: 0.14.0` → ortak **commons ^0.10.0** (lock: commons 0.10.0). 1.0.0 train Flutter 3.44
  ister (bizde 3.41.5) → kullanılamaz. 0.13.2 (commons ^0.11.0) image_labeling ile çakışıyordu. API değişmedi;
  iOS 15.5 min aynı (aynı GoogleMLKit pod ailesi). ⚠️ **iOS'ta YENİ pod (ImageLabeling) eklendi → cihaz build'inde doğrula.**
- **3 ekran bağlandı:** `yuz_fali_foto_screen.dart` (_analizEt başına ön kontrol; günlük hak artık kontrol GEÇİNCE),
  `el_fali_screen.dart` (yeni `hatali` state + `_buildHatali`; günlük hak taşındı), `coffee_screen.dart`
  (`_sendFortune` ön kontrol — 3 fotoda ilk kabulde dur, üçü de retse `_showFincanUyari` dialog; "Yerime İç" atlanır).
  Günlük hak pref'leri (`yuzfali_bugun_tarih`/`elfali_bugun_tarih`) artık yalnız kontrol geçince yazılır →
  yanlış fotoda hak gitmez (`yuz_fali_kimin_screen`/el `_kontrolEt` gate'iyle tutarlı).
- **Codex bug avı düzeltmeleri (kahve):** (P1) çift gönderim — `_sending` artık giriş korumasında + buton aktifliğinde;
  (P2) kontrol edilen≠gönderilen — fotoğraflar await ÖNCESİ sabitlenip üretime öyle veriliyor.
- **Metinler** (`app_strings.dart`): `photoNotCup/photoNotHand/photoNotFace` TR+EN. **Test** `photo_subject_detector_test.dart`
  (10, sezgi yolu: ten→el kabul/fincan ret, gri→el ret/fincan kabul, bozuk/yok dosya→çökmez). analyze temiz; 196 test geçer
  (tek kırmızı: git'te olmayan `_visual_starfield_capture_test.dart`).
- ⏭️ **Codex P2 (kapsam dışı, ayrı task açıldı):** kahve falında kullanıcı "gönderiliyor" 4 sn'si dolmadan çıkarsa fal
  üretilir ama `kahveSentProvider` yazılmaz → günlük hak işaretlenmez (günde 1 delinebilir). Krediyi üretim başında
  idempotent işaretle. (El/yüz offline muamelesi gibi kahve/el hâlâ ClaudeVisionService API — istenirse offline'a çekilir.)

## Ne yapıldı (2026-11-06 sabah, 279 sonrası cihaz geri bildirimi; main'de, BUILD ALINMADI)
Anıl 279'u cihazda gezip düzeltme istedi. Hepsi commit+push (build YALNIZ "test çık" deyince):
- **CAM/GLASS kaydırıcısı** (`settings_screen.dart`, `_glassDragProvider`): parmakla çekilirken profil→gelen
  kutusu TabSwipe kilitlenir (kaydırıcının Listener'ı TabSwipe'tan daha içte → pointer-down'da enabled false).
  Test `tab_swipe_test.dart`.
- **Kader Kitabı** (`kaderkitabi_screen.dart`, `kader_book_scene.dart`): (1) sudan DÜZ çıkar (rise Z-tilt
  kaldırıldı). (2) Dokunuş pop-up AÇMAZ; metin iki sayfaya sığmazsa dokunuş sonraki açılıma geçer
  (`paginateKaderPages`, küçültmesiz; sayfa noktaları `_PageDots`) — sığıyorsa dokunuş yok. (3) "okudun" mesajı
  KİTAPTA değil: ekran o gün okunmuşsa `context.pop('zaten_okundu')` döner, ana menü `_showDailyLimitBubble`
  sohbet balonunu söyler (`fortuneLimitMessage('kaderkitabi')` iki cümleye çıkarıldı). `_buildHakDoldu` SİLİNDİ.
  Test `kader_sayfalama_test.dart`.
- **Numeroloji seçim kartları** (`numeroloji_screen.dart`): ikon ÜSTTE, yazı ALTTA (dikey, ortalı,
  kaydırılabilir). ChatGPT mistik ikonu gelince `Image.asset(iconAsset)` yedeği Material ikonu değiştirir.
  ⚠️ **YARIM:** Anıl 3 mistik numeroloji ikonu (genel/bugün/yıl) istedi (kahve fal_konu gibi). ChatGPT oturumu
  ÇIKIŞ YAPMIŞ (`/api/auth/session` boş) → Anıl Chrome'da ChatGPT'ye yeniden girince üret, düz solid fon,
  indir → `tools\gorsel_isle.ps1` → `assets/images/numeroloji_konu/{ngenel,nbugun,nyil}.png`, pubspec'e
  `assets/images/numeroloji_konu/` ekle. Düzen hazır, dosyalar gelince otomatik görünür.
- **Tavşan Falı** (`tavsanfali_screen.dart`, `_paperXform`): masadaki zarflar perspektife uyar. Eski ekran-içi
  dönüş zarfları kart destesi gibi yelpazeliyordu; yeni masa normali etrafında döner (foreshortened) → hepsi tek
  yüzeye yatmış görünür + derinlik ölçeği; seçilen uçarken flat→0 dikleşir.
- **Metin üretimi T16** (`scripts/metin_turu_hazirla.js` `HABER_SOYLEM` + skill): haber-verme söylemini çeşitlendir
  ("…görüyorum" tek kalıbı yerine öngörüyorum/hissediyorum/yıldızlar diyor/fincanın dibinde beliriyor…), ≤2/20.
- **Kader Çarkı** (`kadercarki_screen.dart`): segment görselleri ilk açılışta görünür. `_ikonCache` tek Map'ti,
  yerinde değişiyordu → `shouldRepaint` referansla göremeyince ancak dönünce çiziliyordu; artık her yüklemede yeni
  Map referansı.
- **Kısmetim/Evim** popup içi yatay kaydırma sayfayı geri götürmez (`NoEdgeSwipeBack`; yıl tekerleği RotatedBox'ta
  dikey eksenli → global yatay-scroll koruması atlanıyordu). **Arabam** son yıl aralığı açık uçlu (2074 yerine →).
- **ElegantHourglass yeniden** (Codex incelemesi): SÜREKLİ kum saati — akar, alt dolunca 180° döner, diğer yönden
  akar; dikişsiz (angle=π+alt-dolu == angle=0+üst-dolu, 180° simetri). Alan-korumalı seviye, eğri bezier cam,
  color'dan tonlar. 15 ekran otomatik. `debugHourglassFrame` test yardımcısı. Flip/Spinning/Pulsing ana widget'e delege.
- **Aşk Uyumu** (`askuyumu_screen.dart`): çark 280→320, basılı-tut butonu yarıçap 40→54 (ikon 38), buton kalan
  boşlukta dikeyde ortalandı.
- **Arabam Ne? yeniden** (`araba_engine.dart` schema 3 + `arabam_screen.dart`, Codex etik incelemesi): kullanıcı ŞU
  ANKİ araba markasını seçer ("Arabam yok" + A–Z); markadan başlangıç sınıfı (yaygınlık ağırlıklı medyan; marka=servet
  DEĞİL); sonraki arabalar en fazla ±1 kademe (yukarı ≥4 yıl + lüks zorluğu); arabam yok → ilk alım sınıf 1.
  **DOĞUM YERİ ekonomik tahminde KULLANILMAZ** (Codex: kaba bölgesel klişe). Meslek nötr (v1). İlk ekran basılı-tut.
  `brands()`, `brandStartLevel()`, `_progressLevel()`, imzaya marka. 6 yeni test.
- **Basılı-tut girişi** (`core/widgets/hold_to_reveal.dart` `HoldToReveal`): kısmetim/arabam/evim ilk ekranda
  seçim sonrası basılı-tut → geleceğe odaklan (Aşk Uyumu gibi). Azaltılmış harekette tek dokunuş.
- **Kapat/Tamam/Kaydet butonları kaldırıldı:** Faloya/Maganda/Tamua (Kapat), Kahinler sonucu `kahin_metin` (Tamam),
  Motivasyon (Kaydet + kullanılmayan kayıt mantığı temizlendi). Geri dönüş kenardan kaydırma.
- **Yana** sonucunda soldan-sağa swipe geri çalışır (kendi `SwipeBack`'i; PopScope canPop:false iken global
  EdgeSwipeBack `doNotPop` görüp durmuştu); sol üstte "Geri Git" yazısı yalnız ok.
- **Yüz Falı: API → CİHAZ-İÇİ (offline) analiz** (`lib/data/services/face_analyzer.dart`, Anıl + Codex). İnternet
  hatasında çökme bitti. Saf Dart + `image`: YCbCr ten, HSV saç/göz rengi, kenar yoğunluğu gözlük, çene-yanak sakal;
  cinsiyet profilden; moral/şapka/küpe/saç boyu fotoğraf hash'inden deterministik. isHuman hep true. Test:
  `test/face_analyzer_test.dart` (sentetik görsel). Eşikler Codex raporunda.
  - **GÜÇLENDİRME — ML Kit yüz tespiti** (`face_landmarks.dart`, `google_mlkit_face_detection`): yüz kutusu bulunup
    görüntü yüze göre kırpılır → sabit % bölgeler gerçek yüze oturur (Codex: asıl hata kaynağı kadraj) + gülümsemeden
    moral. **GÜVENLİ YEDEK:** ML Kit yoksa/başarısızsa/test ortamında tam görüntü sezgi motoruna düşer → çökmez.
  - ⚠️ **ML Kit iOS ASGARİ 15.5 İSTER** → `ios/Podfile` + `pbxproj` 13→**15.5** çıkarıldı (Anıl onayı; eski iOS
    kullanıcıları dışlanır). ML Kit yolu ANCAK cihaz build'inde (TestFlight) doğrulanır; pod sorunu çıkarsa orada bak.
    Gray-world beyaz dengesi denendi, yüz ten-baskın olduğu için rengi bozdu → kaldırıldı.
  - Not: Kahve/El Falı HÂLÂ `ClaudeVisionService` (API) kullanıyor → istenirse onlara da offline muamele.
- ✅ **ChatGPT görselleri (Anıl giriş yaptı, arkadan üretildi):** (1) **numeroloji 3 mistik ikon**
  (`assets/images/numeroloji_konu/{ngenel,nbugun,nyil}.png` — yıldız-sigil/güneş/ay-fazları çarkı); (2) **sonuç
  ekranı amblemleri** (`assets/images/fal_sonuc/{kismet,araba,ev}.png` — iç içe kalpler/araba/ev), kısmetim/arabam/evim
  sonuç sayfalarının en üstünde. Hat: ChatGPT (NORMAL sohbet; geçici sohbette görsel üretimi KAPALI) → `<a download>`
  blob indirme (`indirilen`) → `build/visual_check/ikon_isle.dart` ile 3'e böl + parlaklık-anahtarıyla şeffaf zemin +
  256/300 tuval → asset. ⚠️ **ChatGPT foto-gerçekçi YÜZ üretmez** ("Görsel kullanılamıyor", politika) → yüz-falı
  kalibrasyonu için yapay yüz ÜRETİLEMEDİ; motor ML Kit + sezgi hâliyle kalır.

## Ne yapıldı (2026-11-06 gece, 276 sonrası; main'de) + değişen dosyalar
- **10.8.13+279 test build'i** (2026-11-06 05:25 Android Play Dahili test + iOS TestFlight; incelemeye GÖNDERİLMEDİ).
Anıl: "her falın alınışı daha mistik/animatif/profesyonel olsun, Codex ve Grok'a danış". Envanter + Grok raporu:
`build/visual_check/codex_review/fal_akis_envanteri.md` (gitignored). Codex'in fal akışı raporu kullanım sınırında yarım kaldı.
- **Ana menü sohbet bandı:** önce yerinde durur, ızgara altına girer (`kHomeHeaderHold`); bant gizliyken yeni balon
  gelirse bant üstte belirir, yazı sonra (`_revealHeader`); dışına dokunuş yavaşça kapatır, alttaki karta geçmez.
- **Kullanıcı Bilgileri:** bar orada küçülmez (`floating_bar.dart _minimizeLocked`), ikinci dokunuş paneli kapatır,
  dişli kalktı, cam önizlemesi görselsiz, yönetici paneli ortada açılır pencere. Kenar geri göstergesi kaldırıldı.
- **Kader Kitabı yeniden** (`kaderkitabi/kader_book_scene.dart`, `core/widgets/living_sea.dart` + `shaders/living_sea.frag`):
  dalgalanan gece denizinden yükselen açık parşömen, damlalar akar, mürekkep belirir, suda bulanık yansıma.
- **Kader Çarkı yeniden** (`kadercarki_screen.dart`): altın kasnak, çivi tıkı + ok sekmesi, kazanan parlar; ters
  dönüş hatası düzeldi (`kaderSpinEnd`), dönerken tekrar çevirme kilitli. Test `kadercarki_test` (2000 rastgele vaka).
- **Fal ritüelleri:** I-Ching hexagram çizgi çizgi, Japon omikuji kutusu sallanır; El Falı avuç çizgileri ışıyarak;
  Numeroloji sayıları belirir; Biyoritim yüzdeleri sayar; Doğum Haritası dairesel açılır; Tarot kadife masa + deste
  yelpaze gibi dağılır (`tarot/deck_deal.dart`); Kahve "Yerime İç" fincanından buhar (`coffee/cup_steam.dart`).
- **Ortak parçalar:** `ResultReveal` (fal detayı ışık süpürmesiyle açılır), `StaggerIn` (Astroloji/Dert Ortağı sıralı),
  `FocusRipple` (kum saati yerine nabız gözü: Faloya, Maganda, Yana, Acı Gerçekler), `UnlockFlash` (Kısmetim/Arabam/Evim
  kilit açılışı). Hepsi azaltılmış harekette sade; testleri `test/<ad>_test.dart`.
- **Titreşimler:** sürtme/kazıma tıkları, burç çarkı, kart oturuşu, taş çarpması, kilit açılışı, Maganda sarsıntısı.
- **Süre kısaltmaları:** Yana ~14→~9 sn, Acı Gerçekler 5→3.2 sn (dokununca yazı tamamlanır), tek kart tarot artık
  kendiliğinden gönderilmez ("Gönder" düğmesi). Tamua'ya dokunulmadı (8-12 sekme yarı hız Nisan'da bilinçli seçilmiş).
- **Tavşan:** zarflar yukarı, çift göz kırpma (`tavsan_goz_kapali.png`, `tools/tavsan_kapali_goz.py`), kart dışına
  dokununca kapanır. Fal konusu ikonları yeniden çizildi (ChatGPT). AstroTakvim düğmeleri eski boyutta.
- **Paralel İngilizce eksikleri:** El/Yüz Falı ekranları, Niyet, Tamua, Yana, yasal metin "Anladım", tarot yedek metni.
- **Metin turları 11-17** (+1051 metin, toplam 2449; ChatGPT↔Codex iki yönlü seçim) — ayrıntı `docs/metin_uretim_log.md`.
- **Claude kod incelemesi (14 bulgu) düzeltildi:** gizli bant belirince sohbet en alta kayar; UnlockFlash /
  ResultReveal içeriği yeniden kurmaz (GlobalKey / sabit ağaç); I-Ching animasyonu metindeki yazı-turadan aynı
  heksagramı çizer (`ichingCizgileri`, test); Kader Kitabı okurken 30 Hz + kitap önbellekte, deniz 30 Hz, sayfa alanı
  büyüdü (360 dp en uzun metin 9,9 px) + kitaba dokununca büyük yazılı okuma penceresi; Durugörü boş havuzda kilitlenmez;
  tarot çift dokunuş koruması; El Falı taraması döngüde; azaltılmış hareket eksikleri; çark gölgesi ayrı katman.
  **Bilerek bırakılanlar:** tek kart tarotta kart seçilince geri kilidi (klasik tarotla aynı; yeniden çekmeyi önler,
  alt bar çıkış yolu); deniz shader'ı 10 dk'da bir zaman sarması (tek karelik dalga sıçraması); çark metni dönüş
  başında no-repeat'e yazılıyor (dönerken çıkan kullanıcıda bir metin "görülmüş" sayılır).
- **Codex gece incelemesi (7 bulgu) düzeltildi:** Kader Kitabı boşluksuz metinde çökmez (`splitKaderPages`);
  ana menü bant dokunuş engeli parmak kalkınca sıfırlanır (ekran okuyucu kartı açabilir); Kader Çarkı / I-Ching
  await sonrası `ref` kullanmaz; El Falı / I-Ching / Japon azaltılmış hareketi MediaQuery'den ekran açıkken de izler;
  kitap dalgası ve odak nabzı dikişsiz. Yeni testler: `codex_gece_saf_mantik_test`, `reduced_motion_toggle_test`.
- Testler: 170 geçiyor; tek kırmızı takipsiz `test/_visual_starfield_capture_test.dart`.

## Önceki (2026-11-06 gündüz)
- **10.8.12+276 test build'i** (Android Play Dahili test + iOS TestFlight; incelemeye GÖNDERİLMEDİ).
- **Ana menü 3 düzen** (`home/menu_layout.dart`): açılışta 1/3 ihtimalle 3×9 / büyük·3×4·büyük·3×4·büyük /
  "Favoriler" 3×2 + "Diğer Türler" 3×7 (kullanım sayımı `menu_kullanim`, oturum boyu sabit). Test `menu_layout_test`.
- **Sohbet bandı satır kadar** (`home/home_header_layout.dart`): bant görünen satır kadar, ızgara yayla birlikte iner,
  bant gizliyken menü yerinde (sliver ofset düzeltmesi). Codex 2 bulgu (satır kırılması, semantics) düzeltildi.
- **19 HD menü görseli** (`assets/images/menu_hd/`, ~4 MB): kaynağı <768 px olanlar, ChatGPT'de 1024'e büyütme +
  keskinleştirme (yeniden çizim değil; birebir). Yalnız büyük kartta (`menuImageFor`).
- **Cam bar Instagram eşitleme** Codex 4 tur (puanlar 9,5); kalan fark seçim animasyonu zamanlaması — Anıl'ın sekme
  dokunuşu ekran kaydı gerekli.

## Önceki (2026-11-05)
- **Gece (build YOK, main'de, 4c9295b4):** Ayrıntı CLAUDE.md "2026-11-05 GÜNCEL" ve "KULLANICI BİLGİLERİ
  KART DÜZENİ" bölümlerinde.
  - **Yüzen cam bar tüm uygulamada** (`shell/floating_bar.dart`). Fal ekranlarında seçimsiz.
  - **Alttaki Geri Git'ler kaldırıldı** (40 ekran, `FloatingBarSpacer`).
  - **Bar konumu** Instagram ölçümü (`glassBarBottom`).
  - **Sekme geçişleri:** bar ikonuyla anında; kaydırmayla örten animasyon + titreşim.
  - **Titreşimler:** kaydırma, fal ikonu, fal gönderildi / hazır.
  - **Kullanıcı Bilgileri kart kart.** Ayarlar 3. kart; ara panel; kaydırmayla kutular ve halkalar sıkışır.
  - **Cam saydamlığı** Ayarlar kartında, iOS 26 kaydırıcısı ölçümüyle (`glass_tint.dart`, `liquid_glass_slider.dart`).
  - Testler 126+ geçiyor (tek kırmızı eski artık `_visual_starfield_capture_test`).
  - Codex görsel karşılaştırma raporu: `build/visual_check/codex_review/codex_rapor.txt` (gitignored).
- **Sıvı cam + kaydırmayla küçülme + iki katmanlı ana menü (build YOK, main'de):** Anıl'ın Instagram kayıt/ekran
  görüntülerinden ÖLÇÜLDÜ.
  - (1) Cam bar Impeller'da gerçek ışık kırılması: `shaders/glass_lens.frag` (kenarda dairesel cam pahı, örnek içeri kayar,
    hafif yönlü bulanıklık). Skia'da eski buzlu cam. Geçirgenlik değişmedi.
  - (2) Bar kaydırmayla küçülür/büyür: `lib/core/widgets/bar_minimize.dart` + `main_tabs.dart`. 0.837 ölçek; küçülmede
    45 pt ölü bölge, kararlar 72/60 pt'de; yay 250/24.
  - (3) Ana menü arka planı düz #0C0F14. Üstteki sohbet balonları ayrı üst katman (#151515); ızgarayla birlikte kayıp
    ekrandan çıkar, başa dönünce iner (`home_screen.dart`).
  - (4) Seçili sekme ikonu iOS mavisi #5FBBF9.
  - Testler: `bar_minimize_test` (yeni), `glass_tab_bar_test` / `main_tabs_test` (yeni vakalar).
  - Görsel doğrulama Impeller ile Windows'ta: `flutter test --enable-impeller build/visual_check/lens_compare_test.dart`
    ve `minimize_capture_test.dart`.
- **10.8.11+273 — ÖNEMLİ MENÜ DEĞİŞİKLİĞİ (Anıl):** cam bar 3 ikon: Ev · Zarf · Profil (insan büstü). Ana menü TEK
  sayfa, 3×9 dikey kaydırmalı ızgara (sayfa göstergesi + hazırlanan fal yuvarlakları kaldırıldı, alan ızgaraya katıldı).
  Zarf rozeti: hazırlanan fal → turuncu, hepsi hazır → yeşil, okunmamış yok → yok (zamanlayıcıyla kendiliğinden döner).
  Kapsül hareket yönüne uzayıp kısalıyor. Yön kilitli sekme kaydırma `lib/core/widgets/tab_swipe.dart`.
  Dosyalar: `glass_tab_bar.dart`, `shell/main_tabs.dart`, `home/home_screen.dart`, `inbox_screen.dart`, `settings_screen.dart`,
  `app_strings.dart`; testler `main_tabs_test`, `glass_tab_bar_test`, `tab_swipe_test`. Codex incelemesi (4 bulgu) düzeltildi.
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
- **Metin döngüsü durumu (2026-11-06 05:20):** toplam eklenen **2449** (tur 1–17 tamam). ⚠️ Anıl'ın Chrome'unda
  ChatGPT oturumu 02:15'te düştü (yeni sayfa "Oturum aç"); döngüye devam için Anıl yeniden giriş yapmalı. Tur 18+
  tanımları `scripts/metin_turu_hazirla.js` TURLAR'a eklenmeli. Kader Çarkı'na metin EKLENMEDİ — koşul filtresi bozuk
  (tüm metinlerde `wheel mod=fal`), ayrı görev.
- **METİN DÖNGÜSÜ SÜRÜYOR (Anıl: 4-5 bin ilave metin; "sonra 10 tur daha"):** toplam/ilerleme `docs/metin_uretim_log.md` en üstte.
  Hat: ChatGPT (Anıl'ın Chrome'u) + Codex CLI (`scripts/metin_codex.sh`); adımlar skill `magnus-metin-uretimi` → "Döngü akışı".
  Tur tanımları `scripts/metin_turu_hazirla.js` TURLAR[3..10] (9-10 önceki tanımları yeniden kullanır). Çalışma dosyaları
  oturum scratchpad'inde (metin_turN/, secimler.json, bekleyen_secimler.json) — yeni oturumda yoksa ilgili turu baştan üret.
  Codex kullanım sınırı dolunca saatini bekle; o arada ChatGPT tarafı sürer.

- Anıl'ın 279 geri bildirimi → düzelt. Bir sonraki build `10.8.14+282`, yalnız "test çık" ile.
- Apple uyarısı (279 yüklemesinde): iOS dağıtım hedefi 13.0; **Nisan 2027'den itibaren en az 15.0** gerekir →
  `ios/Podfile` `platform :ios` + Xcode `IPHONEOS_DEPLOYMENT_TARGET` 15.0'a çıkarılmalı (eklentilerle birlikte dene).
- Cam bar seçim animasyonu: Anıl Instagram'da sekme dokunuşu kaydı gönderirse kare kare ölç, eşitle, Codex'e sor.
- "Bir tur daha" denirse: `docs/metin_uretim_log.md` → "Sıradaki tur adayları" (Kahve Uğurlama, Kahve Bağlama,
  Japon, Kader Kitabı, Kâhinler) + `magnus-metin-uretimi` skill'i.
- Güvenlik (Anıl onayı gerekli): repo herkese açık; git geçmişinde eski kişisel veri ve CLAUDE.md'de imza
  şifreleri var → geçmiş temizliği + anahtarları döndürme önerildi. Uygulamadaki Anthropic anahtarı istemcide
  gömülü → sunucu/proxy önerildi.
