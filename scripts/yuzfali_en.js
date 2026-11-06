#!/usr/bin/env node
// Yüz falı JSON'larına metin_en ekler (yerinde satır ekleme → CRLF + girinti korunur).
// Gemini ile çeviri; yer tutucu ({{...}}) parite doğrulaması; uymazsa o öğeyi atlar (TR fallback).
'use strict';
const fs = require('fs');
const { call } = require('./gemini_helper.js');

const file = process.argv[2];
if (!file) { console.error('kullanım: node yuzfali_en.js <dosya.json>'); process.exit(1); }

const raw = fs.readFileSync(file, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const lines = raw.split(/\r?\n/);

// metin satırlarını topla
const metinRe = /^(\s*)"metin":\s*"((?:[^"\\]|\\.)*)"(,?)\s*$/;
const items = []; // {lineIdx, indent, rawVal, comma, decoded, hasEn}
for (let i = 0; i < lines.length; i++) {
  const m = lines[i].match(metinRe);
  if (!m) continue;
  // zaten metin_en var mı? (bir sonraki satır)
  const next = lines[i + 1] || '';
  if (/^\s*"metin_en":/.test(next)) continue;
  let decoded;
  try { decoded = JSON.parse('"' + m[2] + '"'); } catch (e) { console.error('decode hata satır', i + 1); continue; }
  items.push({ lineIdx: i, indent: m[1], comma: m[3], decoded });
}
console.log(file, '→ çevrilecek metin:', items.length);
if (!items.length) { console.log('iş yok'); process.exit(0); }

function phSet(s) {
  const r = (s.match(/\{\{[^}]*\}\}/g) || []).slice().sort();
  return r.join('||');
}
function tagSet(s) {
  const r = (s.match(/<[^>]+>/g) || []).slice().sort();
  return r.join('||');
}

async function translateBatch(arr) {
  // arr: list of turkish strings; returns list of english (same length) or null
  const numbered = arr.map((t, i) => `${i + 1}. ${t}`).join('\n');
  const prompt =
`You are a professional Turkish→English translator for a mystical fortune-telling app ("Magnus"). Translate each numbered Turkish line into natural, fluent English with the SAME mystical, warm, second-person tone.
STRICT RULES:
- Preserve EVERY placeholder token like {{isim}}, {{sayi,1,6}}, {{ay_2}} EXACTLY as written, same count, do not translate or alter inside {{ }}.
- Preserve any markup tags EXACTLY: <color=...>, </color>, <b>, </b>, <i>, </i>.
- Keep it concise, same register. No added notes, no quotes around items.
- Return ONLY a valid JSON array of ${arr.length} strings, in the same order. No markdown, no code fences.

Lines:
${numbered}`;
  let out;
  try { out = await call(prompt, Math.min(16000, 1600 + arr.length * 500)); }
  catch (e) { console.error('  gemini hata:', e.message); return null; }
  // JSON diziyi ayıkla
  let s = out.trim().replace(/^```(?:json)?/i, '').replace(/```$/,'').trim();
  const a = s.indexOf('['); const b = s.lastIndexOf(']');
  if (a < 0 || b < 0) { console.error('  dizi yok, çıktı başı:', JSON.stringify(out.slice(0, 200))); return null; }
  let parsed;
  try { parsed = JSON.parse(s.slice(a, b + 1)); } catch (e) { console.error('  parse hata, çıktı başı:', JSON.stringify(out.slice(0, 200))); return null; }
  if (!Array.isArray(parsed) || parsed.length !== arr.length) { console.error('  uzunluk uyuşmazlık', parsed && parsed.length); return null; }
  return parsed.map(String);
}

(async () => {
  const BATCH = 10;
  const results = new Array(items.length).fill(null);
  for (let start = 0; start < items.length; start += BATCH) {
    const slice = items.slice(start, start + BATCH);
    let en = await translateBatch(slice.map((x) => x.decoded));
    if (!en) {
      // yarıya böl, tekrar dene
      const half = Math.ceil(slice.length / 2);
      const p1 = await translateBatch(slice.slice(0, half).map((x) => x.decoded));
      const p2 = await translateBatch(slice.slice(half).map((x) => x.decoded));
      if (p1 && p2) en = p1.concat(p2);
    }
    if (!en) { console.error('  batch', start, 'başarısız — TR fallback'); continue; }
    for (let k = 0; k < slice.length; k++) {
      const tr = slice[k].decoded, et = en[k];
      if (phSet(tr) !== phSet(et)) { console.error('  yer tutucu uyuşmaz, atlandı:', JSON.stringify(tr.slice(0, 50))); continue; }
      if (tagSet(tr) !== tagSet(et)) { console.error('  tag uyuşmaz, atlandı:', JSON.stringify(tr.slice(0, 50))); continue; }
      results[start + k] = et;
    }
    process.stderr.write(`  ${Math.min(start + BATCH, items.length)}/${items.length}\n`);
  }

  // satırlara yerinde ekle (ters sırada → indeks kaymasın)
  let added = 0;
  for (let idx = items.length - 1; idx >= 0; idx--) {
    const en = results[idx];
    if (en == null) continue;
    const it = items[idx];
    const enc = JSON.stringify(en); // tırnaklı, kaçışlı
    const metinLine = lines[it.lineIdx];
    // metin satırı virgülsüzse (son özellik) → virgül ekle; metin_en virgülsüz olur
    let newMetin, newEn;
    if (it.comma === ',') {
      newMetin = metinLine;
      newEn = `${it.indent}"metin_en": ${enc},`;
    } else {
      newMetin = metinLine.replace(/\s*$/, '') + ',';
      newEn = `${it.indent}"metin_en": ${enc}`;
    }
    lines.splice(it.lineIdx, 1, newMetin, newEn);
    added++;
  }
  fs.writeFileSync(file, lines.join(eol), 'utf8');
  // doğrula
  try { JSON.parse(fs.readFileSync(file, 'utf8')); console.log('JSON geçerli. eklenen metin_en:', added, '/', items.length); }
  catch (e) { console.error('!!! JSON BOZULDU:', e.message); process.exit(1); }
})();
