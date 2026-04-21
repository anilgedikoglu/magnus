import os, json, re

BASE = r'C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\YuzFali\Fallar\Baskasi'

def decode_escapes(s):
    result = []
    i = 0
    while i < len(s):
        ch = s[i]
        if ch == chr(92) and i + 1 < len(s):
            nc = s[i+1]
            if nc == 'n':
                result.append('\n'); i += 2; continue
            elif nc == '"':
                result.append('"'); i += 2; continue
            elif nc == chr(92):
                result.append(chr(92)); i += 2; continue
            elif nc == 'u' and i + 5 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+6], 16))); i += 6; continue
                except Exception:
                    pass
            elif nc == 'x' and i + 3 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+4], 16))); i += 4; continue
                except Exception:
                    pass
        result.append(s[i])
        i += 1
    return ''.join(result)

def parse_asset(path):
    with open(path, encoding='utf-8', errors='replace') as f:
        content = f.read()
    m = re.search(
        r'aciklama:\s*\n(.*?)(?=\n\s*aciklamaEng:|\n\s*gerekliDegisken|\n\s*gostermeSansi|\Z)',
        content, re.DOTALL)
    if not m:
        return ''
    block = m.group(1)
    items = re.findall(r'-\s*"(.*?)"\s*(?=\n\s*-\s*"|\n\s*\w|\Z)', block, re.DOTALL)
    if not items:
        sv = re.search(r'-\s*"(.*)"', block, re.DOTALL)
        if sv:
            items = [sv.group(1)]
    if not items:
        return ''
    raw = items[0]
    # Join YAML continuation lines
    lines = raw.split('\n')
    joined = []
    for line in lines:
        if joined and line.startswith(' '):
            joined[-1] = joined[-1].rstrip() + ' ' + line.lstrip()
        else:
            joined.append(line)
    raw = '\n'.join(joined)
    raw = decode_escapes(raw)
    raw = raw.strip().strip('"')
    raw = re.sub(r'\n{3,}', '\n\n', raw)
    return raw.strip()

FOLDER_NORM = {
    'SacboyuKapali':   'Kapali',
    'SacrengiKapali':  'Kapali',
    'SapkabereKapali': 'Kapali',
}

data = {
    'yuzfalitame': [], 'yuzfalitamkl': [],
    'yfmoral':    {'Moraliiyi': [], 'Moralikotu': [], 'Moralinormal': []},
    'yfsapka':    {'Bereli': [], 'Kapali': [], 'Sapkali': [], 'Sapkasiz': []},
    'yfsacrengi': {'Beyaz': [], 'Esmer': [], 'Kapali': [], 'Kizil': [],
                   'Kumral': [], 'Mavi': [], 'Pembe': [], 'Sarisin': []},
    'yfsacboyu':  {'Kapali': [], 'Kel': [], 'KisaSac': [], 'UzunSac': []},
    'yfgozrengi': {'kahve': [], 'mavi': [], 'yesil': []},
    'yfgozluk':   {'Gozluklu': [], 'Gozluksuz': []},
    'yfsakal':    {'SakalKisa': [], 'SakalUzun': [], 'SakalYok': []},
    'yfkupe':     {'Kupeli': [], 'Kupesiz': []},
}

CAT_MAP = {
    'yfmoral': 'yfmoral', 'yfsapka': 'yfsapka', 'yfsacrengi': 'yfsacrengi',
    'yfsacboyu': 'yfsacboyu', 'yfgozrengi': 'yfgozrengi', 'yfgozluk': 'yfgozluk',
    'yfsakal': 'yfsakal', 'yfkupe': 'yfkupe',
}

gid = 1

# Root-level TamE / TamKL
for fname in os.listdir(BASE):
    fpath = os.path.join(BASE, fname)
    if not os.path.isfile(fpath) or not fname.endswith('.asset'):
        continue
    text = parse_asset(fpath)
    if not text:
        continue
    if 'TamE' in fname:
        data['yuzfalitame'].append({'id': gid, 'metin': text}); gid += 1
    elif 'TamKL' in fname:
        data['yuzfalitamkl'].append({'id': gid, 'metin': text}); gid += 1

# Subfolders
for cat_name in os.listdir(BASE):
    cat_path = os.path.join(BASE, cat_name)
    if not os.path.isdir(cat_path):
        continue
    json_cat = CAT_MAP.get(cat_name)
    if not json_cat:
        continue
    for variant_name in os.listdir(cat_path):
        variant_path = os.path.join(cat_path, variant_name)
        if not os.path.isdir(variant_path):
            continue
        json_variant = FOLDER_NORM.get(variant_name, variant_name)
        if json_variant not in data[json_cat]:
            data[json_cat][json_variant] = []
        for fname in os.listdir(variant_path):
            if not fname.endswith('.asset'):
                continue
            text = parse_asset(os.path.join(variant_path, fname))
            if text:
                data[json_cat][json_variant].append({'id': gid, 'metin': text})
                gid += 1

# Report
total = 0
for k, v in data.items():
    if isinstance(v, list):
        print(f'  {k}: {len(v)}')
        total += len(v)
    else:
        for sk, sv in v.items():
            print(f'  {k}/{sk}: {len(sv)}')
            total += len(sv)
print(f'TOPLAM: {total}')

out = 'C:/src/magnus_app/assets/data/yuzfali_baskasi.json'
with open(out, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print('Kaydedildi:', out)
