#!/usr/bin/env bash
# magnus-metin-uretimi: Codex CLI ile yazım ya da seçim (ChatGPT'nin çapraz ortağı). Tarayıcısız, çıktı dosyaya.
# Kullanım:
#   scripts/metin_codex.sh yaz   <tur_klasoru> <tur> <id> <adet>      → <klasör>/tur<tur>_<id>_codex.json
#   scripts/metin_codex.sh sec   <tur_klasoru> <tur> <id> <secim_dosyasi.txt> → <klasör>/tur<tur>_<id>_codex_secim.json
# Codex salt-okunur kum havuzunda brief dosyasını okur; son yanıtı -o ile dosyaya düşer.
set -u
CODEX=$(ls "$LOCALAPPDATA"/OpenAI/Codex/bin/*/codex.exe 2>/dev/null | head -1)
[ -z "$CODEX" ] && { echo "codex.exe bulunamadı"; exit 1; }
mod=$1; dir=$2; tur=$3; id=$4
cd "$dir" || exit 1
if [ "$mod" = yaz ]; then
  adet=$5
  out="$dir/tur${tur}_${id}_codex_ham.txt"
  prompt="Bu klasördeki tur${tur}_${id}.txt dosyasını baştan sona oku ve içindeki yazım talimatlarını harfiyen uygula (özellikle COLD READING, ALTIN ÖRNEKLER, İSKELET/TÜMLEÇ ve KİŞİYE ÖZEL bölümleri; kuraldaki örnek ifadeleri aynen kullanma, metinler birbirinden ifade ödünç almasın). Tam ${adet} yeni Türkçe metin yaz. Son yanıtın YALNIZCA geçerli bir JSON dizisi olsun: [{\"no\":1,\"kitle\":\"…\",\"metin\":\"…\"}, …] — kod bloğu işareti ve açıklama yok. Hiçbir dosyayı değiştirme."
else
  secim=$5
  [ -s "$dir/$secim" ] || { echo "seçim dosyası yok: $secim — Codex çağrılmadı"; exit 1; }
  out="$dir/tur${tur}_${id}_codex_secim_ham.txt"
  # Token tasarrufu (Codex kullanım sınırı): yazım brief'i okutulmaz; seçim dosyası ölçütleri ve kitleleri zaten içerir.
  prompt="Bu klasördeki ${secim} dosyası, Magnus adlı Türkçe fal uygulaması için başka bir yazarın yazdığı metinleri ve SEÇİM GÖREVİNİ içeriyor. Görevi harfiyen uygula (ÇEŞİTLİLİK ve TUTMA ölçütleri dahil; birbirine çok benzeyenlerden yalnız birini seç; dar/kontrol edilebilir ayrıntılı ve kitlesiyle çelişenleri ele). Başka dosya okuma. Son yanıtın YALNIZCA geçerli JSON olsun: {\"secilenler\":[…], \"gerekce\":{…}} — gerekçeler çok kısa (en fazla 8 kelime), kod bloğu işareti yok. Hiçbir dosyayı değiştirme."
fi
timeout 900 "$CODEX" exec --sandbox read-only --skip-git-repo-check -C "$dir" -o "$out" "$prompt" < /dev/null > "$out.log" 2>&1
rc=$?
node -e "
const fs=require('fs');const t=fs.readFileSync(process.argv[1],'utf8');
const i=Math.min(...['[','{'].map(c=>{const k=t.indexOf(c);return k<0?1e9:k}));const j=Math.max(t.lastIndexOf(']'),t.lastIndexOf('}'));
const v=JSON.parse(t.slice(i,j+1));
const hedef=process.argv[2];
if(!Array.isArray(v)&&!(v.secilenler||[]).length) throw new Error('boş seçim');
if(Array.isArray(v)&&!v.length) throw new Error('boş yazım');
fs.writeFileSync(hedef,JSON.stringify(v,null,1));
console.log(hedef.split('/').pop(), Array.isArray(v)?v.length+' metin':'secilenler '+(v.secilenler||[]).length);
" "$out" "${out%_ham.txt}.json" || echo "AYRIŞTIRMA HATASI (rc=$rc) → $out.log"
