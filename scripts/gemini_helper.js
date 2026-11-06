#!/usr/bin/env node
// Gemini REST yardımcısı — anahtarı içeride okur (echo yok), yer tutucuları korur.
// Kullanım:
//   node gemini_helper.js test
//   node gemini_helper.js call <promptFile> <outFile>        (tek istem → metin)
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');

function readKey() {
  if (process.env.GEMINI_API_KEY && /^AIza/.test(process.env.GEMINI_API_KEY)) {
    return process.env.GEMINI_API_KEY.trim();
  }
  const p = path.join(os.homedir(), '.gemini', 'settings.json');
  try {
    const t = fs.readFileSync(p, 'utf8');
    try {
      const j = JSON.parse(t);
      const cand = j.apiKey || j.geminiApiKey ||
        (j.security && j.security.auth && j.security.auth.apiKey) || '';
      if (cand && /^AIza/.test(cand)) return cand.trim();
    } catch (_) {}
    const m = t.match(/AIza[0-9A-Za-z_\-]{20,}/);
    if (m) return m[0];
  } catch (_) {}
  throw new Error('Gemini anahtarı bulunamadı (env GEMINI_API_KEY ya da ~/.gemini/settings.json)');
}

const KEY = readKey();
const MODELS = ['gemini-3.5-flash', 'gemini-3.8-flash', 'gemini-3.1-pro-preview'];

function once(model, text, maxTok) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      contents: [{ parts: [{ text }] }],
      generationConfig: { maxOutputTokens: maxTok, temperature: 1.0 },
    });
    const req = https.request({
      hostname: 'generativelanguage.googleapis.com',
      path: `/v1beta/models/${model}:generateContent?key=${KEY}`,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
      timeout: 120000,
    }, (res) => {
      let d = '';
      res.on('data', (c) => (d += c));
      res.on('end', () => {
        try {
          const j = JSON.parse(d);
          if (j.error) return reject(new Error(`${res.statusCode} ${j.error.message || ''}`));
          const t = j.candidates && j.candidates[0] && j.candidates[0].content &&
            j.candidates[0].content.parts && j.candidates[0].content.parts.map((p) => p.text || '').join('');
          if (!t || !t.trim()) return reject(new Error('boş yanıt (finishReason=' + (j.candidates && j.candidates[0] && j.candidates[0].finishReason) + ')'));
          resolve(t);
        } catch (e) {
          reject(new Error('parse: ' + d.slice(0, 200)));
        }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(new Error('timeout')); });
    req.write(body);
    req.end();
  });
}

async function call(text, maxTok = 2400) {
  let lastErr;
  for (const m of MODELS) {
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        return await once(m, text, maxTok);
      } catch (e) {
        lastErr = e;
        const msg = String(e.message || '');
        // 429/503 → sıradaki modele; kısa bekleme
        if (/\b(429|503|500|overloaded|timeout|UNAVAILABLE|RESOURCE_EXHAUSTED)\b/i.test(msg)) {
          await new Promise((r) => setTimeout(r, 1500 * (attempt + 1)));
          continue;
        }
        break; // başka hata → modeli değiştir
      }
    }
  }
  throw lastErr;
}

module.exports = { call };

if (require.main === module) {
  (async () => {
    const mode = process.argv[2];
    if (mode === 'test') {
      const out = await call('Translate to natural English, keep {{isim}} verbatim, reply with only the translation: "Yüzünle ilgili detaylı değerlendirmem şöyle {{isim}};"', 400);
      console.log('OK:', out.trim());
    } else if (mode === 'call') {
      const prompt = fs.readFileSync(process.argv[3], 'utf8');
      const maxTok = Number(process.argv[5] || 4000);
      const out = await call(prompt, maxTok);
      fs.writeFileSync(process.argv[4], out, 'utf8');
      console.log('yazıldı:', process.argv[4], out.length, 'char');
    } else {
      console.log('kullanım: test | call <promptFile> <outFile> [maxTok]');
    }
  })().catch((e) => { console.error('HATA:', e.message); process.exit(1); });
}
