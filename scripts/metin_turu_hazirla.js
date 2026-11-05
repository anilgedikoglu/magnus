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
};

const ORTAK_YER = 'YER TUTUCULAR (yalnız bunları, AYNEN yaz): {{isim}} = kullanıcının adı; {{ay_N}} = bugünden N ay sonraki ayın adı (ör. {{ay_2}}); {{sayi,a,b}} = a ile b arası rastgele sayı (BOŞLUKSUZ, ör. {{sayi,2,6}}); {{randomtarih,a,b}} = bugünden a-b gün sonraki tarih (ör. "17 Ocak"); {{kelime, A | B | C}} = seçeneklerden rastgele biri; {{harf}} = rastgele bir harf (isim baş harfi için); {{gun_N}} = N gün sonraki haftanın günü adı; {{burc}} = kullanıcının burcu. Cinsiyete göre kelime gerekirse: {{data, cinsiyet=erkek, X | cinsiyet=kadin, Y}}. {{yil_+1}} gibi artı işaretli biçim YASAK.';
const HEDEF = 'HEDEF: Okuyana "wow, bildin!" dedirtecek, BİLİYOR HİSSİ VEREN, SPESİFİK metinler. Somut gündelik ayrıntı kullan (bir mesaj, bir anahtar, bir koku, bir renk, bir sokak, bir harfle başlayan isim, bir ay/gün, bir sayı, bir alışkanlık) ve kişinin hayatına dokunan isabetli gözlemler yap. Herkese uyan klişelerden kaçın.';
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
- Bir sonuç söylüyorsan NASIL'ını somutla: "keyfin yerine gelecek" deme yeter değil → bir haberle mi, eline geçen bir parayla mı, beklediğin bir gelişmenin tamamına ermesiyle mi?
- 20 metnin hiçbirinde aynı "ne + nasıl + kim" üçlüsü tekrar etmesin; açılış cümleleri de birbirinden farklı olsun.
- KALIP YASAKLARI (tur 2'de yakalandı): metni "Tavsiyem: …" öğüdüyle bitirme; "Öğleye doğru… Öğleden sonra… Akşamüstü… Akşam…" saat zinciri kurma (bir metinde en fazla 2 zaman ifadesi; kimi metin tek bir sahneyi derinleştirsin); "belki X, belki Y" listesi yazma (olay TEK ve somut); "adında {{harf}} harfi olan biri" 20 metnin en fazla 2'sinde.
- GİZLİ VARSAYIM YAPMA: kitlede yazmayanı varsayma ("nişanlı" cinsiyetsizdir — damat/gelin deme; "ev hanımı" evli olmak zorunda değil; "boşanmış" çocuklu olmak zorunda değil; anne/babanın öldüğünü ima etme).`;
const YASAK = 'YASAKLAR: hastalık, ölüm, kaza, felaket, aldatma kehaneti yok; kesinlik/garanti iddiası yok; yapay zekâ olduğunu söyleme; emoji en fazla 1.';

const list = TURLAR[tur];
if (!list || !list.length) { console.error('TURLAR[' + tur + '] boş'); process.exit(1); }
for (const k of list) {
  const raw = JSON.parse(fs.readFileSync(path.join('assets/data', k.file), 'utf8'));
  const pool = raw[k.key];
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
  const kit = shuffle(k.kitle, r).slice(0, 20);
  const KONU = ['genel', 'genel', 'genel', 'genel', 'genel', 'genel', 'aşk', 'aşk', 'aşk', 'aşk', 'aşk', 'aşk', 'kariyer', 'kariyer', 'kariyer', 'kariyer', 'sağlık', 'sağlık', 'sağlık', 'sağlık'];
  const konular = k.konu ? shuffle(KONU, r) : null;

  let s = `Magnus adlı bir fal uygulamasının metin yazarısın. Bu uygulamanın gerçek metinlerini yazan kişinin üslubunu sürdüreceksin.\n\n`;
  s += `FAL TÜRÜ: ${k.tur}\nSİSTEM: ${k.sistem}\nKOMPARTMAN: ${k.gorev}\n`;
  s += `ÜSLUP: Magnus birinci tekil konuşur ("görüyorum", "gözüme çarptı"), kullanıcıya "sen" diye hitap eder; sıcak, hafif esprili, gizemli, kendinden emin.\n\n`;
  s += `${HEDEF}\n\n${CESITLILIK}\n\n${ORTAK_YER}\n\n${YASAK}\n\n`;
  s += `KİTLE KURALI: Her metni aşağıda numarasıyla verilen kitleye göre yaz. "Koşulsuz" metin herkese gösterilir; içinde cinsiyet, medeni durum, meslek, yaş VARSAYMA. Koşullu metin yalnız o kitleye gösterilir; içeriği o kitleye özel ve isabetli olsun.\n\n`;
  s += `YAZILACAK 20 METİN:\n`;
  kit.forEach((x, i) => { s += `${i + 1}. kitle: ${x}${konular ? ` | konu: ${konular[i]}` : ''}\n`; });
  s += `\nGERÇEK ÖRNEK METİNLER (uygulamadan, kitleleriyle — yalnız YAPI için):\n\n`;
  samples.forEach((e, i) => { s += `--- Örnek ${i + 1} | kitle: ${kitle(etkin(e))} ---\n${e.metin}\n\n`; });
  s += `ÇIKTI: Yalnızca bir JSON dizisi, tek bir kod bloğu içinde, 20 öğe:\n[{"no":1,"kitle":"…","metin":"…"}, …]\nMetinlerdeki satır sonlarını \\n olarak yaz. Başka açıklama ekleme.\n`;
  fs.writeFileSync(path.join(outDir, `tur${tur}_${k.id}.txt`), s);
  fs.writeFileSync(path.join(outDir, `tur${tur}_${k.id}_meta.json`), JSON.stringify({ id: k.id, file: k.file, key: k.key, matcher: k.matcher, extra: k.extra || null, kitle: kit, konu: konular, ornekIds: samples.map(e => e.id) }, null, 1));
  console.log(k.id, 'havuz', pool.length, 'medyan', med, 'örnek', samples.length, 'brief', s.length, 'karakter');
}
