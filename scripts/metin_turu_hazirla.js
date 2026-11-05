// magnus-metin-uretimi: bir tur için kompartman başına brief dosyası üretir (30 örnek + çeşitlilik kuralı + 20 kitle).
// Kullanım: node scripts/metin_turu_hazirla.js <çıktı_klasörü> <tur_no>
// Kompartmanlar TURLAR[tur] listesinde. Örnekler deterministik seçilir (tohum = tur_no).
const fs = require('fs');
const path = require('path');
const outDir = process.argv[2];
const tur = parseInt(process.argv[3] || '1', 10);
const ORNEK = 30; // Anıl: örnek arttıkça kalite/yaratıcılık artar
fs.mkdirSync(outDir, { recursive: true });

function rnd(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }
function shuffle(a, r) { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; }

// Bozuk/anlamsız koşullar örnek gösteriminde yok sayılır (ör. Durugörü Bugün'deki saatmin/saatmax)
const YOKSAY = /^(saatmin|saatmax|wheel mod)/;
const etkin = e => (e.kosullar || []).filter(k => !YOKSAY.test(String(k.degisken).replace(/['"]/g, '').trim()));
function kitle(kosullar) {
  if (!kosullar.length) return 'koşulsuz (herkes)';
  return kosullar.map(k => {
    const d = String(k.degisken).trim(), v = String(k.deger);
    if (d === 'yasmax') return `${v} yaş ve altı`;
    if (d === 'yasmin') return `${v} yaş ve üstü`;
    return `${d.replace('_', ' ')}: ${v}`;
  }).join(' + ');
}

const KITLE_M1 = [
  'koşulsuz (herkes)', 'koşulsuz (herkes)', 'koşulsuz (herkes)', 'koşulsuz (herkes)', 'koşulsuz (herkes)',
  'kadın', 'erkek', 'evli', 'ilişkisi yok (bekar)', 'ilişkisi var', 'yeni ayrılmış', 'öğrenci',
  'özel sektör çalışanı', 'kamu sektörü çalışanı', 'kadın + evli', 'erkek + ilişkisi yok (bekar)',
  '25 yaş ve altı', '40 yaş ve üstü', 'ev hanımı', 'emekli', 'akademisyen', 'nişanlı', 'boşanmış',
  'kadın + ilişkisi yok (bekar)', 'erkek + evli',
];
const KITLE_M3 = KITLE_M1.filter(k => !/yaş/.test(k)); // Niyet eşleştiricisi yaş bilmez
const KITLE_M5 = KITLE_M3.concat(['iş arıyor', 'kendi işini yapıyor']);
const KITLE_KOSULSUZ = Array(25).fill('koşulsuz (herkes)'); // Faloya yalnız koşulsuzu gösterir

const TURLAR = {
  1: [/* tur 1 — bkz. docs/metin_uretim_log.md */],
  2: [
    {
      id: 'kahve_giris', file: 'kahve_giris.json', key: 'girisler', matcher: 'M1', kitle: KITLE_M1, konu: true,
      tur: 'Kahve falı',
      sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: karşılama → GİRİŞ → bağlama → gelişme → sonuç → uğurlama. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir; her metin tek başına anlamlı olmalı, öncesi/sonrasıyla çelişmemeli (selam/veda yok).',
      gorev: 'GİRİŞ — fincanda gözüne İLK çarpan sembol: onu canlı ve somut tarif et, ne anlama geldiğini söyle ve kişinin hayatına dair isabetli bir gözlem/öngörüyle bağla. Uzunluk: 400-800 karakter.',
    },
    {
      id: 'niyet', file: 'niyet.json', key: 'niyet', matcher: 'M3', kitle: KITLE_M3,
      tur: 'Niyet (kazıma kartı kehaneti)',
      sistem: 'Kullanıcı içinden bir niyet tutar ve ekrandaki kartı parmağıyla kazır; altından tek bir kehanet çıkar. Kısa, gelecek zamanlı, kendinden emin.',
      gorev: 'NİYET KEHANETİ — tutulan niyetle ilgili gelecekte olacak somut bir gelişme. Uzunluk: 150-320 karakter.',
    },
    {
      id: 'faloya', file: 'faloya.json', key: 'faloya', matcher: 'M7', kitle: KITLE_KOSULSUZ,
      tur: 'Faloya (varlıkların fısıldadığı tarihli öngörü)',
      sistem: 'Kullanıcı "Faloya" der; Magnus varlıklardan bir fısıltı alır ve belirli bir tarihte olacak tek bir şeyi söyler. Metin hep şu açılışla başlar: "Merhaba {{isim}}.\\n\\nVarlıklar fısıldıyor...\\n\\nGeleceğine dair bir öngörüm var.\\n\\n" ve ardından tarihli öngörü gelir (çoğu "Önümüzdeki {{sayi,1,28}} {{ay_2}} tarihinde, …" ya da {{randomtarih,a,b}}).',
      gorev: 'TARİHLİ ÖNGÖRÜ — açılıştan sonra 2-4 cümle: hangi tarihte, ne olacak, kim/nasıl. HEPSİ KOŞULSUZ (herkese uygun; cinsiyet/medeni durum/meslek varsayma). Uzunluk: 280-450 karakter (açılış dahil).',
    },
    {
      id: 'durugoru_yno', file: 'durugoru_yno.json', key: 'durugoru_yno', matcher: 'M1', kitle: KITLE_M1,
      tur: 'Durugörü',
      sistem: 'Kullanıcı "Yarın beni neler bekliyor?" sorusunu seçer; Magnus odaklanır ve YARIN olacakları anlatır. Metin gelen kutusuna tek parça düşer.',
      gorev: 'YARIN — yarının akışından 2-3 somut sahne/olay (sabah, öğle, akşam gibi), her birinin anlamı ve küçük bir tavsiye. Uzunluk: 550-950 karakter.',
    },
    {
      id: 'durugoru_bno', file: 'durugoru_bno.json', key: 'durugoru_bno', matcher: 'M1', kitle: KITLE_M1,
      tur: 'Durugörü',
      sistem: 'Kullanıcı "Bugün beni neler bekliyor?" sorusunu seçer; Magnus odaklanır ve BUGÜN (günün geri kalanında) olacakları anlatır. Metin gelen kutusuna tek parça düşer.',
      gorev: 'BUGÜN — bugün içinde karşılaşacağı 1-3 somut olay/kişi/haber ve anlamı. Uzunluk: 450-900 karakter.',
    },
  ],
  3: [
    {
      id: 'durugoru_bno', file: 'durugoru_bno.json', key: 'durugoru_bno', matcher: 'M1', kitle: KITLE_M1, orijinalMaxId: 92,
      tur: 'Durugörü',
      sistem: 'Kullanıcı "Bugün beni neler bekliyor?" sorusunu seçer; Magnus odaklanır ve BUGÜN (günün geri kalanında) olacakları anlatır. Metin gelen kutusuna tek parça düşer.',
      gorev: 'BUGÜN — günün geri kalanında yaşayacağı 1-2 olay/karşılaşma/haber ve anlamı. Olaylar "bugün çoğu insanın başına gelebilecek" yaygınlıkta olsun (COLD READING), dokusu canlı. Uzunluk: 450-850 karakter.',
    },
    {
      id: 'kahve_ugurlama', file: 'kahve_ugurlama.json', key: 'ugurlamalar', matcher: 'M1', kitle: KITLE_M1, konu: true, adet: 40,
      tur: 'Kahve falı',
      sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: karşılama → giriş → bağlama → gelişme → sonuç → UĞURLAMA. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir; her metin tek başına anlamlı olmalı, öncekilerle çelişmemeli.',
      gorev: 'UĞURLAMA — falın son parçası: sıcak bir veda, kişiye dair kısa ve isabetli (Barnum tarzı) bir son tespit ya da önümüzdeki günler için geniş zamanlı küçük bir öngörü/iyi dilek; çoğu "\\n\\nMagnus" imzasıyla biter. Uzunluk: 120-330 karakter.',
      ekYasak: 'ŞARKI SÖZÜ, şiir dizesi ya da başka bir eserden alıntı YAZMA (telif) — kendi cümlelerini kur.',
    },
    {
      id: 'kaderkitabi', file: 'kaderkitabi.json', key: 'kaderkitabi', matcher: 'M2', kitle: KITLE_M1, adet: 40,
      tur: 'Kader Kitabı',
      sistem: 'Kullanıcı Kader Kitabı\'nı açar ve sıradaki sayfayı okur. Her sayfa "||" işaretiyle ayrılmış İKİ kısa bölümden oluşur; ekranda iki ayrı paragraf olarak görünür. Her açılışta yeni bir sayfa gelir.',
      gorev: 'KADER KİTABI SAYFASI — 1. bölüm: okuyanın şu anki hâline dair Barnum tarzı, isabetli hissettiren bir tespit ve öğüt; 2. bölüm: bunu bağlayan özlü, akılda kalan bir hikmet ya da yol gösterici cümle. İki bölümün arasına "||" koy (başka yerde || kullanma). Hitap "sen"; Magnus\'un konuşma tonu yerine kadim bir kitabın sesi. Uzunluk toplam 180-380 karakter. Yer tutucu nadiren ({{isim}}).',
      uslup: 'ÜSLUP: kadim, sakin, bilge bir kitabın sesi; kısa ve vurucu cümleler; gündelik hayattan somut bir imge (diş fırçalamak, gün doğumu, çaydanlık…) ile soyut bir hakikati birleştir; vaaz gibi değil, insanın kendini tanıdığı bir ayna gibi.',
      ekYasak: 'Dinî ibare, ayet/hadis alıntısı ya da başka bir yazardan özlü söz KOPYALAMA — kendi cümlelerini kur.',
    },
    {
      id: 'kahin_likia', file: 'kahinler.json', key: 'kahinler.likia', matcher: 'M7', kitle: KITLE_KOSULSUZ,
      tur: 'Kâhinlere Sor — Kâhin LİKİA',
      sistem: 'Kullanıcı AKLINDAN bir soru tutar (uygulama soruyu BİLMEZ) ve kâhinlerden Likia\'yı seçer. Likia kendi kişiliğiyle kendini tanıtır, tutulan soruya cevap verir ve vedalaşır. Cevap HER SORUYA oturmalı: ne sorulduğunu bilmeden, ama soruyu biliyormuş gibi.',
      gorev: 'LİKİA CEVABI — 3 paragraf: (1) Likia\'nın kendini tanıtışı: örneklerdeki kişiliği koru (gölgelerin/kuytuların kâhini, fısıltılı ve gizemli, kendine hayran, flörtöz, rahat, "Sevgimle..." diye biter) ama tanıtım cümlelerini KOPYALAMA, yeni lakaplar ve takılmalar üret; (2) cevap: soruyu bilmeden biliyormuş gibi; olumlu yöne çıkan, ama süre/şart/dönüm noktası içeren çift çıkışlı bir hüküm (ör. "önce yavaşlayacak, sonra bir an gelecek…", "cevap hayır, ama bu senin için iyi"); (3) kısa veda. Uzunluk: 450-800 karakter.',
      uslup: 'ÜSLUP: Likia birinci tekil konuşur, kullanıcıya "sen" der; gizemli, cilveli, kendini beğenmiş, esprili. <sprite=…> etiketi KULLANMA.',
    },
    {
      id: 'kahin_yousuf', file: 'kahinler.json', key: 'kahinler.yousuf', matcher: 'M7', kitle: KITLE_KOSULSUZ,
      tur: 'Kâhinlere Sor — Kâhin YOUSUF',
      sistem: 'Kullanıcı AKLINDAN bir soru tutar (uygulama soruyu BİLMEZ) ve kâhinlerden Yousuf\'u seçer. Yousuf kendi kişiliğiyle kendini tanıtır, tutulan soruya cevap verir ve vedalaşır. Cevap HER SORUYA oturmalı: ne sorulduğunu bilmeden, ama soruyu biliyormuş gibi.',
      gorev: 'YOUSUF CEVABI — 3 paragraf: (1) Yousuf\'un gösterişli girişi: örneklerdeki kişiliği koru (kâhinlerin en güçlüsü/azametlisi, kafiyeli övünmeler, "Hahh!", "Hohh!", mahalle ağzı, kendiyle dalga geçen kibir) ama övünme cümlelerini KOPYALAMA, yenilerini üret; (2) cevap: soruyu bilmeden biliyormuş gibi; olumluya çıkan ama zamanı ve şartı açık bırakan bir hüküm (ör. "olacak, ama acele ettiremem"); (3) kısa, esprili veda. Uzunluk: 450-850 karakter.',
      uslup: 'ÜSLUP: Yousuf birinci tekil konuşur, kullanıcıya "sen" der; kibirli-komik, gürültülü, sıcak. <sprite=…> etiketi KULLANMA. {{data, cinsiyet=erkek, X | cinsiyet=kadin, Y}} kullanırsan "kadin" (ı değil i) yaz.',
    },
  ],
  4: [
    {
      id: 'tavsanfali', file: 'tavsanfali.json', key: 'tavsanfali', matcher: 'M5', kitle: KITLE_M5, adet: 40, orijinalMaxId: 120,
      tur: 'Tavşan Falı',
      sistem: 'Ekranda kâğıtlar dalgalanır; kullanıcı bir kâğıda dokunur ve tavşan o kâğıdı çekip ağzıyla getirir. Kâğıtta tek bir kısa kehanet yazar. Günde bir kez.',
      gorev: 'TAVŞANIN KÂĞIDI — tek bir kısa, gelecek zamanlı kehanet: "{{isim}}, <zaman> <olay>. <kısa devam/duygu>." biçiminde ama her metin farklı iskeletle. Kısa ama hikâyeleşmiş: bir mini sahne + sonuç. Uzunluk: 90-170 karakter.',
    },
    {
      id: 'niyet', file: 'niyet.json', key: 'niyet', matcher: 'M3', kitle: KITLE_M3, adet: 40, orijinalMaxId: 178,
      tur: 'Niyet (kazıma kartı kehaneti)',
      sistem: 'Kullanıcı içinden bir niyet tutar ve ekrandaki kartı parmağıyla kazır; altından tek bir kehanet çıkar. Kısa, gelecek zamanlı, kendinden emin. Uygulama niyeti BİLMEZ: kehanet her niyete oturmalı.',
      gorev: 'NİYET KEHANETİ — tutulan (bilinmeyen) niyetle ilgili gelecekte olacak bir gelişme: biliyormuş gibi, her niyete uyacak çift çıkışlı. Uzunluk: 150-320 karakter.',
    },
    {
      id: 'yana_bana', file: 'yana.json', key: 'bana_dair', matcher: 'M4', kitle: KITLE_M1, adet: 40, orijinalMaxId: 68, extra: { tur: 'bana' },
      tur: 'Yana — Bana Dair (yıllar sonrasının kehaneti)',
      sistem: 'Kullanıcı "Bana dair" seçer; Magnus Magnuskop\'u yıllar sonrasına ayarlar ve kullanıcıyı orada görür. Metin ekranda aşağıdan yukarı kelime kelime yerleşir.',
      gorev: 'YILLAR SONRASI — kullanıcının birkaç yıl sonraki hayatından bir sahne (ev, iş, ilişki, alışkanlık, bir an): uzak geleceğe dair ama sıcak ve inandırıcı; çoğu "Magnuskop\'u … sonrası için ayarladığımda, seni … görüyorum {{isim}}" duygusunda ama hep aynı açılışla değil. Uzunluk: 220-420 karakter.',
    },
    {
      id: 'kahve_sonuc', file: 'kahve_sonuc.json', key: 'sonuclar', matcher: 'M1', kitle: KITLE_M1, konu: true, orijinalMaxId: 398,
      tur: 'Kahve falı',
      sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: karşılama → giriş → bağlama → gelişme → SONUÇ → uğurlama. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir; her metin tek başına anlamlı olmalı, öncekilerle çelişmemeli.',
      gorev: 'SONUÇ — fincanın dibine yakın gördüğün 1-2 sembol ve falın varacağı yer: yakın gelecekte (günler/haftalar, {{ay_N}}) olacak somut gelişmeler, az ve yumuşak bir olumsuz + bol olumlu sonuç. Uzunluk: 450-750 karakter.',
    },
    {
      id: 'kahve_gelisme', file: 'kahve_gelisme.json', key: 'gelismeler', matcher: 'M1', kitle: KITLE_M1, konu: true, orijinalMaxId: 418,
      tur: 'Kahve falı',
      sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: karşılama → giriş → bağlama → GELİŞME → sonuç → uğurlama. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir; her metin tek başına anlamlı olmalı, öncekilerle çelişmemeli.',
      gorev: 'GELİŞME — falın gövdesi: fincanda gördüğün 2-3 ana sembol ve her birinin öngörüsü; zaman ipuçları ({{ay_N}}, {{sayi,a,b}} gün/hafta, {{gun_N}}), kişiler ve olayların zincirlenmesi (biri ötekine yol açar). Uzunluk: 850-1250 karakter.',
    },
  ],
  5: [
    {
      id: 'kahve_karsilama', file: 'kahve_akarsilama.json', key: 'karsilamalar', matcher: 'M1', kitle: KITLE_M1, konu: true, adet: 40, orijinalMaxId: 346,
      tur: 'Kahve falı',
      sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: KARŞILAMA → giriş → bağlama → gelişme → sonuç → uğurlama. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir.',
      gorev: 'KARŞILAMA — falın ilk paragrafı: kullanıcıyı adıyla ya da özelliğiyle karşıla, fincanına bakmadan önceki ilk izlenimini söyle (Barnum tarzı kısa bir tespit: o günkü hâli, beklentisi), seçtiği konuya (aşk/kariyer/sağlık/genel) göndermeyle falı sun ve "başlıyorum" duygusuyla bitir (çoğu ";" ya da "…" ile biter, bir sonraki parçaya bağlanır). Uzunluk: 180-420 karakter.',
    },
    {
      id: 'yana_yasama', file: 'yana.json', key: 'yasama_dair', matcher: 'M4', kitle: KITLE_KOSULSUZ, adet: 40, orijinalMaxId: 110, extra: { tur: 'yasama' },
      tur: 'Yana — Yaşama Dair (dünyanın geleceği kehaneti)',
      sistem: 'Kullanıcı "Yaşama dair" seçer; Magnus Magnuskop\'u uzak geleceğe ayarlar ve dünyada, bilimde, teknolojide, gündelik yaşamda olacakları söyler (kişisel değil, insanlığa dair). Metin ekranda kelime kelime yerleşir.',
      gorev: 'DÜNYANIN GELECEĞİ — yıllar/onyıllar sonrası ({{sayi,a,b}} ile yıl: "20{{sayi,40,96}} yılında") bilim, teknoloji, şehir, doğa, sağlık, iletişim, yemek, eğitim ya da gündelik alışkanlıklarda olacak somut ve hayal gücü yüksek ama makul bir gelişme; sonunda kullanıcıya ({{isim}}) dönük kısa bir bağ. Felaket/savaş/salgın YOK; umutlu. HEPSİ KOŞULSUZ. Uzunluk: 220-450 karakter.',
    },
    {
      id: 'kahin_derun', file: 'kahinler.json', key: 'kahinler.derun', matcher: 'M7', kitle: KITLE_KOSULSUZ,
      tur: 'Kâhinlere Sor — Kâhin DERUN',
      sistem: 'Kullanıcı AKLINDAN bir soru tutar (uygulama soruyu BİLMEZ) ve kâhinlerden Derun\'u seçer. Derun kendini tanıtır, tutulan soruya cevap verir ve vedalaşır. Cevap HER SORUYA oturmalı.',
      gorev: 'DERUN CEVABI — 3-4 paragraf: (1) tanıtım: örneklerdeki kişiliği koru (bilinmezleri gözeten yüce kâhin, yıldızların habercisi, ciddi ve ağır, "yabancı" diye hitap edebilir, "Güce selam olsun!" tarzı kapanışlar) ama cümleleri KOPYALAMA; (2) cevap: soruyu bilmeden biliyormuş gibi, çift çıkışlı hüküm (inanç/şart/iki zaman); (3) kısa veda. Uzunluk: 400-750 karakter.',
      uslup: 'ÜSLUP: Derun birinci tekil konuşur, "sen" der; vakur, gizemli, biraz kibirli ama koruyucu. <sprite=…> etiketi KULLANMA.',
    },
    {
      id: 'kahin_khaleesi', file: 'kahinler.json', key: 'kahinler.khaleesi', matcher: 'M7', kitle: KITLE_KOSULSUZ,
      tur: 'Kâhinlere Sor — Kâhin KHALEESI',
      sistem: 'Kullanıcı AKLINDAN bir soru tutar (uygulama soruyu BİLMEZ) ve kâhinlerden Khaleesi\'yi seçer. Khaleesi kendini tanıtır, tutulan soruya cevap verir ve vedalaşır. Cevap HER SORUYA oturmalı.',
      gorev: 'KHALEESI CEVABI — 3-4 paragraf: (1) tanıtım: örneklerdeki kişiliği koru (kehanetlerin iç sesi, karlı/soğuk diyarlardan gelen, samimi ve geveze, "naber", "okeyiz" gibi rahat dil) ama cümleleri KOPYALAMA; (2) cevap: soruyu bilmeden biliyormuş gibi; vadeler, kırılmalar ve sonunda isteğin ötesine geçen bir varış; (3) kısa veda. Uzunluk: 400-750 karakter.',
      uslup: 'ÜSLUP: Khaleesi birinci tekil konuşur, "sen" der; sıcak, esprili, laubali ama güçlü. <sprite=…> etiketi KULLANMA.',
    },
    {
      id: 'kahin_uraz', file: 'kahinler.json', key: 'kahinler.uraz', matcher: 'M7', kitle: KITLE_KOSULSUZ,
      tur: 'Kâhinlere Sor — Kâhin URAZ',
      sistem: 'Kullanıcı AKLINDAN bir soru tutar (uygulama soruyu BİLMEZ) ve kâhinlerden Uraz\'ı seçer. Uraz kendini tanıtır, tutulan soruya cevap verir ve vedalaşır. Cevap HER SORUYA oturmalı.',
      gorev: 'URAZ CEVABI — 3-4 paragraf: (1) tanıtım: örneklerdeki kişiliği koru (son derece kibar, eski İstanbul nezaketi, Osmanlıca kelimeler — "efendim", "mümtaz", "emrinize amadeyim", "şükran duyarım" —, kullanıcıya "SİZ" der ve "{{isim hanim/bey}}" ile seslenir) ama cümleleri KOPYALAMA; (2) cevap: soruyu bilmeden biliyormuş gibi, ölçülü ve çift çıkışlı (vade, beklentinin dozu, gönle göre olma); (3) nazik veda. Uzunluk: 400-750 karakter.',
      uslup: 'ÜSLUP: Uraz birinci tekil konuşur, kullanıcıya "SİZ" diye hitap eder; ağırbaşlı, zarif, eski usul nezaket. Hitap için {{isim hanim/bey}} yer tutucusunu kullan ("Ayşe Hanım"/"Ahmet Bey" olur). <sprite=…> etiketi KULLANMA.',
    },
  ],
  6: [
    {
      id: 'kahve_baglama', file: 'kahve_baglama.json', key: 'baglamalar', matcher: 'M1', kitle: KITLE_M1, konu: true, adet: 40, orijinalMaxId: 250,
      tur: 'Kahve falı',
      sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: karşılama → giriş → BAĞLAMA → gelişme → sonuç → uğurlama. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir.',
      gorev: 'BAĞLAMA — girişten gelişmeye geçen 1-3 cümlelik köprü: fincanda daha derine indiğini, yeni işaretler gördüğünü söyle; kimi zaman kullanıcıya dair kısa bir Barnum tespiti ya da tatlı bir espriyle (yer tutucu: {{isim}}, {{burc}}). Sonu ":" / ";" / "…" ile bir sonraki parçaya açılabilir. Şarkı sözü alıntısı YOK. Uzunluk: 70-260 karakter.',
    },
    {
      id: 'faloya', file: 'faloya.json', key: 'faloya', matcher: 'M7', kitle: KITLE_KOSULSUZ, adet: 40, orijinalMaxId: 111,
      tur: 'Faloya (varlıkların fısıldadığı tarihli öngörü)',
      sistem: 'Kullanıcı "Faloya" der; Magnus varlıklardan bir fısıltı alır ve belirli bir tarihte olacak tek bir şeyi söyler. Metin hep şu açılışla başlar: "Merhaba {{isim}}.\\n\\nVarlıklar fısıldıyor...\\n\\nGeleceğine dair bir öngörüm var.\\n\\n" ve ardından tarihli öngörü gelir (çoğu "Önümüzdeki {{sayi,1,28}} {{ay_2}} tarihinde, …" ya da {{randomtarih,a,b}}); çoğu "\\n\\nTekrar gel." ile biter.',
      gorev: 'TARİHLİ ÖNGÖRÜ — açılıştan sonra 2-4 cümle: tarih + olay + kim/nasıl + duygu. Tarih kesin görünür ama olay yaygın olsun (COLD READING); "o gün" yerine "o tarihte ya da hemen sonrasında" gibi tolerans payı. HEPSİ KOŞULSUZ (cinsiyet/medeni durum/meslek varsayma). Uzunluk: 280-460 karakter (açılış dahil).',
    },
    {
      id: 'kahve_giris', file: 'kahve_giris.json', key: 'girisler', matcher: 'M1', kitle: KITLE_M1, konu: true, orijinalMaxId: 748,
      tur: 'Kahve falı',
      sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: karşılama → GİRİŞ → bağlama → gelişme → sonuç → uğurlama. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir; her metin tek başına anlamlı olmalı.',
      gorev: 'GİRİŞ — fincanda gözüne İLK çarpan sembol: onu canlı ve somut tarif et, ne anlama geldiğini söyle ve kişinin hayatına dair Barnum tarzı isabetli bir gözlem + yaygın ama hikâyeleşmiş bir öngörüyle bağla. Uzunluk: 400-800 karakter.',
    },
    {
      id: 'durugoru_yno', file: 'durugoru_yno.json', key: 'durugoru_yno', matcher: 'M1', kitle: KITLE_M1, orijinalMaxId: 19,
      tur: 'Durugörü',
      sistem: 'Kullanıcı "Yarın beni neler bekliyor?" sorusunu seçer; Magnus odaklanır ve YARIN olacakları anlatır. Metin gelen kutusuna tek parça düşer.',
      gorev: 'YARIN — yarının akışından 1-2 sahne/olay ve anlamı: zincirli zaman ("sabah işe çıkarken… ardından birkaç saat içinde"), az ve yumuşak bir olumsuz + bol olumlu; "Tavsiyem" ile bitirme. Uzunluk: 550-900 karakter.',
    },
    {
      id: 'durugoru_gno', file: 'durugoru_gno.json', key: 'durugoru_gno', matcher: 'M1', kitle: KITLE_M1, orijinalMaxId: 46,
      tur: 'Durugörü',
      sistem: 'Kullanıcı "Geleceğimde neler var?" sorusunu seçer; Magnus odaklanır ve aylar sonrasını anlatır (çoğu "Geleceğine odaklandığımda, seni {{ay_5}} ayında … görüyorum {{isim}}" duygusunda, ama hep aynı açılışla değil). Metin gelen kutusuna tek parça düşer.',
      gorev: 'GELECEK — birkaç ay sonrasından ({{ay_N}}) bir sahne ve ona giden yol: bir gelişme, bir kişi, bir değişim; zaman geniş, doku canlı. Uzunluk: 380-650 karakter.',
    },
  ],
};
const getPath = (o, p) => p.split('.').reduce((a, k) => (a == null ? a : a[k]), o);

const ORTAK_YER = 'YER TUTUCULAR (yalnız bunları, AYNEN yaz): {{isim}} = kullanıcının adı; {{ay_N}} = bugünden N ay sonraki ayın adı (ör. {{ay_2}}); {{sayi,a,b}} = a ile b arası rastgele sayı (BOŞLUKSUZ, ör. {{sayi,2,6}}); {{randomtarih,a,b}} = bugünden a-b gün sonraki tarih (ör. "17 Ocak"); {{kelime, A | B | C}} = seçeneklerden rastgele biri; {{harf}} = rastgele bir harf (isim baş harfi için); {{gun_N}} = N gün sonraki haftanın günü adı; {{burc}} = kullanıcının burcu. Cinsiyete göre kelime gerekirse: {{data, cinsiyet=erkek, X | cinsiyet=kadin, Y}}. {{yil_+1}} gibi artı işaretli biçim YASAK.';
const HEDEF = 'HEDEF: Okuyana "wow, bildin!" dedirtecek, BİLİYOR HİSSİ VEREN, SPESİFİK GÖRÜNEN metinler. Somut gündelik ayrıntı kullan (bir mesaj, bir anahtar, bir koku, bir renk, bir sokak, bir harfle başlayan isim, bir ay/gün, bir sayı, bir alışkanlık) ve kişinin hayatına dokunan isabetli gözlemler yap. Herkese uyan basmakalıp klişelerden kaçın — ama ayrıntı, olayın TUTMA ihtimalini düşürmesin (aşağıdaki COLD READING kuralı).';
// Anıl (2026-11-05): gelecekten haberler iyi birer cold reading / Barnum cümlesi olsun; ayrıntılı görünsün, tutmama ihtimali en aza insin.
const COLD_READING = `COLD READING / BARNUM KURALI — EN ÖNEMLİ KALİTE ÖLÇÜTÜ:
Metin AYRINTILI ve kişiye özel GÖRÜNMELİ, ama okuyanların çoğunda GERÇEKTEN TUTMALI. Formül: DOKU SOMUT, OLAY YAYGIN, ZAMAN GENİŞ.
1. OLAY yüksek olasılıklı olsun: çoğu insanın o zaman aralığında gerçekten yaşadığı şeyler — beklenen bir dönüşün (mesaj/arama/cevap) gecikmesi ya da gelmesi, küçük bir ödeme/iade/indirim, kaybolan bir eşyanın bulunması, birinin geçmişten bir konuyu açması, bir planın ertelenmesi ya da öne alınması, ertelenmiş bir işin bitmesi, bir tanıdığın aklına gelmesi/haber vermesi, yorgunluk ve toparlanma, bir karar öncesi kararsızlık, ev/iş düzeninde küçük bir değişiklik, beklenmedik küçük bir iltifat.
2. AYRINTI dokuda olsun, olayda değil: somut görünen ama neredeyse her zaman doğru ya da kişinin kendi hayatına uydurabileceği ayrıntılar — bir fincan çay, koyu renk giyen biri, telefonda okunmamış/ertelenmiş bir mesaj, çekmecede uzun süredir duran bir şey, yarım kalmış bir iş, "senden yaşça büyük biri", "konuşurken ellerini kullanan biri". DAR ve KONTROL EDİLEBİLİR ayrıntı YASAK: kesin saat ("saat 15.00'te"), kesin para tutarı, adı verilen mekân/marka, nadir ve tek seferlik olay (kurye yanlış paket getirir, komşu düğün davetiyesi uzatır, kütüphanede kayıp kitap bulunur), üç özellikli dar kişi tarifi ("kızıl saçlı, gözlüklü, yeşil ceketli kadın").
3. ZAMAN penceresi geniş ve esnek: "önümüzdeki günlerde", "bu hafta bitmeden", "ay dönmeden", "{{sayi,3,10}} gün içinde", Bugün/Yarın'da "günün bir anında", "akşama doğru". Tek bir kesin gün+saat verme.
4. ÖZNEL DOĞRULAMA: olayı iç deneyime bağla — "fark edeceksin", "içinden geçecek", "bir an duraksayacaksın", "omzundan bir yük kalkacak" — okuyan kendi yaşadığını buraya yerleştirir.
5. BARNUM + GÖKKUŞAĞI: herkesin kendinde gördüğü ama kişiye özel hissettiren tespitler ("dışarıdan sakin görünsen de bazı geceler zihnin susmuyor", "insanlara bazen hak ettiklerinden fazla şans veriyorsun"); iki zıt yönü birlikte söyle ("kalabalıkta rahatsın ama asıl dinlendiğin yer kendi köşen").
6. ZARİF TEK ÇIKIŞ KAPISI: olayı, birden çok gerçek karşılığı olabilecek tek ve canlı bir ifadeyle söyle: "beklediğin bir dönüş" (mesaj da olur, arama da, e-posta da), "eline geçecek bir kâğıt" (fatura, fiş, belge), "eski bir tanıdık". "belki X, belki Y, belki Z" LİSTESİ değil — tek, kapsayıcı ama canlı ifade.
7. Olumlu yorumlanabilir ol; olumsuz kesin hüküm verme. Kendini gerçekleştiren bir öneri ekleyebilirsin ("o mesajı bu kez sen yazarsan…").
8. TUTMA TESTİ: Her metni bitirince sor: "Bunu okuyan 100 kişiden kaçı 'evet, bu bende de oldu/oluyor/olabilir' der?" Hedef: en az 60. Altındaysa olayı yaygınlaştır, zamanı genişlet, kişi tarifini gevşet — dokuyu (renk, koku, nesne, cümle) koru.
⚠️ Bu kuraldaki örnek ifadeler ("küçük bir ödeme/iade", "koyu renk giyen biri", "senden yaşça büyük biri", "okunmamış bir mesaj", "çekmecede duran bir şey", "plakası okunmayan araba"…) yalnız TÜR örneğidir: AYNEN KULLANMA, her metinde kendi özgün somut karşılığını üret. Aynı imge/olay/kişi tarifi metinlerin en fazla birinde geçebilir; metinler birbirinden ifade ödünç almasın.
9. DUYGU DOZU: çok az negatif, sonra bol pozitif. Olumsuzluk küçük ve yumuşatılmış olsun ("canını BİRAZ sıkABİLİR"), hemen ardından büyük olumlu gelsin (havadis, müjde, gelişme, sevinç). Her metinde olumsuz olmak zorunda değil; olunca hep tek ve hafif.`;
// Anıl'ın kendi yazdığı altın örnekler + çözümlemesi (KOPYALANMAZ, yapısı öğrenilir)
const ALTIN_ORNEK = `ALTIN ÖRNEKLER (uygulamanın sahibi yazdı — yapısını çöz, cümlelerini KOPYALAMA):
A) "İlerleyen günlerde, alacağın bir telefon canını biraz sıkabilir. Ancak hemen birkaç saat sonrasında sözlü olarak bir yere çağırılacak ve orada konuşacağın insandan büyük bir havadis alarak çok sevineceksin."
B) "Plakası pek okunmayan, camları kirli bir arabadan, senden yaşça büyük biri inecek ve seni sözleriyle çok sevindirecek."
NEDEN İYİLER:
- ZAMAN geniş ama ZİNCİRLİ: "ilerleyen günlerde" (geniş) → "hemen birkaç saat sonrasında" (önceki olaya bağlı göreli zaman: kesinlik HİSSİ verir, kontrol edilemez).
- NASIL/KANAL her adımda değişir: telefon → sözlü davet → yüz yüze konuşma.
- YER ve KİŞİ varmış gibi ama geniş: "bir yere", "orada", "konuşacağın insan", "senden yaşça büyük biri".
- DOKU canlı ama yanlışlanamaz: "plakası pek okunmayan, camları kirli bir araba" — sahne gözde canlanır, kimse yalanlayamaz.
- DUYGU sırası: önce AZ ve yumuşatılmış olumsuz ("biraz" + "-abilir"), hemen ardından BOL olumlu ("büyük bir havadis", "çok sevineceksin").
- SONUÇ öznel: "sözleriyle sevindirecek" — okuyan sevinci kendi yaşadığı habere bağlar.
TÜMLEÇLER VE İSKELET:
- Dolaylı tümleç (kime / kimden / nereye / nereden) ve zarf tümleci (ne zaman / nasıl / ne kadar / kaç kez) bilgilerini BOL ve ÇEŞİTLİ kullan. Her metinde "ne, nerede, nereden, nasıl, ne zaman, kaç tane" sorularından EN AZ İKİSİNİN cevabı verilmiş gibi hissettir (A: ne zaman + nasıl + kimden; B: nereden + kim + nasıl). "Kaç tane" için: "iki ayrı haber", "üç gün arayla", "{{sayi,2,4}} kişilik bir masa".
- İSKELET ÇEŞİTLİLİĞİ: her metin başka bir öğeyle açılsın ve başka bir cümle düzeniyle ilerlesin — zaman zarfıyla (A gibi), yer/nesne betimiyle (B gibi), bir kişiyle, bir duyguyla, bir sayıyla, bir ses/kokuyla, bir soruyla, bir karşıtlıkla. Aynı iskelet 20 metinde en fazla 2 kez.
KİŞİYE ÖZEL HİSSETTİR (kimi metinde ismi, kimi metinde diğer özellikleri):
- Kimi metinde adıyla seslen: {{isim}} (yönelme {{isime}}, ayrılma {{isimden}}, sevgi {{isimcigim}}). Kimi metinde burcuna ({{burc}}) ya da yaşına ({{yas}}) dokun ("{{burc}} burcunun o inadı…", "{{yas}} yaşın getirdiği…"). Hepsini aynı metne doldurma; 20 metinde dağıt.
- KOŞULLU metinde kitlenin dünyasını kullan: özel sektör → "çalıştığın yerde", "iş yerinde", "mesai arkadaşların", "yöneticin"; kamu sektörü → "kurumda", "amirin", "evrak"; öğrenci → "okulda", "derste", "sınav haftası"; akademisyen → "bölümde", "makale", "öğrencilerin"; ev hanımı → "evinin düzeni", "komşuların"; emekli → "yılların birikimi", "eski çalışma arkadaşların"; evli → "eşin", "eşinle"; ilişkisi var → "sevdiğin kişi"; nişanlı → "nişanlın", "düğün hazırlığı"; yeni ayrılmış/boşanmış → "geride bıraktığın", "yeni düzenin"; bekar → "kalbinin kapısı"; 25 yaş altı → "arkadaş grubun", "ilk"ler; 40 yaş üstü → "tecrüben", "çocuklar/gençler". KOŞULSUZ metinde bu varsayımları YAPMA (orada yalnız isim/burç/yaş yer tutucuları ve {{data, cinsiyet=erkek, X | cinsiyet=kadin, Y}}).`;
const CESITLILIK = `ÖRNEKLER YALNIZCA YAPI İÇİN — ÇOK ÖNEMLİ:
- Aşağıdaki ${ORNEK} gerçek örneğe BİRE BİR benzeme. Cümle kalıplarını, sembolleri, olayları, ifadeleri KOPYALAMA. Yalnızca YAPISAL olarak benze: uzunluk, hitap, akış (gözlem → anlam → somut öngörü), yer tutucu kullanımı.
- "Yapısal benzerlik" moda mod kalıp DEĞİLDİR. YANLIŞ: "Salı günü müjden var." / "Çarşamba günü müjden var." / "Perşembe müjden var." (aynı kalıba başka kelime koymak).
- DOĞRU: Her metin öngörünün boyutlarını DEĞİŞTİRİR, her seferinde farklı soruların cevabını verir:
  • NE olacak (müjde, teklif, karşılaşma, kayıp bir eşyanın bulunması, borcun ödenmesi, davet, karar, sürpriz, bir kapanış…)
  • NEREDEN / NEREDE (iş yeri, akraba, eski okul, komşu, resmî bir kurum, yolculuk, internet, pazar yeri…)
  • KİM ARACILIĞIYLA (baş harfi verilen biri, yaşlı bir kadın, bir çocuk, bir meslektaş, bir kurye, eski bir dost…)
  • NASIL (telefon, mesaj, mektup, yüz yüze, bir belge, para olarak, bir hediye, bir rüya, bir tesadüf…)
  • NE ZAMAN (gün, hafta, ay, mevsim, saat dilimi, "şu olaydan hemen sonra"…)
  • SONUÇ nasıl hissedilir, neye dönüşür.
- Bir sonuç söylüyorsan NASIL'ını somutla: "keyfin yerine gelecek" deme yeter değil → bir haberle mi, eline geçen bir parayla mı, beklediğin bir gelişmenin tamamına ermesiyle mi? (NASIL'ı yaygın kanallardan seç: mesaj, arama, yüz yüze bir sohbet, hesaba geçen bir ödeme, bitirilen bir iş — nadir/tek seferlik olaylardan değil.)
- 20 metnin hiçbirinde aynı "ne + nasıl + kim" üçlüsü tekrar etmesin; açılış cümleleri de birbirinden farklı olsun.
- KALIP YASAKLARI (tur 2'de yakalandı): metni "Tavsiyem: …" öğüdüyle bitirme; "Öğleye doğru… Öğleden sonra… Akşamüstü… Akşam…" saat zinciri kurma (bir metinde en fazla 2 zaman ifadesi; kimi metin tek bir sahneyi derinleştirsin); "belki X, belki Y" listesi yazma (olay tek ve canlı bir ifadeyle — ama COLD READING kuralı gereği YAYGIN bir olay); "adında {{harf}} harfi olan biri" 20 metnin en fazla 2'sinde.
- GİZLİ VARSAYIM YAPMA: kitlede yazmayanı varsayma ("nişanlı" cinsiyetsizdir — damat/gelin deme; "ev hanımı" evli olmak zorunda değil; "boşanmış" çocuklu olmak zorunda değil; anne/babanın öldüğünü ima etme).`;
const YASAK = 'YASAKLAR: hastalık, ölüm, kaza, felaket, aldatma kehaneti yok; kesinlik/garanti iddiası yok; yapay zekâ olduğunu söyleme; emoji en fazla 1.';

const list = TURLAR[tur];
if (!list || !list.length) { console.error('TURLAR[' + tur + '] boş'); process.exit(1); }
for (const k of list) {
  const raw = JSON.parse(fs.readFileSync(path.join('assets/data', k.file), 'utf8'));
  const tumHavuz = getPath(raw, k.key);
  // Örnekler yalnız Anıl'ın orijinal metinlerinden (önceki turların yapay metinleri örnek olmaz)
  const pool = k.orijinalMaxId ? tumHavuz.filter(e => typeof e.id !== 'number' || e.id <= k.orijinalMaxId) : tumHavuz;
  const r = rnd(tur * 1000 + k.id.length * 17);
  const lens = pool.map(e => e.metin.length).sort((a, b) => a - b);
  const med = lens[Math.floor(lens.length / 2)];
  const ok = e => e.metin.length > med * 0.45 && e.metin.length < med * 1.7 && !/kadın'|lgbt/.test(JSON.stringify(etkin(e)));
  const adaylar = pool.filter(ok);
  const nUncond = Math.round(ORNEK * 0.45);
  const uncond = shuffle(adaylar.filter(e => !etkin(e).length), r).slice(0, nUncond);
  const cond = shuffle(adaylar.filter(e => etkin(e).length), r).slice(0, ORNEK - uncond.length);
  let samples = uncond.concat(cond);
  if (samples.length < ORNEK) samples = samples.concat(shuffle(pool.filter(e => !samples.includes(e)), r).slice(0, ORNEK - samples.length));
  samples = shuffle(samples, r);
  const N = k.adet || 20; // kısa metinli bölmede 40 (karşı model yarısını seçer)
  let kit = [];
  while (kit.length < N) kit = kit.concat(shuffle(k.kitle, r));
  kit = kit.slice(0, N);
  const KONU = ['genel', 'genel', 'genel', 'genel', 'genel', 'genel', 'aşk', 'aşk', 'aşk', 'aşk', 'aşk', 'aşk', 'kariyer', 'kariyer', 'kariyer', 'kariyer', 'sağlık', 'sağlık', 'sağlık', 'sağlık'];
  const konular = k.konu ? [].concat(...Array.from({ length: Math.ceil(N / 20) }, () => shuffle(KONU, r))).slice(0, N) : null;

  let s = `Magnus adlı bir fal uygulamasının metin yazarısın. Bu uygulamanın gerçek metinlerini yazan kişinin üslubunu sürdüreceksin.\n\n`;
  s += `FAL TÜRÜ: ${k.tur}\nSİSTEM: ${k.sistem}\nKOMPARTMAN: ${k.gorev}\n`;
  s += (k.uslup || `ÜSLUP: Magnus birinci tekil konuşur ("görüyorum", "gözüme çarptı"), kullanıcıya "sen" diye hitap eder; sıcak, hafif esprili, gizemli, kendinden emin.`) + `\n\n`;
  s += `${HEDEF}\n\n${COLD_READING}\n\n${ALTIN_ORNEK}\n\n${CESITLILIK}\n\n${ORTAK_YER}\n\n${YASAK}${k.ekYasak ? ' ' + k.ekYasak : ''}\n\n`;
  s += `KİTLE KURALI: Her metni aşağıda numarasıyla verilen kitleye göre yaz. "Koşulsuz" metin herkese gösterilir; içinde cinsiyet, medeni durum, meslek, yaş VARSAYMA. Koşullu metin yalnız o kitleye gösterilir; içeriği o kitleye özel ve isabetli olsun.\n\n`;
  s += `YAZILACAK ${N} METİN:\n`;
  kit.forEach((x, i) => { s += `${i + 1}. kitle: ${x}${konular ? ` | konu: ${konular[i]}` : ''}\n`; });
  s += `\nGERÇEK ÖRNEK METİNLER (uygulamadan, kitleleriyle — yalnız YAPI için):\n\n`;
  samples.forEach((e, i) => { s += `--- Örnek ${i + 1} | kitle: ${kitle(etkin(e))} ---\n${e.metin}\n\n`; });
  s += `ÇIKTI: Yalnızca bir JSON dizisi, tek bir kod bloğu içinde, ${N} öğe:\n[{"no":1,"kitle":"…","metin":"…"}, …]\nMetinlerdeki satır sonlarını \\n olarak yaz. Başka açıklama ekleme.\n`;
  fs.writeFileSync(path.join(outDir, `tur${tur}_${k.id}.txt`), s);
  fs.writeFileSync(path.join(outDir, `tur${tur}_${k.id}_meta.json`), JSON.stringify({ id: k.id, file: k.file, key: k.key, matcher: k.matcher, extra: k.extra || null, kitle: kit, konu: konular, ornekIds: samples.map(e => e.id) }, null, 1));
  console.log(k.id, 'havuz', pool.length, 'medyan', med, 'örnek', samples.length, 'brief', s.length, 'karakter');
}
