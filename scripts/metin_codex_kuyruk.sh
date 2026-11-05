#!/usr/bin/env bash
# magnus-metin-uretimi: Codex iş kuyruğu yöneticisi (tek seferde TEK iş; kullanım sınırında bekleyip yeniden dener).
#   bash scripts/metin_codex_kuyruk.sh <scratch_kökü>      (run_in_background ile çalıştır)
# İş dosyası: <kök>/codex_isler.txt — satır başına bir iş (sonradan satır eklenebilir):
#   yaz <tur> <id> <adet>      → <kök>/metin_tur<tur>/tur<tur>_<id>_codex.json
#   sec <tur> <id>             → önce seçim brief'ini kurar (ChatGPT çıktısı indirilen'de olmalı), sonra
#                                <kök>/metin_tur<tur>/tur<tur>_<id>_codex_secim.json
#   DUR                        → kuyruğu bitirir
# Bitenler <kök>/codex_bitti.txt'ye yazılır. Sınır mesajındaki "try again at H:MM AM/PM" saatine kadar uyur.
# 3 saat boyunca yeni iş gelmezse kendiliğinden çıkar.
set -u
K=$1; I="C:/Users/AG/Desktop/indirilen"
cd "$(dirname "$0")/.." || exit 1
touch "$K/codex_isler.txt" "$K/codex_bitti.txt"
bosta=0
saate_kadar_bekle() { # $1 = log dosyası
  local t; t=$(grep -o -E "try again at [0-9]{1,2}:[0-9]{2} ?[AP]M" "$1" | tail -1 | sed -E 's/try again at //')
  [ -z "$t" ] && { sleep 600; return; }
  local hedef; hedef=$(date -d "$t" +%s 2>/dev/null) || { sleep 600; return; }
  local simdi; simdi=$(date +%s); [ "$hedef" -le "$simdi" ] && hedef=$((hedef + 86400))
  local fark=$((hedef - simdi + 90)); [ $fark -gt 21600 ] && fark=21600
  echo "$(date +%H:%M) sınır: $t'e kadar bekleniyor (${fark}s)"; sleep $fark
}
while true; do
  is=""
  while IFS= read -r satir; do
    [ -z "$satir" ] && continue
    grep -qxF "$satir" "$K/codex_bitti.txt" && continue
    # sec işi hazır değilse (Codex yazımı ya da ChatGPT çıktısı yok) atla, sonra yeniden bakılır
    set -- $satir
    if [ "$1" = sec ] && { [ ! -s "$K/metin_tur$2/tur$2_$3_codex.json" ] || [ ! -s "$I/tur$2_$3_chatgpt.json" ]; }; then continue; fi
    is="$satir"; break
  done < "$K/codex_isler.txt"
  if [ -z "$is" ]; then sleep 60; bosta=$((bosta + 1)); [ $bosta -gt 180 ] && exit 0; continue; fi
  bosta=0
  [ "$is" = "DUR" ] && { echo DUR >> "$K/codex_bitti.txt"; exit 0; }
  set -- $is; tur=$2; id=$3; dir="$K/metin_tur$tur"
  if [ "$1" = yaz ]; then
    hedef="$dir/tur${tur}_${id}_codex.json"; log="$dir/tur${tur}_${id}_codex_ham.txt.log"
    [ -s "$hedef" ] || bash scripts/metin_codex.sh yaz "$dir" "$tur" "$id" "$4"
    [ -s "$hedef" ] && cp "$hedef" "$I/"
  else
    hedef="$dir/tur${tur}_${id}_codex_secim.json"; log="$dir/tur${tur}_${id}_codex_secim_ham.txt.log"
    if [ ! -s "$hedef" ]; then
      cp "$dir/tur${tur}_${id}_codex.json" "$I/" 2>/dev/null
      MODELLER=chatgpt,codex node scripts/metin_capraz_hazirla.js "$I" "$dir" "$tur" "$id" >/dev/null 2>&1 \
        && cp "$dir/tur${tur}_${id}_chatgpte_secim.txt" "$I/" \
        && bash scripts/metin_codex.sh sec "$dir" "$tur" "$id" "tur${tur}_${id}_codexe_secim.txt"
    fi
  fi
  if [ -s "$hedef" ]; then echo "$is" >> "$K/codex_bitti.txt"; echo "$(date +%H:%M) bitti: $is"
  elif grep -q "usage limit" "$log" 2>/dev/null; then saate_kadar_bekle "$log"
  else echo "$(date +%H:%M) HATA: $is (log: $log)"; echo "$is" >> "$K/codex_bitti.txt"; echo "$is" >> "$K/codex_hata.txt"; fi
done
