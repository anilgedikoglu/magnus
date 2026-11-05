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
  out="$dir/tur${tur}_${id}_codex_secim_ham.txt"
  prompt="Bu klasördeki tur${tur}_${id}.txt dosyası bir fal metni yazım talimatı ve gerçek örnekler içeriyor; önce onu oku (bağlam). Sonra ${secim} dosyasındaki SEÇİM GÖREVİNİ harfiyen uygula (ÇEŞİTLİLİK ve TUTMA ölçütleri dahil; birbirine çok benzeyenlerden yalnız birini seç). Son yanıtın YALNIZCA geçerli JSON olsun: {\"secilenler\":[…], \"gerekce\":{…}} — kod bloğu işareti yok. Hiçbir dosyayı değiştirme."
fi
timeout 900 "$CODEX" exec --sandbox read-only --skip-git-repo-check -C "$dir" -o "$out" "$prompt" < /dev/null > "$out.log" 2>&1
rc=$?
node -e "
const fs=require('fs');const t=fs.readFileSync(process.argv[1],'utf8');
const i=Math.min(...['[','{'].map(c=>{const k=t.indexOf(c);return k<0?1e9:k}));const j=Math.max(t.lastIndexOf(']'),t.lastIndexOf('}'));
const v=JSON.parse(t.slice(i,j+1));
const hedef=process.argv[2];fs.writeFileSync(hedef,JSON.stringify(v,null,1));
console.log(hedef.split('/').pop(), Array.isArray(v)?v.length+' metin':'secilenler '+(v.secilenler||[]).length);
" "$out" "${out%_ham.txt}.json" || echo "AYRIŞTIRMA HATASI (rc=$rc) → $out.log"
