// merge_en.js — Unity .asset dosyalarindan aciklamaEng (Ingilizce) cikarip
// mevcut JSON'lara metin_en alani ekler. id eslesmesiyle.
//
// Kullanim: node scripts/merge_en.js <config_key>
// Config asagidaki MAPPINGS'te tanimli.

const fs = require('fs');
const path = require('path');

const ROOT = 'C:/src/magnus_app/.claude/worktrees/exciting-swanson-a016eb';
const DATA = ROOT + '/assets/data';

// ── YAML flow scalar (single/double quote) cozucu ──────────────────────────

function decodeDoubleEscapes(s) {
  let out = ''; let i = 0;
  while (i < s.length) {
    if (s[i] === '\\' && i + 1 < s.length) {
      const c = s[i + 1];
      if (c === 'u' && i + 6 <= s.length) { out += String.fromCharCode(parseInt(s.substring(i + 2, i + 6), 16)); i += 6; }
      else if (c === 'x' && i + 4 <= s.length) { out += String.fromCharCode(parseInt(s.substring(i + 2, i + 4), 16)); i += 4; }
      else if (c === 'n') { out += '\n'; i += 2; }
      else if (c === 't') { out += '\t'; i += 2; }
      else if (c === '"') { out += '"'; i += 2; }
      else if (c === '\\') { out += '\\'; i += 2; }
      else if (c === '0') { out += '\0'; i += 2; }
      else { out += s[i]; i++; }
    } else { out += s[i]; i++; }
  }
  return out;
}

// Coklu satirli scalar'i YAML folding kurallariyla birlestir.
// lines: ilk satir + devam satirlari (devam satirlari sol bosluklari kirpilmis,
// hepsi sag bosluklari kirpilmis). Bos satir = paragraf kirigi.
function foldLines(lines) {
  if (lines.length === 0) return '';
  let result = lines[0];
  let pendingBlanks = 0;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '') { pendingBlanks++; continue; }
    if (pendingBlanks === 0) result += ' ' + lines[i];
    else { result += '\n'.repeat(pendingBlanks) + lines[i]; pendingBlanks = 0; }
  }
  return result;
}

// raw: '- ' sonrasi tam scalar metni (coklu satir, orijinal newline + girinti ile)
function parseScalar(raw) {
  const t = raw.trimStart();
  if (t.length === 0) return '';
  const q = t[0];
  if (q === "'") {
    // tek tirnak: '' -> ' ; satir folding uygula
    // kapanis tirnagini bul ('' degil)
    let inner = '';
    let i = 1;
    while (i < t.length) {
      if (t[i] === "'") {
        if (t[i + 1] === "'") { inner += "'"; i += 2; continue; }
        break; // kapanis
      }
      inner += t[i]; i++;
    }
    const lines = inner.split('\n').map((l, idx) => idx === 0 ? l.replace(/\s+$/, '') : l.trim());
    return foldLines(lines);
  } else if (q === '"') {
    // cift tirnak: kacis sekanslari + folding
    let inner = '';
    let i = 1;
    while (i < t.length) {
      if (t[i] === '\\') { inner += t[i] + (t[i + 1] || ''); i += 2; continue; }
      if (t[i] === '"') break;
      inner += t[i]; i++;
    }
    // once satir folding (ham, kacis korunarak), sonra decode
    const lines = inner.split('\n').map((l, idx) => idx === 0 ? l.replace(/\s+$/, '') : l.trim());
    // cift tirnakta satir sonu '\' = devam (bosluk yok). Basitlik icin folding sonrasi decode.
    let folded = foldLines(lines);
    return decodeDoubleEscapes(folded);
  } else {
    // tirnaksiz plain scalar
    return foldLines(raw.split('\n').map((l, idx) => idx === 0 ? l.replace(/\s+$/, '') : l.trim()));
  }
}

// Bir .asset metninden belirli bir blok anahtarinin liste maddelerini cikar.
function extractListBlock(txt, key) {
  const marker = '\n  ' + key + ':';
  const start = txt.indexOf(marker);
  if (start === -1) return null;
  // blok govdesi marker sonrasindan baslar
  let bodyStart = start + marker.length;
  // ayni satirda "[]" varsa bos liste
  const restOfLine = txt.substring(bodyStart, txt.indexOf('\n', bodyStart));
  if (restOfLine.trim() === ' []' || restOfLine.trim() === '[]') return [];
  bodyStart = txt.indexOf('\n', bodyStart) + 1;
  // Bir sonraki ayni girintili anahtara (^  \S, 2 bosluk + bosluk-olmayan, '-' degil) kadar
  const lines = txt.substring(bodyStart).split('\n');
  const blockLines = [];
  for (const line of lines) {
    // Yeni anahtar: tam 2 bosluk + harf (devam/madde degil)
    if (/^  [A-Za-z_]/.test(line)) break;
    blockLines.push(line);
  }
  // Maddeleri ('  - ') ayir
  const items = [];
  let current = null;
  for (const line of blockLines) {
    if (/^  - /.test(line)) {
      if (current !== null) items.push(current);
      current = line.substring(4); // '  - ' sonrasi
    } else if (current !== null) {
      current += '\n' + line;
    }
  }
  if (current !== null) items.push(current);
  return items.map(parseScalar)
    .map(s => s.replace(/<sprite=\d+>/g, '').trim())
    .filter(s => s.length > 0);
}

// Bir asset'ten TR+EN parali listelerini cikar.
function readPairsFromAsset(fp) {
  if (!fs.existsSync(fp)) return [];
  const txt = fs.readFileSync(fp, 'utf8');
  const tr = extractListBlock(txt, 'aciklama') || [];
  const en = extractListBlock(txt, 'aciklamaEng') || [];
  const pairs = [];
  for (let i = 0; i < tr.length; i++) {
    pairs.push({ tr: tr[i], en: en[i] || '' });
  }
  return pairs;
}

// Eslestime anahtari: TAM metin normalize (cakisma yok → yanlis eslesme yok).
function normKey(s) {
  return (s || '')
    .replace(/\{\{[^}]+\}\}/g, '')      // placeholder'lari at (TR/EN farkli olabilir)
    .replace(/<[^>]+>/g, '')            // tag'lari at
    .replace(/[^0-9A-Za-zĞğÜüŞşİıÖöÇç]/g, '') // sadece harf+rakam
    .toLowerCase();
}

// Klasor(ler)deki TUM asset'lerden TR->EN haritasi olustur.
function buildTrToEnMap(folders) {
  const list = Array.isArray(folders) ? folders : [folders];
  const map = new Map();
  for (const folder of list) {
    if (!fs.existsSync(folder)) { console.log('UYARI klasor yok:', folder); continue; }
    const files = fs.readdirSync(folder).filter(f => f.endsWith('.asset'));
    for (const f of files) {
      const pairs = readPairsFromAsset(folder + '/' + f);
      for (const p of pairs) {
        if (!p.tr) continue;
        const k = normKey(p.tr);
        if (k.length > 4 && p.en && p.en.length > 1) {
          if (!map.has(k)) map.set(k, p.en);
        }
      }
    }
  }
  return map;
}

// ── Mappings: hangi JSON, hangi kaynak klasor, hangi dizi anahtari ──────────

const ODB = 'C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR';
const MAPPINGS = {
  motivasyonlar: { json: 'motivasyonlar.json', arrayKey: 'motivasyonlar', folder: ODB + '/AnaMenu2/Motivasyon/Motivasyonlar' },
  olumlamalar:   { json: 'olumlamalar.json',   arrayKey: 'olumlamalar',   folder: ODB + '/AnaMenu2/Olumlama/Olumlamalar' },
  ozlusozler:    { json: 'ozlusozler.json',    arrayKey: 'ozlusozler',    folder: ODB + '/AnaMenu2/Ozlusoz/OzluSozler' },
  japonfali:     { json: 'japonfali.json',     arrayKey: 'japonfali',     folder: ODB + '/AnaMenu2/JaponFali/Metinler' },
  iching:        { json: 'iching.json',        arrayKey: 'iching',        folder: ODB + '/AnaMenu2/IChing/Metinler' },
  kaderkitabi:   { json: 'kaderkitabi.json',   arrayKey: 'kaderkitabi',   folder: ODB + '/AnaMenu2/KaderKitabı/Tefeul' },
  acigercekler:  { json: 'acigercekler.json',  arrayKey: 'acigercekler',  folders: [ODB + '/AnaMenu3/AciGercekler/AciGecrekler', ODB + '/AnaMenu3/AciGercekler/AciGercekCikis'] },
};

function main() {
  const key = process.argv[2];
  if (!key || !MAPPINGS[key]) {
    console.log('Kullanim: node scripts/merge_en.js <key>');
    console.log('Mevcut:', Object.keys(MAPPINGS).join(', '));
    process.exit(1);
  }
  const cfg = MAPPINGS[key];
  const jsonPath = DATA + '/' + cfg.json;
  const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  const arr = data[cfg.arrayKey];
  if (!Array.isArray(arr)) { console.log('Dizi bulunamadi:', cfg.arrayKey); process.exit(1); }

  const map = buildTrToEnMap(cfg.folders || cfg.folder);
  console.log('Kaynak TR->EN harita boyutu:', map.size);

  let matched = 0, missing = 0;
  const missingIds = [];
  for (const entry of arr) {
    const k = normKey(entry.metin);
    const en = map.get(k);
    if (en && en.length > 1) {
      entry.metin_en = en;
      matched++;
    } else {
      entry.metin_en = entry.metin; // fallback TR
      missing++;
      missingIds.push(entry.id);
    }
  }

  fs.writeFileSync(jsonPath, JSON.stringify(data, null, 2), 'utf8');
  console.log(`${cfg.json}: ${arr.length} girdi | EN eslesen: ${matched} | eksik(TR fallback): ${missing}`);
  if (missingIds.length > 0 && missingIds.length <= 40) console.log('Eksik id:', missingIds.join(','));
}

main();
