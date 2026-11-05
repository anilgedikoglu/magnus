#!/usr/bin/env bash
# magnus-metin-uretimi (ChatGPT + Codex): Codex yazımı biten bölmeler için çapraz seçimi başlatır.
#   bash scripts/metin_capraz_baslat.sh <tur> <tur_klasoru> <id> [id …]
# Her id için: Codex çıktısını indirilen klasörüne kopyalar, MODELLER=chatgpt,codex ile seçim brief'lerini kurar,
# ChatGPT'ye yüklenecek <id>_chatgpte_secim.txt'yi indirilen'e koyar, sonra Codex'in ChatGPT metinlerinden seçimini
# sırayla çalıştırır (uzun sürer → çağıran run_in_background ile çalıştırsın).
set -u
tur=$1; dir=$2; shift 2
I="C:/Users/AG/Desktop/indirilen"
cd "$(dirname "$0")/.." || exit 1
for id in "$@"; do
  cp "$dir/tur${tur}_${id}_codex.json" "$I/" || { echo "$id: codex çıktısı yok"; continue; }
  MODELLER=chatgpt,codex node scripts/metin_capraz_hazirla.js "$I" "$dir" "$tur" "$id"
  cp "$dir/tur${tur}_${id}_chatgpte_secim.txt" "$I/"
done
for id in "$@"; do
  [ -f "$dir/tur${tur}_${id}_codexe_secim.txt" ] && bash scripts/metin_codex.sh sec "$dir" "$tur" "$id" "tur${tur}_${id}_codexe_secim.txt"
done
