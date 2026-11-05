// Panodaki model çıktısını (JSON dizi) doğrulayıp indirilen klasörüne yazar. Bozuk JSON'da (kaçışsız tırnak)
// satır bazlı toleranslı ayrıştırma yapar. Kullanım: node pano_kaydet.js <ad.json> <beklenen_adet>
const fs = require('fs');
const { execSync } = require('child_process');
const [ad, beklenen] = process.argv.slice(2);
const raw = execSync('powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-Clipboard -Raw"', { encoding: 'utf8', maxBuffer: 20e6 });
const c = raw.slice(raw.indexOf('['), raw.lastIndexOf(']') + 1);
let a;
try { a = JSON.parse(c); } catch (e) {
  const re = /"no"\s*:\s*(\d+)\s*,\s*"kitle"\s*:\s*"([^"]*)"\s*,\s*"metin"\s*:\s*"([\s\S]*?)"\s*\}\s*(?=,\s*\{|\s*\])/g;
  let m; a = [];
  while ((m = re.exec(c))) a.push({ no: +m[1], kitle: m[2], metin: m[3].replace(/\\n/g, '\n').replace(/\\"/g, '"') });
  console.log('toleranslı ayrıştırma');
}
a = a.map(x => ({ no: x.no, kitle: x.kitle, metin: x.metin }));
fs.writeFileSync('C:/Users/AG/Desktop/indirilen/' + ad, JSON.stringify(a, null, 1));
console.log(ad, a.length, beklenen && a.length !== +beklenen ? 'UYARI beklenen ' + beklenen : 'tamam');
