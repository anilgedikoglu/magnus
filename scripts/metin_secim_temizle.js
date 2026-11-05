// magnus-metin-uretimi: karşı modelin seçtiği metinlerde birbirine çok benzeyenleri (ortak 5-gram) ve tekrarlanan
// açılışları ayıklar; yerlerine aynı modelin SEÇİLMEMİŞ metinlerinden çakışmasız olanı koyar (sırayla, kitle çeşitliliği
// gözetilerek). Ayrıca mevcut havuzla ortak 5-gramı yüksek olanı da değiştirir.
// Kullanım: node scripts/metin_secim_temizle.js <model_cikti.json> "<no,no,…>" <havuz.json:anahtar> [diger_secim.json]
//   diger_secim.json: aynı bölmede diğer modelin seçilen metinleri (onlarla da çakışma ölçülür) — [{metin}] dizisi
// Çıktı: temizlenmiş no listesi (JSON) + açıklama satırları.
const fs = require('fs');
const getPath = (o, p) => p.split('.').reduce((a, k) => (a == null ? a : a[k]), o);
const [cikti, secStr, havuzArg, digerArg] = process.argv.slice(2);
const tum = JSON.parse(fs.readFileSync(cikti, 'utf8'));
let sec = secStr.split(',').map(Number);
const [hf, hk] = havuzArg.split(':');
const havuz = getPath(JSON.parse(fs.readFileSync(hf, 'utf8')), hk).map(e => e.metin);
const diger = digerArg ? JSON.parse(fs.readFileSync(digerArg, 'utf8')).map(e => e.metin) : [];

const kel = s => s.replace(/^Merhaba[\s\S]*?öngörüm var\./, '').toLocaleLowerCase('tr').replace(/\{\{[^}]*\}\}/g, ' ').replace(/[^a-zçğıöşüâîû0-9 ]/g, ' ').split(/\s+/).filter(Boolean);
const gr = s => { const w = kel(s), g = new Set(); for (let i = 0; i + 5 <= w.length; i++) g.add(w.slice(i, i + 5).join(' ')); return g; };
const ac = s => kel(s).slice(0, 2).join(' ');
// Havuzun sabit çerçevesi (Faloya gibi) yok sayılır
const say = new Map();
havuz.forEach(m => gr(m).forEach(g => say.set(g, (say.get(g) || 0) + 1)));
const cerceve = new Set([...say].filter(([, n]) => havuz.length >= 5 && n / havuz.length > 0.3).map(([g]) => g));
const havuzG = new Set([...say.keys()].filter(g => !cerceve.has(g)));
const G = new Map(tum.map(t => [t.no, gr(t.metin)]));
const digerG = diger.map(gr);
const ortak = (a, b) => [...a].filter(g => b.has(g) && !cerceve.has(g)).length;
const havuzOrtak = no => [...G.get(no)].filter(g => havuzG.has(g)).length;

function sorunlu(liste) {
  for (let i = 0; i < liste.length; i++) {
    const a = liste[i];
    if (havuzOrtak(a) >= 3) return { no: a, neden: 'havuzla ' + havuzOrtak(a) + ' ortak' };
    for (const dg of digerG) if (ortak(G.get(a), dg) >= 2) return { no: a, neden: 'diğer modelin seçimiyle ortak' };
    for (let j = 0; j < i; j++) {
      const n = ortak(G.get(a), G.get(liste[j]));
      if (n >= 2) return { no: a, neden: `#${liste[j]} ile ${n} ortak 5-gram` };
    }
    const acs = liste.slice(0, i).filter(b => ac(tum.find(t => t.no === b).metin) === ac(tum.find(t => t.no === a).metin)).length;
    if (acs >= 2) return { no: a, neden: 'açılış 3. kez' };
  }
  return null;
}
const yedek = tum.map(t => t.no).filter(n => !sec.includes(n));
let s;
const notlar = [];
while ((s = sorunlu(sec))) {
  const kalan = sec.filter(n => n !== s.no);
  const aday = yedek.find(n => !sorunlu(kalan.concat(n)) || sorunlu(kalan.concat(n)).no !== n);
  if (aday === undefined) { notlar.push(`#${s.no} çıkarıldı (${s.neden}), çakışmasız yedek yok`); sec = kalan; continue; }
  yedek.splice(yedek.indexOf(aday), 1);
  notlar.push(`#${s.no} → #${aday} (${s.neden})`);
  sec = kalan.concat(aday);
}
notlar.forEach(n => console.error(n));
console.log(JSON.stringify(sec.sort((a, b) => a - b)));
