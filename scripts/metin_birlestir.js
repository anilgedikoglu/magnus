// magnus-metin-uretimi: seçilen 10+10 metni toplar, kitleyi eşleştiriciye göre kosullar'a çevirir,
// yer tutucuları düzeltir/denetler ve bir "aday" dosyası yazar (insan/Claude gözden geçirmesi için).
// Kullanım:
//   node scripts/metin_birlestir.js aday   <indirilen> <tur_klasoru> <tur> <id>   → <id>_aday.json
//   node scripts/metin_birlestir.js ekle   <tur_klasoru> <tur> <id>               → aday + _en.json'u JSON'a ekler
const fs = require('fs');
const path = require('path');
const [mode, ...rest] = process.argv.slice(2);

const ALLOWED_PH = /^(isim|isime|isimi|isimden|isimcigim|harf|sabit_harf|burc|burc_ilkHarfBuyuk|rastgeleburc|yas|meslek|medeni_durum|gelecek_ay|gecen_ay|simdiki_ay|tam saat|saat kac yazi|fiziki|kadinisim|erkekisim|xgundur|kullanici sehri|kullanici sehrinde|nereli|dogum gunu|dogum ayi|dogum yili|dogum ayi yazi)$|^(ay|gun|gunsayi|yil|mevsim|yas)_[+-]?\d+$|^(sayi|sabit_sayi),\d+,\d+$|^(kelime|sabitkelime|data|saat|kelimecins|medenidurum|randomtarih),/;

// Nötr kitle → koşullar (eşleştiriciye göre)
function kosullar(kitle, matcher) {
  const k = (kitle || '').toLowerCase();
  if (/koşulsuz/.test(k)) return [];
  const out = [];
  const add = (degisken, deger) => out.push({ degisken, deger });
  if (matcher === 'M7') return []; // Faloya yalnız koşulsuzu gösterir
  const M1 = matcher === 'M1', M4 = matcher === 'M4', M5 = matcher === 'M5', M3 = matcher === 'M3';
  if (/kadın/.test(k)) add('cinsiyet', 'kadin');
  if (/erkek/.test(k)) add('cinsiyet', 'erkek');
  const med = [['evli', 'evli', 'evli', 'evli'], ['ilişkisi yok', 'ilişkisi yok', 'ilişkisi yok', 'iliskisi_yok'],
    ['ilişkisi var', 'ilişkisi var', 'ilişkisi var', 'iliski_var'], ['yeni ayrılmış', 'yeni ayrılmış', 'yeni ayrılmış', 'yeni_ayrilmis'],
    ['nişanlı', 'nişanlı', 'nişanlı', 'nisanli'], ['boşanmış', 'boşanmış', 'boşanmış', 'bosanmis']];
  for (const [key, m1, m4, m5] of med) {
    // M3 (Niyet): toVariableMap['medeni durum'] varlık biçimi, birebir
    if (k.includes(key)) add(M1 || M3 ? 'medeni durum' : 'medeni_durum', M1 || M3 ? m1 : M4 ? m4 : m5);
  }
  const mes = [['öğrenci', 'öğrenci', 'öğrenci', 'ogrenci'], ['özel sektör', 'özel sektör', 'özel sektör', 'ozelsektoru'],
    ['kamu sektörü', 'kamu sektörü', 'kamu sektörü', 'kamusektoru'], ['ev hanımı', 'ev hanımı', 'ev hanımı', 'evhanimi'],
    ['emekli', 'emekli', 'emekli', 'emekli'], ['akademisyen', 'akademisyen', 'akademisyen', 'akademisyen'],
    ['iş arıyor', null, 'iş arıyor', 'isariyor'], ['kendi işini', null, 'kendi işini yapıyor', 'kendiisi']];
  // M3 (Niyet): toVariableMap['meslek'] = etiket (büyük harfli), birebir karşılaştırma
  const M3_ETIKET = { 'öğrenci': 'Öğrenci', 'özel sektör': 'Özel Sektör', 'kamu sektörü': 'Kamu Sektörü',
    'ev hanımı': 'Ev Hanımı', 'emekli': 'Emekli', 'akademisyen': 'Akademisyen', 'iş arıyor': 'İş Arıyor',
    'kendi işini': 'Kendi İşini Yapıyor' };
  for (const [key, m1, m4, m5] of mes) {
    if (k.includes(key)) {
      const v = M3 ? M3_ETIKET[key] : M1 ? m1 : M4 ? m4 : m5;
      if (v) add('meslek', v);
    }
  }
  // Yaş sınırı METİN olarak yazılır ("25"): orijinal veri böyle, ekranların çoğu `deger as String` okur
  // (sayı yazılırsa Kahve/Durugörü filtresi TypeError fırlatır — tur 1-2'de yakalandı).
  if (/25 yaş ve altı/.test(k) && !M5 && !M3) add('yasmax', '25');
  if (/40 yaş ve üstü/.test(k) && !M5 && !M3) add('yasmin', '40');
  return out;
}

function fixPh(metin, warn) {
  let m = metin
    .replace(/\{\{\s*(gun|ay)_N\s*\}\}/g, (_, x) => `{{${x}_2}}`)
    .replace(/\{\{yil_\+(\d+)\}\}/g, '{{yil_$1}}')
    .replace(/\{\{(sayi|sabit_sayi)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}\}/g, '{{$1,$2,$3}}')
    .replace(/cinsiyet=kadın/g, 'cinsiyet=kadin');
  for (const ph of m.match(/\{\{([^}]*)\}\}/g) || []) {
    const inner = ph.slice(2, -2).trim();
    if (!ALLOWED_PH.test(inner)) warn.push(`bilinmeyen yer tutucu ${ph}`);
  }
  if (!/[.!?…"”')]\s*$/.test(m.trim())) warn.push('noktalama ile bitmiyor');
  return m.trim();
}

const KONU_TAG = { 'genel': ['genel', 'ask', 'kariyer', 'saglik'], 'aşk': ['ask', 'genel'], 'kariyer': ['kariyer', 'genel'], 'sağlık': ['saglik', 'genel'] };

if (mode === 'aday') {
  const [inDir, turDir, tur, id] = rest;
  const meta = JSON.parse(fs.readFileSync(path.join(turDir, `tur${tur}_${id}_meta.json`), 'utf8'));
  const sec = JSON.parse(fs.readFileSync(path.join(turDir, 'secimler.json'), 'utf8'))[id];
  const pool = JSON.parse(fs.readFileSync(path.join('assets/data', meta.file), 'utf8'))[meta.key];
  const existing = new Set(pool.map(e => e.metin.slice(0, 40)));
  const out = [];
  for (const kaynak of ['chatgpt', 'deepseek']) {
    const arr = JSON.parse(fs.readFileSync(path.join(inDir, `tur${tur}_${id}_${kaynak}.json`), 'utf8'));
    for (const no of sec[kaynak]) {
      const t = arr.find(x => x.no === no);
      if (!t) { console.log('YOK', kaynak, no); continue; }
      const kitle = meta.kitle[no - 1] || t.kitle;
      const warn = [];
      const metin = fixPh(t.metin, warn);
      if (existing.has(metin.slice(0, 40))) warn.push('mevcut metinle aynı başlangıç');
      const e = { kaynak, no, kitle, metin, kosullar: kosullar(kitle, meta.matcher), uyari: warn };
      if (meta.konu) e.fal_konusu = KONU_TAG[meta.konu[no - 1]] || KONU_TAG.genel;
      out.push(e);
    }
  }
  fs.writeFileSync(path.join(turDir, `${id}_aday.json`), JSON.stringify(out, null, 1));
  console.log(id, 'aday', out.length, 'uyarı', out.filter(e => e.uyari.length).map(e => `${e.kaynak}#${e.no}:${e.uyari.join('/')}`).join(' | ') || 'yok');
} else if (mode === 'ekle') {
  const [turDir, tur, id] = rest;
  const meta = JSON.parse(fs.readFileSync(path.join(turDir, `tur${tur}_${id}_meta.json`), 'utf8'));
  const aday = JSON.parse(fs.readFileSync(path.join(turDir, `${id}_aday.json`), 'utf8'));
  const en = JSON.parse(fs.readFileSync(path.join(turDir, `${id}_en.json`), 'utf8'));
  if (en.length !== aday.length) throw new Error(`EN sayısı ${en.length} ≠ ${aday.length}`);
  const file = path.join('assets/data', meta.file);
  const raw = fs.readFileSync(file, 'utf8');
  const j = JSON.parse(raw);
  const pool = j[meta.key];
  const numeric = pool.every(e => typeof e.id === 'number');
  let next = numeric ? Math.max(...pool.map(e => e.id)) + 1 : null;
  const prefix = !numeric ? String(pool[pool.length - 1].id).replace(/\d+$/, '') : '';
  let nNext = !numeric ? Math.max(...pool.map(e => parseInt(String(e.id).replace(/\D/g, '') || '0', 10))) + 1 : null;
  const added = [];
  aday.forEach((a, i) => {
    const phTr = (a.metin.match(/\{\{[^}]*\}\}/g) || []).sort().join('|');
    const phEn = (en[i].match(/\{\{[^}]*\}\}/g) || []).sort().join('|');
    if (phTr !== phEn) console.log('UYARI yer tutucu TR/EN farklı', a.kaynak, a.no, phTr, '≠', phEn);
    const e = { id: numeric ? next++ : `${prefix}${nNext++}` };
    if (meta.extra) Object.assign(e, meta.extra);
    e.metin = a.metin;
    e.metin_en = en[i];
    e.kosullar = a.kosullar;
    if (a.fal_konusu) e.fal_konusu = a.fal_konusu;
    pool.push(e);
    added.push(e.id);
  });
  // Dosyanın mevcut girinti stilini koru (2 boşluk varsayılan)
  const indent = /\n\t/.test(raw) ? '\t' : (raw.match(/\n( +)"/) || [, '  '])[1];
  fs.writeFileSync(file, JSON.stringify(j, null, indent) + (raw.endsWith('\n') ? '\n' : ''));
  console.log(id, 'eklendi', added.length, 'id', added[0], '→', added[added.length - 1]);
}
