// magnus-metin-uretimi: çapraz seçim dosyaları. Bir modelin N metnini diğerine "en iyi N/2'yi seç" diye verir.
// Kullanım: node scripts/metin_capraz_hazirla.js <indirilen_klasörü> <çıktı_klasörü> <tur> <kompartman_id>
// Girdi: tur<N>_<id>_chatgpt.json, tur<N>_<id>_deepseek.json → Çıktı: <id>_chatgpte_secim.txt (DeepSeek metinleri),
// <id>_deepseeke_secim.txt (ChatGPT metinleri).
const fs = require('fs');
const path = require('path');
const [inDir, outDir, tur, id] = process.argv.slice(2);
const load = m => JSON.parse(fs.readFileSync(path.join(inDir, `tur${tur}_${id}_${m}.json`), 'utf8'));
const brief = (texts) => {
  const n = texts.length, sec = Math.floor(n / 2); // 20 → 10, 40 → 20
  let s = 'SEÇİM GÖREVİ\n\n';
  s += `Bu sohbette sana verdiğim talimatla (aynı fal türü, aynı kompartman, aynı kitleler) BAŞKA BİR YAZARIN yazdığı ${n} metin aşağıda.\n`;
  s += `Görevin: bu ${n} metinden, talimattaki GERÇEK ÖRNEK METİNLERE üslup ve sistem olarak en çok benzeyen, en SPESİFİK GÖRÜNEN, okuyana "wow, bildin!" dedirtecek, BİLİYOR HİSSİ VEREN ve kendi kitlesine en uygun EN İYİ ${sec} tanesini seçmek.\n`;
  s += `Yalnız bu ${n} metni değerlendir (kendi yazdıklarını değil). Klişe, genel geçer, kitleyle çelişen ya da yer tutucusu hatalı olanları eleme.\n`;
  s += 'ÇEŞİTLİLİK ÖLÇÜTÜ: Örneklere bire bir benzeyenleri ve birbirinin kalıbını tekrarlayanları (moda mod: "Salı günü müjde var / Çarşamba günü müjde var") ELE. Seçtiğin metinler; NE olacağı, NEREDEN, KİM aracılığıyla, NASIL, NE ZAMAN ve sonucun nasıl hissedileceği bakımından birbirinden belirgin farklı olsun. "Keyfin yerine gelecek" gibi sonucun NASIL\'ını somutlamayanları değil, somutlayanları seç.\n';
  s += 'TUTMA ÖLÇÜTÜ (cold reading / Barnum): Ayrıntılı GÖRÜNEN ama okuyanların çoğunda GERÇEKTEN TUTACAK metinleri seç — "bu metni okuyan 100 kişiden kaçı \'evet, bu bende de oldu/oluyor\' der?" sorusuna en yüksek cevabı verenler. Dar ve kontrol edilebilir ayrıntı (kesin saat, kesin tutar, adı verilen mekân, nadir/tek seferlik olay, üç özellikli dar kişi tarifi) içerip tutmama ihtimali yüksek olanları ELE.\n\n';
  s += `ÇIKTI: Yalnızca tek bir kod bloğu içinde JSON: {"secilenler":[${sec} adet no], "gerekce":{"<no>":"kısa gerekçe", …}}\n\n`;
  s += 'METİNLER:\n';
  for (const t of texts) s += `\n#${t.no} | kitle: ${t.kitle}\n${t.metin}\n`;
  return s;
};
// Model çifti: MODELLER=chatgpt,codex (varsayılan chatgpt,deepseek). <A>e_secim = B'nin metinleri (A seçer).
const [A, B] = (process.env.MODELLER || 'chatgpt,deepseek').split(',');
fs.writeFileSync(path.join(outDir, `tur${tur}_${id}_${A}e_secim.txt`), brief(load(B)));
fs.writeFileSync(path.join(outDir, `tur${tur}_${id}_${B}e_secim.txt`), brief(load(A)));
console.log('ok', id);
