"""
Kahve Falı Unity .asset dosyalarından JSON çıkarma scripti.
Kaynak: C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/KahveFali/TumFallar/
Çıktı:  C:/src/magnus_app/assets/data/kahve_{bolum}.json
"""

import os
import json
import re

BASE = "C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/KahveFali/TumFallar"
OUT  = "C:/src/magnus_app/assets/data"

BOLUMLER = {
    "AKarsilamaX": "kahve_akarsilama",
    "BGiris":      "kahve_giris",
    "CBaglamaX":   "kahve_baglama",
    "DGelisme":    "kahve_gelisme",
    "ESonuc":      "kahve_sonuc",
    "FUgurlamaX":  "kahve_ugurlama",
}

def decode_escape(s):
    out = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i+1]
            if nxt == 'n':
                out.append('\n')
                i += 2
            elif nxt == '"':
                out.append('"')
                i += 2
            elif nxt == '\\':
                out.append('\\')
                i += 2
            elif nxt == 'u' and i + 5 < len(s):
                hex_str = s[i+2:i+6]
                try:
                    out.append(chr(int(hex_str, 16)))
                    i += 6
                except ValueError:
                    out.append(s[i])
                    i += 1
            elif nxt == 'x' and i + 3 < len(s):
                hex_str = s[i+2:i+4]
                try:
                    out.append(chr(int(hex_str, 16)))
                    i += 4
                except ValueError:
                    out.append(s[i])
                    i += 1
            else:
                out.append(s[i])
                i += 1
        else:
            out.append(s[i])
            i += 1
    return ''.join(out)

def join_continuation(s):
    # YAML satır devamı: gerçek newline + boşluklar → tek boşluk
    result = re.sub(r'\n[ \t]+', ' ', s)
    return result

def strip_outer_quotes(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        s = s[1:-1]
    return s.strip()

def clean_text(s):
    # 3+ boş satırı 2'ye indir
    s = re.sub(r'\n{3,}', '\n\n', s)
    return s.strip()

def parse_aciklama(content):
    """aciklama: alanındaki Türkçe metni parse et."""
    lines = content.split('\n')
    in_aciklama = False
    collected = []

    for line in lines:
        stripped = line.strip()
        if stripped.startswith('aciklama:'):
            in_aciklama = True
            rest = stripped[len('aciklama:'):].strip()
            if rest and rest != '[]':
                collected.append(rest)
            continue
        if in_aciklama:
            # Yeni top-level alan → dur
            if stripped and not stripped.startswith('-') and not stripped.startswith('"') and ':' in stripped and not stripped.startswith(' '):
                break
            if stripped.startswith('aciklamaEng:'):
                break
            if stripped.startswith('- '):
                collected.append(stripped[2:])
            elif stripped and collected:
                collected.append(stripped)

    if not collected:
        return None

    raw = ' '.join(collected)
    raw = decode_escape(raw)
    raw = join_continuation(raw)
    raw = strip_outer_quotes(raw)
    return clean_text(raw)

def parse_kosullar(content):
    """gerekliDegiskenler bloğunu parse et."""
    lines = content.split('\n')
    in_block = False
    kosullar = []
    current = {}

    for line in lines:
        stripped = line.strip()
        if stripped.startswith('gerekliDegiskenler:') or stripped.startswith('gerekliDegisken:'):
            in_block = True
            continue
        if in_block:
            if stripped and not stripped.startswith('-') and ':' in stripped and not stripped.startswith(' ') and not stripped.startswith('degisken'):
                break
            if stripped.startswith('- '):
                if current:
                    kosullar.append(current)
                current = {}
                rest = stripped[2:].strip()
                if ':' in rest:
                    k, v = rest.split(':', 1)
                    current[k.strip()] = v.strip()
            elif ':' in stripped and in_block:
                if stripped.startswith('degiskenAdi:'):
                    current['degisken'] = stripped.split(':', 1)[1].strip()
                elif stripped.startswith('degiskenDegeri:'):
                    current['deger'] = stripped.split(':', 1)[1].strip()

    if current:
        kosullar.append(current)

    result = []
    for k in kosullar:
        if 'degisken' in k and 'deger' in k:
            result.append({'degisken': k['degisken'], 'deger': k['deger']})
    return result

def process_folder(folder_path, bolum_adi):
    entries = []
    asset_id = 1

    files = sorted([f for f in os.listdir(folder_path) if f.endswith('.asset')])
    print(f"  {bolum_adi}: {len(files)} dosya")

    for fname in files:
        fpath = os.path.join(folder_path, fname)
        try:
            with open(fpath, encoding='utf-8', errors='replace') as f:
                content = f.read()
        except Exception as e:
            print(f"    HATA okuma: {fname} → {e}")
            continue

        metin = parse_aciklama(content)
        if not metin or len(metin) < 5:
            continue

        kosullar = parse_kosullar(content)

        entries.append({
            "id": asset_id,
            "metin": metin,
            "kosullar": kosullar,
        })
        asset_id += 1

    return entries

def main():
    os.makedirs(OUT, exist_ok=True)

    for klasor, json_adi in BOLUMLER.items():
        folder_path = os.path.join(BASE, klasor)
        if not os.path.isdir(folder_path):
            print(f"UYARI: Klasör bulunamadı: {folder_path}")
            continue

        entries = process_folder(folder_path, klasor)
        out_path = os.path.join(OUT, f"{json_adi}.json")
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump({json_adi: entries}, f, ensure_ascii=False, indent=2)
        print(f"  → {out_path} ({len(entries)} metin)")

    print("\nTamamlandı!")

if __name__ == '__main__':
    main()
