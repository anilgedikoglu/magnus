#!/usr/bin/env bash
# magnus-metin-uretimi: Codex ile aday -> İngilizce çeviri (Gemini kotası bittiğinde yedek yol).
# Kullanım: scripts/metin_codex_ceviri.sh <tur_klasoru> <id>
#   Girdi:  <klasör>/<id>_aday.json  (dizi: [{metin,...}])
#   Çıktı:  <klasör>/<id>_en.json    (dizi: ["en",...] aynı sıra/uzunluk)
set -u
CODEX=$(ls "$LOCALAPPDATA"/OpenAI/Codex/bin/*/codex.exe 2>/dev/null | head -1)
[ -z "$CODEX" ] && { echo "codex.exe yok"; exit 1; }
dir=$1; id=$2
n=$(node -e "console.log(require('$dir/${id}_aday.json').length)")
out="$dir/${id}_en_ham.txt"
prompt="Bu klasördeki ${id}_aday.json dosyasını oku; bir nesne dizisidir, her nesnenin 'metin' alanı Magnus adlı mistik fal uygulaması için Türkçe bir metindir. Her 'metin'i akıcı, doğal, aynı mistik ve sıcak İngilizceye çevir. KURALLAR: {{isim}}, {{sayi,1,6}}, {{ay_2}}, {{gun_3}}, {{burc}}, {{harf}}, {{isim hanim/bey}}, {{randomtarih,3,12}} gibi TÜM yer tutucuları ve <color=...>/<b>/<i> etiketlerini ve '||' ayıracını AYNEN koru (içlerini çevirme; yalnız {{data,...}}/{{kelime,...}} içindeki seçenek sözcükleri yapı bozulmadan çevrilebilir). Satır sonlarını (\\n) koru. Son yanıtın YALNIZCA ${n} öğelik geçerli bir JSON dizisi olsun: [\"english1\", \"english2\", ...] — aday ile AYNI sırada, kod bloğu işareti ve açıklama yok. Hiçbir dosyayı değiştirme."
timeout 900 "$CODEX" exec --sandbox read-only --skip-git-repo-check -C "$dir" -o "$out" "$prompt" < /dev/null > "$out.log" 2>&1
node -e "
const fs=require('fs');const t=fs.readFileSync('$out','utf8');
const i=t.indexOf('[');const j=t.lastIndexOf(']');
const v=JSON.parse(t.slice(i,j+1));
if(!Array.isArray(v)) throw new Error('dizi değil');
fs.writeFileSync('$dir/${id}_en.json',JSON.stringify(v,null,1));
console.log('$id en', v.length);
" || echo "ÇEVİRİ AYRIŞTIRMA HATASI $id → $out.log"
