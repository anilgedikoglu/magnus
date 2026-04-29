import os, re, json

BASE = "C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/GunlukAstroloji/GunlukAstro"

SECTION_MAP = [
    ("giris",              "Giris"),
    ("astroyorum",         "AstroYorum"),
    ("astrogununsozu",     "AstroGununSozu"),
    ("astrogununayeti",    "AstroGununAyeti"),
    ("astrogununhadisi",   "AstroGununHadisi"),
    ("astroeglencelibilgi","AstroEglenceliBilgi"),
    ("astrokesif",         "AstroKesif"),
    ("astrogununismi",     "AstroGununismi"),
    ("astrogununyemegi",   "AstroGununyemegi"),
    ("astroveda",          "AstroVeda"),
]

def decode_escapes(s):
    result = []
    i = 0
    while i < len(s):
        if s[i] == chr(92) and i+1 < len(s):
            nc = s[i+1]
            if nc == 'n':
                result.append('\n'); i += 2
            elif nc == '"':
                result.append('"'); i += 2
            elif nc == chr(92):
                result.append(chr(92)); i += 2
            elif nc == 'u' and i+5 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+6], 16))); i += 6
                except Exception:
                    result.append(s[i]); i += 1
            elif nc == 'x' and i+3 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+4], 16))); i += 4
                except Exception:
                    result.append(s[i]); i += 1
            else:
                result.append(s[i]); i += 1
        else:
            result.append(s[i]); i += 1
    return ''.join(result)

def parse_aciklama(content):
    texts = []
    in_block = False
    current = []
    for line in content.splitlines():
        if re.match(r'\s*aciklama\s*:', line):
            in_block = True
            continue
        if in_block:
            if re.match(r'\s*aciklamaEng\s*:', line) or re.match(r'\s*gerekliDegisken', line):
                if current:
                    texts.append('\n'.join(current).strip())
                    current = []
                in_block = False
                continue
            stripped = line.strip()
            if stripped.startswith('- "') or stripped.startswith("- '"):
                if current:
                    texts.append('\n'.join(current).strip())
                    current = []
                val = stripped[3:]
                if val.endswith('"') or val.endswith("'"):
                    val = val[:-1]
                current = [val]
            elif stripped.startswith('- '):
                if current:
                    texts.append('\n'.join(current).strip())
                    current = []
                current = [stripped[2:]]
            elif current and stripped:
                current.append(stripped)
    if current:
        texts.append('\n'.join(current).strip())
    return texts

def parse_kosullar(content):
    kosullar = []
    in_block = False
    cur = None
    for line in content.splitlines():
        if re.match(r'\s*gerekliDegisken', line):
            in_block = True
            continue
        if not in_block:
            continue
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        if re.match(r'degiskenAdi\s*:', stripped):
            if cur:
                kosullar.append(cur)
            cur = {'degisken': stripped.split(':', 1)[1].strip(), 'deger': ''}
        elif re.match(r'degiskenDegeri\s*:', stripped) and cur:
            cur['deger'] = stripped.split(':', 1)[1].strip()
        elif re.match(r'kontrol\s*:', stripped):
            pass
        elif stripped.startswith('-'):
            pass
        else:
            if cur:
                kosullar.append(cur)
                cur = None
            in_block = False
    if cur:
        kosullar.append(cur)
    return kosullar

result = {}
global_id = 1

for key, folder in SECTION_MAP:
    folder_path = os.path.join(BASE, folder)
    if not os.path.isdir(folder_path):
        print(f"KLASOR YOK: {folder_path}")
        result[key] = []
        continue

    entries = []
    files = sorted([f for f in os.listdir(folder_path) if f.endswith('.asset') and not f.endswith('.meta')])

    for fname in files:
        fpath = os.path.join(folder_path, fname)
        with open(fpath, encoding='utf-8', errors='replace') as f:
            content = f.read()

        texts = parse_aciklama(content)
        kosullar = parse_kosullar(content)

        for t in texts:
            t = decode_escapes(t)
            t = re.sub(r'\n', ' ', t)       # tüm satır kırıklarını boşluğa çevir
            t = re.sub(r'  +', ' ', t)      # fazla boşlukları temizle
            t = t.strip().strip('"').strip("'").strip()
            if len(t) < 20:
                continue
            entries.append({"id": global_id, "metin": t, "kosullar": kosullar})
            global_id += 1

    result[key] = entries
    print(f"{key}: {len(entries)} metin")

total = sum(len(v) for v in result.values())
print(f"\nToplam: {total} metin, {global_id-1} ID")

out_path = "C:/src/magnus_app/assets/data/gunlukastroloji.json"
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, indent=2)
print(f"Kaydedildi: {out_path}")
