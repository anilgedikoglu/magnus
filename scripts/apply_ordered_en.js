// apply_ordered_en.js — Bir JSON'daki belirli bir alt-ağacın metin alanlarına,
// SIRALI bir İngilizce dizisinden metin_en atar. Dump ve apply AYNI gezinme
// sırasını kullanır (Object.keys insertion order + array index).
//
// Komutlar:
//   node scripts/apply_ordered_en.js dump <file.json> <dotPath>
//       → numaralı TR listesi yazdirir
//   node scripts/apply_ordered_en.js apply <file.json> <dotPath> <en.json>
//       → en.json (string dizisi) sirayla metin_en olarak atar

const fs = require('fs');
const ROOT = 'C:/src/magnus_app/.claude/worktrees/exciting-swanson-a016eb';
const DATA = ROOT + '/assets/data';

function resolvePath(obj, dotPath) {
  if (!dotPath) return obj;
  let cur = obj;
  for (const k of dotPath.split('.')) cur = cur[k];
  return cur;
}

// Bir alt-agacin tum metin alanli objelerini SIRALI topla (insertion order).
function collect(node, out) {
  if (Array.isArray(node)) { for (const x of node) collect(x, out); return; }
  if (node && typeof node === 'object') {
    if (typeof node.metin === 'string') out.push(node);
    for (const k of Object.keys(node)) {
      if (k === 'metin' || k === 'metin_en') continue;
      collect(node[k], out);
    }
  }
}

function main() {
  const [cmd, file, dotPath, enFile] = process.argv.slice(2);
  const path = DATA + '/' + file;
  const data = JSON.parse(fs.readFileSync(path, 'utf8'));
  const sub = resolvePath(data, dotPath);
  const nodes = [];
  collect(sub, nodes);

  if (cmd === 'dump') {
    nodes.forEach((n, i) => {
      console.log(`#${i} ${n.metin.replace(/\n+/g, ' ⏎ ')}`);
    });
    console.log(`\nTOPLAM: ${nodes.length}`);
    return;
  }

  if (cmd === 'apply') {
    const en = JSON.parse(fs.readFileSync(enFile.startsWith('C:') ? enFile : (ROOT + '/scripts/' + enFile), 'utf8'));
    if (en.length !== nodes.length) {
      console.error(`HATA: EN sayisi (${en.length}) != node sayisi (${nodes.length})`);
      process.exit(1);
    }
    let assigned = 0;
    nodes.forEach((n, i) => {
      if (en[i] && en[i].trim().length > 0) { n.metin_en = en[i]; assigned++; }
      else n.metin_en = n.metin;
    });
    fs.writeFileSync(path, JSON.stringify(data, null, 2), 'utf8');
    console.log(`${file} [${dotPath}]: ${nodes.length} node | atanan EN: ${assigned}`);
    return;
  }

  console.error('Komut: dump | apply');
  process.exit(1);
}
main();
