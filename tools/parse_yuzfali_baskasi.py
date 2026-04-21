"""
Parse Unity .asset files from:
C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\YuzFali\Fallar\Baskasi\
into:
C:/src/magnus_app/assets/data/yuzfali_baskasi.json
"""

import os
import json

BASE = r'C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\YuzFali\Fallar\Baskasi'
OUT  = r'C:\src\magnus_app\assets\data\yuzfali_baskasi.json'

# ── escape decoder ────────────────────────────────────────────────────────────
def decode_escapes(s):
    result = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i + 1]
            if nxt == 'n':
                result.append('\n')
                i += 2
            elif nxt == '"':
                result.append('"')
                i += 2
            elif nxt == '\\':
                result.append('\\')
                i += 2
            elif nxt == 'u' and i + 5 < len(s):
                hex4 = s[i+2:i+6]
                if all(c in '0123456789abcdefABCDEF' for c in hex4):
                    result.append(chr(int(hex4, 16)))
                    i += 6
                else:
                    result.append(s[i])
                    i += 1
            elif nxt == 'x' and i + 3 < len(s):
                hex2 = s[i+2:i+4]
                if all(c in '0123456789abcdefABCDEF' for c in hex2):
                    result.append(chr(int(hex2, 16)))
                    i += 4
                else:
                    result.append(s[i])
                    i += 1
            else:
                result.append(s[i])
                i += 1
        else:
            result.append(s[i])
            i += 1
    return ''.join(result)


# ── YAML continuation-line joiner ─────────────────────────────────────────────
def join_yaml_continuation(raw_lines):
    """
    YAML folds continuation lines (real newline + leading spaces) into a
    single space.  We mimic that: if a line (after stripping its own leading
    spaces) continues directly from the previous one we join with a space.
    """
    if not raw_lines:
        return ''
    result = raw_lines[0].rstrip()
    for line in raw_lines[1:]:
        stripped = line.lstrip()
        if stripped:
            result += ' ' + stripped.rstrip()
    return result


# ── extract `aciklama:` block ─────────────────────────────────────────────────
def extract_aciklama(content):
    lines = content.splitlines()
    collecting = False
    raw_pieces = []          # list of continuation-line groups
    current_group = []       # lines belonging to the current list item

    for line in lines:
        stripped = line.rstrip()

        if stripped.strip() == 'aciklama:':
            collecting = True
            continue

        if collecting:
            # Stop when we hit the next top-level key
            if stripped.startswith('  aciklamaEng:') or stripped.strip().startswith('aciklamaEng:'):
                if current_group:
                    raw_pieces.append(current_group)
                break

            # New list item starts with "  - "
            if stripped.startswith('  - '):
                if current_group:
                    raw_pieces.append(current_group)
                # Grab text after "  - "
                first_text = stripped[4:]
                current_group = [first_text]
            elif collecting and current_group is not None:
                # Continuation line — keep indented content
                current_group.append(stripped)

    if not raw_pieces:
        return None

    # Take the first (and normally only) list item
    raw = join_yaml_continuation(raw_pieces[0])

    # Decode escape sequences
    raw = decode_escapes(raw)

    # Remove wrapping double-quotes if present
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"'):
        raw = raw[1:-1]

    # Normalize blank lines (3+ → 2)
    import re
    raw = re.sub(r'\n{3,}', '\n\n', raw)
    raw = raw.strip()
    return raw


# ── extract `gerekliDegiskenler:` block ───────────────────────────────────────
def extract_kosullar(content):
    lines = content.splitlines()
    collecting = False
    kosullar = []
    current = {}

    for line in lines:
        stripped = line.strip()

        if stripped in ('gerekliDegiskenler:', 'gerekliDegisken:'):
            collecting = True
            continue

        if collecting:
            # Stop at next sibling key (same or lower indent)
            if stripped and not stripped.startswith('-') and not stripped.startswith('degisken') and ':' in stripped:
                if current:
                    kosullar.append(current)
                    current = {}
                break

            if stripped.startswith('- degiskenAdi:'):
                if current:
                    kosullar.append(current)
                    current = {}
                adi = stripped.split(':', 1)[1].strip()
                current = {'degisken': decode_escapes(adi)}
            elif stripped.startswith('degiskenDegeri:'):
                deger = stripped.split(':', 1)[1].strip()
                current['deger'] = decode_escapes(deger)
            # ignore kontrol: lines

    if current and 'degisken' in current:
        kosullar.append(current)

    return [k for k in kosullar if 'degisken' in k and 'deger' in k]


# ── parse a single .asset file ────────────────────────────────────────────────
def parse_asset(path):
    with open(path, encoding='utf-8', errors='replace') as f:
        content = f.read()
    metin = extract_aciklama(content)
    kosullar = extract_kosullar(content)
    return metin, kosullar


# ── collect all .asset files from a folder (no .meta) ────────────────────────
def collect_assets(folder):
    items = []
    for name in sorted(os.listdir(folder)):
        if name.endswith('.asset') and not name.endswith('.asset.meta'):
            items.append(os.path.join(folder, name))
    return items


# ── build output structure ────────────────────────────────────────────────────
output = {}
global_id = [1]   # mutable counter

def next_id():
    val = global_id[0]
    global_id[0] += 1
    return val


def assets_to_list(folder):
    entries = []
    for path in collect_assets(folder):
        metin, kosullar = parse_asset(path)
        if metin:
            entries.append({
                'id': next_id(),
                'metin': metin,
                'kosullar': kosullar,
            })
    return entries


# ── ROOT single files ─────────────────────────────────────────────────────────
for key, filename in [
    ('yuzfalitame',  'YuzFaliTamE.asset'),
    ('yuzfalitamkl', 'YuzFaliTamKL.asset'),
]:
    path = os.path.join(BASE, filename)
    metin, kosullar = parse_asset(path)
    if metin:
        output[key] = [{'id': next_id(), 'metin': metin, 'kosullar': kosullar}]
    else:
        output[key] = []


# ── sub-folder categories ─────────────────────────────────────────────────────
# Mapping: (category_key, subfolder_name, json_key)
CATEGORIES = [
    # yfmoral
    ('yfmoral',    'Moraliiyi',        'Moraliiyi'),
    ('yfmoral',    'Moralikotu',       'Moralikotu'),
    ('yfmoral',    'Moralinormal',     'Moralinormal'),
    # yfsapka
    ('yfsapka',    'Bereli',           'Bereli'),
    ('yfsapka',    'SapkabereKapali',  'Kapali'),    # normalize
    ('yfsapka',    'Sapkali',          'Sapkali'),
    ('yfsapka',    'Sapkasiz',         'Sapkasiz'),
    # yfsacrengi
    ('yfsacrengi', 'Beyaz',            'Beyaz'),
    ('yfsacrengi', 'Esmer',            'Esmer'),
    ('yfsacrengi', 'SacrengiKapali',   'Kapali'),    # normalize
    ('yfsacrengi', 'Kizil',            'Kizil'),
    ('yfsacrengi', 'Kumral',           'Kumral'),
    ('yfsacrengi', 'Mavi',             'Mavi'),
    ('yfsacrengi', 'Pembe',            'Pembe'),
    ('yfsacrengi', 'Sarisin',          'Sarisin'),
    # yfsacboyu
    ('yfsacboyu',  'SacboyuKapali',    'Kapali'),    # normalize
    ('yfsacboyu',  'Kel',              'Kel'),
    ('yfsacboyu',  'KisaSac',          'KisaSac'),
    ('yfsacboyu',  'UzunSac',          'UzunSac'),
    # yfgozrengi
    ('yfgozrengi', 'kahve',            'kahve'),
    ('yfgozrengi', 'mavi',             'mavi'),
    ('yfgozrengi', 'yesil',            'yesil'),
    # yfgozluk
    ('yfgozluk',   'Gozluklu',         'Gozluklu'),
    ('yfgozluk',   'Gozluksuz',        'Gozluksuz'),
    # yfsakal
    ('yfsakal',    'SakalKisa',        'SakalKisa'),
    ('yfsakal',    'SakalUzun',        'SakalUzun'),
    ('yfsakal',    'SakalYok',         'SakalYok'),
    # yfkupe
    ('yfkupe',     'Kupeli',           'Kupeli'),
    ('yfkupe',     'Kupesiz',          'Kupesiz'),
]

for cat_key, subfolder, json_key in CATEGORIES:
    folder = os.path.join(BASE, cat_key, subfolder)
    entries = assets_to_list(folder)
    if cat_key not in output:
        output[cat_key] = {}
    output[cat_key][json_key] = entries


# ── write JSON ────────────────────────────────────────────────────────────────
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

# ── report ────────────────────────────────────────────────────────────────────
total = 0

def count_list(lst):
    return len(lst) if isinstance(lst, list) else 0

for key, val in output.items():
    if isinstance(val, list):
        print(f'  {key}: {len(val)} entry')
        total += len(val)
    elif isinstance(val, dict):
        sub_total = sum(len(v) for v in val.values())
        print(f'  {key}: {sub_total} entries ({", ".join(f"{k}={len(v)}" for k, v in val.items())})')
        total += sub_total

print(f'\nTotal entries: {total}')
print(f'Written to: {OUT}')
