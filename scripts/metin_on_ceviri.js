// magnus-metin-uretimi: ÖN ÇEVİRİ — bir modelin çıktısının TAMAMINI çapraz seçimden önce çevirtir (Codex beklerken
// ChatGPT boş kalmasın; seçim gelince yalnız eşleme yapılır). Anahtar: <id>#<model>#<no>.
//   node scripts/metin_on_ceviri.js brief  <indirilen> <tur> <id> <model> <cikti.txt>
//   node scripts/metin_on_ceviri.js uygula <tur_klasoru> <id> <gelen.json> [gelen2.json …]
//        → <tur_klasoru>/<id>_en.json (aday sırasıyla; eksik olanları listeler — onları normal `brief/bol` ile çevir)
const fs = require('fs');
const path = require('path');
const [mode, ...rest] = process.argv.slice(2);
if (mode === 'brief') {
  const [inDir, tur, id, model, out] = rest;
  const a = JSON.parse(fs.readFileSync(path.join(inDir, `tur${tur}_${id}_${model}.json`), 'utf8'));
  let s = 'ÇEVİRİ GÖREVİ — Türkçe fal metinlerini doğal, akıcı İngilizceye çevir.\n\n';
  s += 'KURALLAR:\n- Ton ve üslup aynı kalsın: anlatıcı Magnus birinci tekil konuşur, okura "you" diye hitap eder; sıcak, gizemli, kendinden emin.\n';
  s += '- {{…}} yer tutucularını AYNEN, hiç değiştirmeden ve aynı sayıda koru (ör. {{isim}}, {{harf}}, {{ay_2}}, {{gun_3}}, {{sayi,2,6}}, {{kelime, A | B}} — kelime seçeneklerini de İngilizceye çevir ama süslü parantez yapısını koru).\n';
  s += '- "Magnuskop" → "MagnusScope". Türkçeye özgü kavramları doğal İngilizce karşılığıyla ver (ör. "ince belli çay bardağı" → "tulip-shaped tea glass").\n';
  s += '- <color=…>, <b>, </b> gibi etiketleri ve "||" ayırıcısını aynen koru. Satır sonlarını (\\n) koru. Anlam ekleme/çıkarma yapma.\n\n';
  s += 'ÇIKTI: Yalnızca tek kod bloğunda JSON dizisi: [{"k":"<anahtar>","en":"…"}, …] — her girdi için aynı "k".\n\nMETİNLER:\n';
  a.forEach(e => { s += `\n[k=${id}#${model}#${e.no}]\n${e.metin}\n`; });
  fs.writeFileSync(out, s);
  console.log('brief', a.length, s.length);
} else if (mode === 'uygula') {
  const [dir, id, ...files] = rest;
  const map = {};
  for (const f of files) for (const x of JSON.parse(fs.readFileSync(f, 'utf8'))) map[x.k] = x.en;
  const aday = JSON.parse(fs.readFileSync(path.join(dir, `${id}_aday.json`), 'utf8'));
  const en = aday.map(e => map[`${id}#${e.kaynak}#${e.no}`] || null);
  fs.writeFileSync(path.join(dir, `${id}_en.json`), JSON.stringify(en, null, 1));
  const eksik = en.map((x, i) => (x ? null : `${aday[i].kaynak}#${aday[i].no}`)).filter(Boolean);
  console.log(id, 'en', en.length, 'eksik', eksik.join(',') || 'yok');
}
