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

// Bir klasordeki tum .asset dosyalarini (opsiyonel recursive) topla.
function listAssets(folder, recursive) {
  const out = [];
  if (!fs.existsSync(folder)) return out;
  for (const e of fs.readdirSync(folder, { withFileTypes: true })) {
    const fp = folder + '/' + e.name;
    if (e.isDirectory()) { if (recursive) out.push(...listAssets(fp, true)); }
    else if (e.name.endsWith('.asset')) out.push(fp);
  }
  return out;
}

// Klasor(ler)deki TUM asset'lerden TR->EN haritasi olustur.
function buildTrToEnMap(folders, recursive) {
  const list = Array.isArray(folders) ? folders : [folders];
  const map = new Map();
  for (const folder of list) {
    if (!fs.existsSync(folder)) { console.log('UYARI klasor yok:', folder); continue; }
    for (const fp of listAssets(folder, recursive)) {
      const pairs = readPairsFromAsset(fp);
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
  karsilamalar:  { json: 'karsilamalar.json',  arrayKeys: ['karsilamalar', 'biliyormuydun', 'ozel_gunler'], singleKeys: ['ilk_giris'], folder: ODB + '/OzelSohbetler/Karsilamalar', recursive: true },
  biyoritim:     { json: 'biyoritim.json',      arrayKeys: ['b1','b2a','b2b','b2c','b3a','b3b','b4','b5'], folder: ODB + '/AnaMenu2/Biyoritim', recursive: true },
  gunlukastroloji: { json: 'gunlukastroloji.json', arrayKeys: ['giris','astroyorum','astrogununsozu','astrogununayeti','astrogununhadisi','astroeglencelibilgi','astrokesif','astrogununismi','astrogununyemegi','astroveda'], folder: ODB + '/AnaMenu2/GunlukAstroloji', recursive: true },
  yana:          { json: 'yana.json',           arrayKeys: ['bana_dair','yasama_dair'], folder: ODB + '/AnaMenu1/Kehanet/Yana', recursive: true },
  durugoru_bno:  { json: 'durugoru_bno.json',   arrayKey: 'durugoru_bno', folder: ODB + '/AnaMenu1/Kehanet/Durugoru', recursive: true },
  durugoru_gno:  { json: 'durugoru_gno.json',   arrayKey: 'durugoru_gno', folder: ODB + '/AnaMenu1/Kehanet/Durugoru', recursive: true },
  durugoru_yno:  { json: 'durugoru_yno.json',   arrayKey: 'durugoru_yno', folder: ODB + '/AnaMenu1/Kehanet/Durugoru', recursive: true },
  kahve_giris:      { json: 'kahve_giris.json',      arrayKey: 'girisler',     folder: ODB + '/AnaMenu1/KahveFali', recursive: true },
  kahve_akarsilama: { json: 'kahve_akarsilama.json', arrayKey: 'karsilamalar', folder: ODB + '/AnaMenu1/KahveFali', recursive: true },
  kahve_baglama:    { json: 'kahve_baglama.json',    arrayKey: 'baglamalar',   folder: ODB + '/AnaMenu1/KahveFali', recursive: true },
  kahve_gelisme:    { json: 'kahve_gelisme.json',    arrayKey: 'gelismeler',   folder: ODB + '/AnaMenu1/KahveFali', recursive: true },
  kahve_sonuc:      { json: 'kahve_sonuc.json',      arrayKey: 'sonuclar',     folder: ODB + '/AnaMenu1/KahveFali', recursive: true },
  kahve_ugurlama:   { json: 'kahve_ugurlama.json',   arrayKey: 'ugurlamalar',  folder: ODB + '/AnaMenu1/KahveFali', recursive: true },
  astrotakvim:   { json: 'astrotakvim.json',    arrayKeys: ['transit_tarihli','transit','aktivite','saglik','guzellik','maneviyat'], folder: ODB + '/AnaMenu2/AstroTakvim', recursive: true },
  faloya:        { json: 'faloya.json',         arrayKey: 'faloya',  folder: ODB + '/AnaMenu1/Kehanet/Faloya', recursive: true },
  maganda:       { json: 'maganda.json',        arrayKey: 'sorular', folder: ODB + '/AnaMenu1/Kehanet/Maganda', recursive: true },
  niyet:         { json: 'niyet.json',          arrayKey: 'niyet',   folder: ODB + '/AnaMenu1/Niyet', recursive: true },
  kadercarki_alev:   { json: 'kadercarki_alev.json',   arrayKey: 'kadercarki_alev',   folder: ODB + '/AnaMenu1/KaderCarki', recursive: true },
  kadercarki_zar:    { json: 'kadercarki_zar.json',    arrayKey: 'kadercarki_zar',    folder: ODB + '/AnaMenu1/KaderCarki', recursive: true },
  kadercarki_renk:   { json: 'kadercarki_renk.json',   arrayKey: 'kadercarki_renk',   folder: ODB + '/AnaMenu1/KaderCarki', recursive: true },
  kadercarki_tas:    { json: 'kadercarki_tas.json',    arrayKey: 'kadercarki_tas',    folder: ODB + '/AnaMenu1/KaderCarki', recursive: true },
  kadercarki_kure:   { json: 'kadercarki_kure.json',   arrayKey: 'kadercarki_kure',   folder: ODB + '/AnaMenu1/KaderCarki', recursive: true },
  kadercarki_hayvan: { json: 'kadercarki_hayvan.json', arrayKey: 'kadercarki_hayvan', folder: ODB + '/AnaMenu1/KaderCarki', recursive: true },
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

  const map = buildTrToEnMap(cfg.folders || cfg.folder, cfg.recursive);
  console.log('Kaynak TR->EN harita boyutu:', map.size);

  const arrayKeys = cfg.arrayKeys || [cfg.arrayKey];
  const metinField = cfg.metinField || 'metin';
  let totalMatched = 0, totalMissing = 0, totalCount = 0;

  for (const ak of arrayKeys) {
    const arr = data[ak];
    if (!Array.isArray(arr)) { console.log('  Dizi yok, atlandi:', ak); continue; }
    let matched = 0, missing = 0;
    for (const entry of arr) {
      const tr = entry[metinField];
      if (typeof tr !== 'string') continue;
      const en = map.get(normKey(tr));
      if (en && en.length > 1) { entry[metinField + '_en'] = en; matched++; }
      else { entry[metinField + '_en'] = tr; missing++; }
    }
    console.log(`  [${ak}] ${arr.length} | EN: ${matched} | eksik: ${missing}`);
    totalMatched += matched; totalMissing += missing; totalCount += arr.length;
  }

  // Tek string alanlar (orn. ilk_giris)
  if (cfg.singleKeys) {
    for (const sk of cfg.singleKeys) {
      if (typeof data[sk] === 'string') {
        const en = map.get(normKey(data[sk]));
        data[sk + '_en'] = en && en.length > 1 ? en : data[sk];
      }
    }
  }

  fs.writeFileSync(jsonPath, JSON.stringify(data, null, 2), 'utf8');
  console.log(`${cfg.json}: toplam ${totalCount} | EN eslesen: ${totalMatched} | eksik(TR fallback): ${totalMissing}`);
}

main();
