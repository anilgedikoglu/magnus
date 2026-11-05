// magnus-metin-uretimi: bir tur için kompartman başına brief dosyası üretir (10 örnek + 20 hedef kitle).
// Kullanım: node scripts/metin_turu_hazirla.js <çıktı_klasörü> <tur_no>
// Kompartman tanımları aşağıda (TUR listesi). Örnekler deterministik seçilir (tohum = tur_no).
const fs = require('fs');
const path = require('path');
const outDir = process.argv[2];
const tur = parseInt(process.argv[3] || '1', 10);
fs.mkdirSync(outDir, { recursive: true });

function rnd(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }
function shuffle(a, r) { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; }

const LBL = {
  cinsiyet: { kadin: 'kadın', 'kadın': 'kadın', erkek: 'erkek' },
};
function kitle(kosullar) {
  if (!kosullar || !kosullar.length) return 'koşulsuz (herkes)';
  return kosullar.map(k => {
    const d = k.degisken, v = String(k.deger);
    if (d === 'yasmax') return `${v} yaş ve altı`;
    if (d === 'yasmin') return `${v} yaş ve üstü`;
    return `${d.replace('_', ' ')}: ${v}`;
  }).join(' + ');
}

// Hedef kitle havuzu (nötr dil; ekleme sırasında eşleştiriciye göre etikete çevrilir)
const KITLE_M1 = [
  'koşulsuz (herkes)', 'koşulsuz (herkes)', 'koşulsuz (herkes)', 'koşulsuz (herkes)', 'koşulsuz (herkes)',
  'kadın', 'erkek', 'evli', 'ilişkisi yok (bekar)', 'ilişkisi var', 'yeni ayrılmış', 'öğrenci',
  'özel sektör çalışanı', 'kamu sektörü çalışanı', 'kadın + evli', 'erkek + ilişkisi yok (bekar)',
  '25 yaş ve altı', '40 yaş ve üstü', 'ev hanımı', 'emekli', 'akademisyen', 'nişanlı', 'boşanmış',
  'kadın + ilişkisi yok (bekar)', 'erkek + evli',
];
const KITLE_M5 = KITLE_M1.filter(k => !/yaş/.test(k)).concat(['iş arıyor', 'kendi işini yapıyor']);

const TUR = [
  {
    id: 'kahve_gelisme', file: 'kahve_gelisme.json', key: 'gelismeler', matcher: 'M1', kitle: KITLE_M1,
    konu: true,
    tur: 'Kahve falı',
    sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: karşılama → giriş → bağlama → GELİŞME → sonuç → uğurlama. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir; bu yüzden her metin tek başına anlamlı olmalı ve öncesi/sonrasıyla çelişmemeli (selam verme, veda etme, "ilk olarak" deme).',
    gorev: 'GELİŞME — falın ana bölümü: fincanın orta kısmında görülen ana sembol(ler) ve buna dayalı somut öngörüler; çoğu zaman bir ay/tarih ya da sayı verir. Uzunluk: 700-1200 karakter, 2-4 paragraf.',
  },
  {
    id: 'kahve_sonuc', file: 'kahve_sonuc.json', key: 'sonuclar', matcher: 'M1', kitle: KITLE_M1, konu: true,
    tur: 'Kahve falı',
    sistem: 'Uygulama kullanıcının fincan fotoğrafına bakıp 6 parçalı bir fal oluşturur: karşılama → giriş → bağlama → gelişme → SONUÇ → uğurlama. Her parça kendi havuzundan rastgele seçilir ve alt alta eklenir; her metin tek başına anlamlı olmalı ve öncesi/sonrasıyla çelişmemeli (selam/veda yok).',
    gorev: 'SONUÇ — fincanın dibine / tabana yakın kısımdaki semboller ve falın varacağı sonuç; somut bir öngörüyle biter. Uzunluk: 400-800 karakter.',
  },
  {
    id: 'durugoru_gno', file: 'durugoru_gno.json', key: 'durugoru_gno', matcher: 'M1', kitle: KITLE_M1,
    tur: 'Durugörü',
    sistem: 'Kullanıcı "Geleceğimde ne görüyorsun?" sorusunu seçer; Magnus odaklanır ve uzak gelecekte gördüğü TEK bir somut sahneyi anlatır. Metin gelen kutusuna tek parça düşer.',
    gorev: 'GELECEK — Magnus kullanıcıyı gelecekte belirli bir anda (ay adı, mekân, kişiler, nesneler) "görür" ve sahnenin anlamını söyler. Uzunluk: 400-650 karakter.',
  },
  {
    id: 'yana_bana', file: 'yana.json', key: 'bana_dair', matcher: 'M4', kitle: KITLE_M1, extra: { tur: 'bana' },
    tur: 'Yana (Magnuskop kehaneti)',
    sistem: 'Kullanıcı "Bana dair" kehaneti ister; Magnus "Magnuskop" adlı aletini kullanıcının birkaç yıl sonrasına ayarlar ve onu orada nasıl gördüğünü anlatır. Tek parça metin.',
    gorev: 'BANA DAİR — kullanıcının kendi geleceğinden (1-10 yıl sonrası) somut bir an: nerede, ne yapıyor, yanında kim/ne var. Uzunluk: 250-450 karakter.',
  },
  {
    id: 'tavsanfali', file: 'tavsanfali.json', key: 'tavsanfali', matcher: 'M5', kitle: KITLE_M5,
    tur: 'Tavşan falı',
    sistem: 'Kullanıcı bir kâğıda dokunur, tavşan 5 kâğıttan birini çeker; kâğıtta gelecek, kısmet, nasibe dair kısa bir öngörü yazar. Tek parça, çok kısa.',
    gorev: 'TAVŞAN KÂĞIDI — 1-2 cümle: "{{isim}}, <zaman ifadesi> <somut olay>. <kısa devamı>." Uzunluk: 90-150 karakter.',
  },
];

const ORTAK_YER = 'YER TUTUCULAR (yalnız bunları, AYNEN yaz): {{isim}} = kullanıcının adı; {{ay_N}} = bugünden N ay sonraki ayın adı (ör. {{ay_2}}); {{sayi,a,b}} = a ile b arası rastgele sayı (BOŞLUKSUZ, ör. {{sayi,2,6}}); {{kelime, A | B | C}} = seçeneklerden rastgele biri; {{harf}} = rastgele bir harf (isim baş harfi için); {{gun_N}} = N gün sonraki haftanın günü adı; {{burc}} = kullanıcının burcu. Cinsiyete göre kelime gerekirse: {{data, cinsiyet=erkek, X | cinsiyet=kadin, Y}}.';
const HEDEF = 'HEDEF: Okuyana "wow, bildin!" dedirtecek, BİLİYOR HİSSİ VEREN, SPESİFİK metinler. Somut gündelik ayrıntı kullan (bir mesaj, bir anahtar, bir koku, bir renk, bir sokak, bir harfle başlayan isim, bir ay/gün, bir sayı, bir alışkanlık) ve kişinin hayatına dokunan isabetli gözlemler yap. Herkese uyan klişelerden kaçın. Aşağıdaki gerçek örneklerin ÜSLUBUNA ve SİSTEMİNE benze ama onları kopyalama, aynı sembolleri tekrar etme.';
const YASAK = 'YASAKLAR: hastalık, ölüm, kaza, felaket, aldatma kehaneti yok; kesinlik/garanti iddiası yok; yapay zekâ olduğunu söyleme; emoji kullanma (örneklerde varsa bile en fazla 1).';

for (const k of TUR) {
  const raw = JSON.parse(fs.readFileSync(path.join('assets/data', k.file), 'utf8'));
  const pool = raw[k.key];
  const r = rnd(tur * 1000 + k.id.length * 17);
  const lens = pool.map(e => e.metin.length).sort((a, b) => a - b);
  const med = lens[Math.floor(lens.length / 2)];
  const ok = e => e.metin.length > med * 0.5 && e.metin.length < med * 1.6 && !/kadın'|lgbt|saatm/.test(JSON.stringify(e.kosullar || []));
  const uncond = shuffle(pool.filter(e => ok(e) && !(e.kosullar || []).length), r).slice(0, 4);
  const cond = shuffle(pool.filter(e => ok(e) && (e.kosullar || []).length), r).slice(0, 10 - uncond.length);
  const samples = shuffle(uncond.concat(cond), r);
  const kit = shuffle(k.kitle, r).slice(0, 20);
  // konu (yalnız kahve): metin konusu
  const KONU = ['genel', 'genel', 'genel', 'genel', 'genel', 'genel', 'aşk', 'aşk', 'aşk', 'aşk', 'aşk', 'aşk', 'kariyer', 'kariyer', 'kariyer', 'kariyer', 'sağlık', 'sağlık', 'sağlık', 'sağlık'];
  const konular = k.konu ? shuffle(KONU, r) : null;

  let s = `Magnus adlı bir fal uygulamasının metin yazarısın. Bu uygulamanın gerçek metinlerini yazan kişinin üslubunu sürdüreceksin.\n\n`;
  s += `FAL TÜRÜ: ${k.tur}\nSİSTEM: ${k.sistem}\nKOMPARTMAN: ${k.gorev}\n`;
  s += `ÜSLUP: Magnus birinci tekil konuşur ("görüyorum", "gözüme çarptı"), kullanıcıya "sen" diye hitap eder; sıcak, hafif esprili, gizemli, kendinden emin.\n\n`;
  s += `${HEDEF}\n\n${ORTAK_YER}\n\n${YASAK}\n\n`;
  s += `KİTLE KURALI: Her metni aşağıda numarasıyla verilen kitleye göre yaz. "Koşulsuz" metin herkese gösterilir; içinde cinsiyet, medeni durum, meslek, yaş VARSAYMA. Koşullu metin yalnız o kitleye gösterilir; içeriği o kitleye özel ve isabetli olsun (ör. "evli" için eşle ilgili, "öğrenci" için okul/sınav ile ilgili somut ayrıntı).\n\n`;
  s += `YAZILACAK 20 METİN:\n`;
  kit.forEach((x, i) => { s += `${i + 1}. kitle: ${x}${konular ? ` | konu: ${konular[i]}` : ''}\n`; });
  s += `\nGERÇEK ÖRNEK METİNLER (uygulamadan, kitleleriyle):\n\n`;
  samples.forEach((e, i) => { s += `--- Örnek ${i + 1} | kitle: ${kitle(e.kosullar)} ---\n${e.metin}\n\n`; });
  s += `ÇIKTI: Yalnızca bir JSON dizisi, tek bir kod bloğu içinde, 20 öğe:\n[{"no":1,"kitle":"…","metin":"…"}, …]\nMetinlerdeki satır sonlarını \\n olarak yaz. Başka açıklama ekleme.\n`;
  fs.writeFileSync(path.join(outDir, `tur${tur}_${k.id}.txt`), s);
  fs.writeFileSync(path.join(outDir, `tur${tur}_${k.id}_meta.json`), JSON.stringify({ id: k.id, file: k.file, key: k.key, matcher: k.matcher, extra: k.extra || null, kitle: kit, konu: konular, ornekIds: samples.map(e => e.id) }, null, 1));
  console.log(k.id, 'havuz', pool.length, 'medyan', med, 'brief', s.length, 'karakter');
}
