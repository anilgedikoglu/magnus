// magnus-metin-uretimi: aday metinlerde "moda mod" kalıp tekrarını ve kopyayı yakalar (eklemeden ÖNCE çalıştır).
// Kullanım:
//   node scripts/metin_kalip_tara.js <aday.json> [havuz.json:anahtar]
//   node scripts/metin_kalip_tara.js --havuz-araligi <havuz.json> <anahtar> <ilkId> <sonId>   (eklenmiş metinleri tara)
// Bulduğu her şey bir UYARI'dır; karar Claude'un. Çıkış kodu: ciddi bulgu varsa 1.
const fs = require('fs');

const args = process.argv.slice(2);
let yeni, havuz = [];
if (args[0] === '--havuz-araligi') {
  const [, file, key, a, b] = args;
  const list = JSON.parse(fs.readFileSync(file, 'utf8'))[key];
  const ia = +a, ib = +b;
  const inR = e => typeof e.id === 'number' && e.id >= ia && e.id <= ib;
  yeni = list.filter(inR).map(e => ({ ad: `#${e.id}`, metin: e.metin }));
  havuz = list.filter(e => !inR(e)).map(e => e.metin);
} else {
  yeni = JSON.parse(fs.readFileSync(args[0], 'utf8')).map((e, i) => ({ ad: e.kaynak ? `${e.kaynak[0]}${e.no}` : `#${i + 1}`, metin: e.metin }));
  if (args[1]) {
    const [file, key] = args[1].split(':');
    havuz = JSON.parse(fs.readFileSync(file, 'utf8'))[key].map(e => e.metin);
  }
}

const kelimeler = s => s.toLocaleLowerCase('tr').replace(/\{\{[^}]*\}\}/g, ' ').replace(/[^a-zçğıöşüâîû0-9 ]/g, ' ').split(/\s+/).filter(Boolean);
const gramlar = (w, n = 5) => { const g = new Set(); for (let i = 0; i + n <= w.length; i++) g.add(w.slice(i, i + n).join(' ')); return g; };

// Türün sabit çerçevesi (ör. Faloya "Merhaba … Varlıklar fısıldıyor …"): havuzun %30'undan fazlasında geçen 5-gramlar yok sayılır.
const sayac = new Map();
havuz.forEach(m => gramlar(kelimeler(m)).forEach(g => sayac.set(g, (sayac.get(g) || 0) + 1)));
const cerceve = new Set([...sayac].filter(([, n]) => havuz.length >= 5 && n / havuz.length > 0.3).map(([g]) => g));
const havuzG = new Set([...sayac.keys()].filter(g => !cerceve.has(g)));

// JS \b Türkçe harfte (ö, ş…) çalışmaz → Unicode harf sınırı
const ZAMAN = /(?<!\p{L})(sabah\p{L}*|öğle\p{L}*|ikindi\p{L}*|akşamüstü\p{L}*|akşam\p{L}*|gece\p{L}*)(?!\p{L})/giu;
const BELKI = /(?<!\p{L})belki(?!\p{L})/giu;
const ort = (arr, re) => arr.length ? arr.reduce((t, m) => t + (m.match(re) || []).length, 0) / arr.length : 0;
const havuzBelki = ort(havuz, BELKI), havuzZaman = ort(havuz, ZAMAN);
let ciddi = 0;
const satir = [];
for (const y of yeni) {
  const m = y.metin, b = [];
  if (/Tavsiyem/i.test(m)) b.push('"Tavsiyem" kalıbı');
  const zaman = (m.match(ZAMAN) || []).length;
  if (zaman >= Math.max(4, Math.ceil(havuzZaman * 2))) b.push(`saat zinciri (${zaman} zaman ifadesi)`);
  const belki = (m.match(BELKI) || []).length;
  if (belki >= Math.max(2, Math.ceil(havuzBelki * 2))) b.push(`"belki X, belki Y" (${belki})`);
  const ortak = [...gramlar(kelimeler(m))].filter(g => havuzG.has(g));
  if (ortak.length >= 3) b.push(`havuzla ${ortak.length} ortak 5-gram: ${ortak.slice(0, 2).join(' | ')}`);
  if (b.length) { satir.push(`  ${y.ad}: ${b.join(' · ')}`); if (b.some(x => /Tavsiyem|zinciri|havuzla/.test(x))) ciddi++; }
}
// Metinler arası
for (let i = 0; i < yeni.length; i++) for (let j = i + 1; j < yeni.length; j++) {
  const gi = gramlar(kelimeler(yeni[i].metin)), gj = gramlar(kelimeler(yeni[j].metin));
  const o = [...gi].filter(g => gj.has(g) && !cerceve.has(g));
  if (o.length >= 2) { satir.push(`  ${yeni[i].ad}~${yeni[j].ad}: ${o.length} ortak 5-gram (${o.slice(0, 2).join(' | ')})`); ciddi++; }
}
const harf = yeni.filter(y => /adında \{\{harf\}\}/.test(y.metin)).length;
if (harf > Math.max(2, Math.ceil(yeni.length / 10))) { satir.push(`  "adında {{harf}} harfi" ${harf} metinde (en fazla ${Math.max(2, Math.ceil(yeni.length / 10))})`); ciddi++; }
const acKey = m => kelimeler(m.replace(/^Merhaba[\s\S]*?öngörüm var\./, '')).slice(0, 2).join(' ');
const havuzAcilis = {};
havuz.forEach(m => { const k = acKey(m); havuzAcilis[k] = (havuzAcilis[k] || 0) + 1; });
const acilis = {};
yeni.forEach(y => { const k = acKey(y.metin); (acilis[k] = acilis[k] || []).push(y.ad); });
// Havuzda da yaygın olan açılış türün yapısıdır (ör. Faloya "Önümüzdeki … tarihinde") → kalıp sayılmaz
Object.entries(acilis).filter(([k, v]) => v.length > 2 && v.length / yeni.length > 1.5 * ((havuzAcilis[k] || 0) / Math.max(1, havuz.length))).forEach(([k, v]) => { satir.push(`  açılış "${k}…" ${v.length} kez: ${v.join(',')}`); ciddi++; });

console.log(`${yeni.length} metin tarandı · sabit çerçeve 5-gram: ${cerceve.size} · havuz ort. belki ${havuzBelki.toFixed(2)}, zaman ${havuzZaman.toFixed(2)} · ciddi bulgu: ${ciddi}`);
satir.forEach(s => console.log(s));
process.exitCode = ciddi ? 1 : 0;
