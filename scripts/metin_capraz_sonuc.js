// magnus-metin-uretimi (ChatGPT + Codex): iki yönlü seçimi temizleyip secimler.json'a yazar.
// Kullanım: node scripts/metin_capraz_sonuc.js <indirilen> <tur_klasoru> <tur> <id> "<ChatGPT'nin Codex metinlerinden seçtiği no'lar>"
// Codex'in ChatGPT metinlerinden seçimi: <tur_klasoru>/tur<N>_<id>_codex_secim.json (metin_codex.sh sec çıktısı).
// Havuz yolu meta dosyasından okunur. Önce Codex tarafı, sonra ChatGPT tarafı (Codex seçilenleriyle çakışma da ölçülür).
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const [inDir, dir, tur, id, gptSecti] = process.argv.slice(2);
const meta = JSON.parse(fs.readFileSync(path.join(dir, `tur${tur}_${id}_meta.json`), 'utf8'));
const havuz = `assets/data/${meta.file}:${meta.key}`;
const temizle = (cikti, sec, diger) => JSON.parse(execFileSync('node',
  ['scripts/metin_secim_temizle.js', cikti, sec, havuz].concat(diger ? [diger] : []), { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'] }));
const codexCikti = path.join(inDir, `tur${tur}_${id}_codex.json`);
const gptCikti = path.join(inDir, `tur${tur}_${id}_chatgpt.json`);
const codexSec = temizle(codexCikti, gptSecti, null);
const digerYol = path.join(dir, `diger_${id}.json`);
const cx = JSON.parse(fs.readFileSync(codexCikti, 'utf8'));
fs.writeFileSync(digerYol, JSON.stringify(cx.filter(x => codexSec.includes(x.no))));
const codexSectiGpt = JSON.parse(fs.readFileSync(path.join(dir, `tur${tur}_${id}_codex_secim.json`), 'utf8')).secilenler;
const gptSec = temizle(gptCikti, codexSectiGpt.join(','), digerYol);
const sf = path.join(dir, 'secimler.json');
const s = fs.existsSync(sf) ? JSON.parse(fs.readFileSync(sf, 'utf8')) : {};
s[id] = { chatgpt: gptSec, codex: codexSec, not: 'ChatGPT↔Codex çapraz; metin_secim_temizle ile çakışanlar değiştirildi' };
fs.writeFileSync(sf, JSON.stringify(s, null, 1));
console.log(id, 'chatgpt', gptSec.length, 'codex', codexSec.length);
