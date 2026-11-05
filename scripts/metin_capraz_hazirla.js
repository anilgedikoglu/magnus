// magnus-metin-uretimi: çapraz seçim dosyaları. Bir modelin 20 metnini diğerine "en iyi 10'u seç" diye verir.
// Kullanım: node scripts/metin_capraz_hazirla.js <indirilen_klasörü> <çıktı_klasörü> <tur> <kompartman_id>
// Girdi: tur<N>_<id>_chatgpt.json, tur<N>_<id>_deepseek.json → Çıktı: <id>_chatgpte_secim.txt (DeepSeek metinleri),
// <id>_deepseeke_secim.txt (ChatGPT metinleri).
const fs = require('fs');
const path = require('path');
const [inDir, outDir, tur, id] = process.argv.slice(2);
const load = m => JSON.parse(fs.readFileSync(path.join(inDir, `tur${tur}_${id}_${m}.json`), 'utf8'));
const brief = (texts) => {
  let s = 'SEÇİM GÖREVİ\n\n';
  s += 'Bu sohbette sana verdiğim talimatla (aynı fal türü, aynı kompartman, aynı 20 kitle) BAŞKA BİR YAZARIN yazdığı 20 metin aşağıda.\n';
  s += 'Görevin: bu 20 metinden, talimattaki GERÇEK ÖRNEK METİNLERE üslup ve sistem olarak en çok benzeyen, en SPESİFİK, okuyana "wow, bildin!" dedirtecek, BİLİYOR HİSSİ VEREN ve kendi kitlesine en uygun EN İYİ 10 tanesini seçmek.\n';
  s += 'Yalnız bu 20 metni değerlendir (kendi yazdıklarını değil). Klişe, genel geçer, kitleyle çelişen ya da yer tutucusu hatalı olanları eleme.\n\n';
  s += 'ÇIKTI: Yalnızca tek bir kod bloğu içinde JSON: {"secilenler":[10 adet no], "gerekce":{"<no>":"kısa gerekçe", …}}\n\n';
  s += 'METİNLER:\n';
  for (const t of texts) s += `\n#${t.no} | kitle: ${t.kitle}\n${t.metin}\n`;
  return s;
};
fs.writeFileSync(path.join(outDir, `tur${tur}_${id}_chatgpte_secim.txt`), brief(load('deepseek')));
fs.writeFileSync(path.join(outDir, `tur${tur}_${id}_deepseeke_secim.txt`), brief(load('chatgpt')));
console.log('ok', id);
