// magnus-metin-uretimi: aday dosyalarından İngilizce çeviri brief'i üretir / gelen çeviriyi _en.json'lara böler.
// node scripts/metin_ceviri_hazirla.js brief <tur_klasoru> <cikti.txt> <id1> [id2 …]
// node scripts/metin_ceviri_hazirla.js bol   <tur_klasoru> <gelen.json> <id1> [id2 …]
const fs = require('fs');
const path = require('path');
const [mode, dir, file, ...ids] = process.argv.slice(2);
if (mode === 'brief') {
  let s = 'ÇEVİRİ GÖREVİ — Türkçe fal metinlerini doğal, akıcı İngilizceye çevir.\n\n';
  s += 'KURALLAR:\n- Ton ve üslup aynı kalsın: anlatıcı Magnus birinci tekil konuşur, okura "you" diye hitap eder; sıcak, gizemli, kendinden emin.\n';
  s += '- {{…}} yer tutucularını AYNEN, hiç değiştirmeden ve aynı sayıda koru (ör. {{isim}}, {{harf}}, {{ay_2}}, {{gun_3}}, {{sayi,2,6}}, {{kelime, A | B}} — kelime seçeneklerini de İngilizceye çevir ama süslü parantez yapısını koru).\n';
  s += '- "Magnuskop" → "MagnusScope". Türkçeye özgü kavramları doğal İngilizce karşılığıyla ver (ör. "ince belli çay bardağı" → "tulip-shaped tea glass").\n';
  s += '- Satır sonlarını (\\n) koru. Anlam ekleme/çıkarma yapma.\n\n';
  s += 'ÇIKTI: Yalnızca tek kod bloğunda JSON dizisi: [{"k":"<anahtar>","en":"…"}, …] — her girdi için aynı "k".\n\nMETİNLER:\n';
  for (const id of ids) {
    const a = JSON.parse(fs.readFileSync(path.join(dir, `${id}_aday.json`), 'utf8'));
    a.forEach((e, i) => { s += `\n[k=${id}#${i}]\n${e.metin}\n`; });
  }
  fs.writeFileSync(file, s);
  console.log('brief', s.length);
} else if (mode === 'bol') {
  const arr = JSON.parse(fs.readFileSync(file, 'utf8'));
  const map = Object.fromEntries(arr.map(x => [x.k, x.en]));
  for (const id of ids) {
    const a = JSON.parse(fs.readFileSync(path.join(dir, `${id}_aday.json`), 'utf8'));
    const en = a.map((_, i) => map[`${id}#${i}`]);
    const miss = en.filter(x => !x).length;
    fs.writeFileSync(path.join(dir, `${id}_en.json`), JSON.stringify(en, null, 1));
    console.log(id, 'en', en.length, 'eksik', miss);
  }
}
