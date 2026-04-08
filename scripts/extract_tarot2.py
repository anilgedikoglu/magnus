import os, json

BASE = r'C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Tarot\KlasikTarot'
OUT  = r'C:\src\magnus_app\assets\data\tarot_texts.json'

BACKSLASH = chr(92)

def decode_yaml_str(s):
    out = []
    i = 0
    while i < len(s):
        if s[i] == BACKSLASH and i + 1 < len(s):
            c = s[i + 1]
            if c == 'u' and i + 6 <= len(s):
                out.append(chr(int(s[i+2:i+6], 16)))
                i += 6
            elif c == 'x' and i + 4 <= len(s):
                out.append(chr(int(s[i+2:i+4], 16)))
                i += 4
            elif c == 'n':
                out.append('\n')
                i += 2
            elif c == 't':
                out.append('\t')
                i += 2
            elif c == '"':
                out.append('"')
                i += 2
            elif c == BACKSLASH:
                out.append(BACKSLASH)
                i += 2
            else:
                out.append(s[i])
                i += 1
        else:
            out.append(s[i])
            i += 1
    return ''.join(out)

def parse_aciklama(lines):
    collecting = False
    parts = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('aciklama:'):
            collecting = True
            continue
        if collecting and stripped.startswith('aciklamaEng:'):
            break
        if collecting:
            parts.append(stripped)

    # Join continuation lines with a space (YAML folded string)
    text = ''
    for p in parts:
        if p.startswith('- '):
            p = p[2:]
        if text:
            text += ' ' + p
        else:
            text = p

    if text.startswith('"'):
        text = text[1:]
    if text.endswith('"'):
        text = text[:-1]

    return decode_yaml_str(text).strip()

def parse_conditions(content):
    conds = []
    in_block = False
    cur_ad = None
    cur_dg = None
    for line in content.split('\n'):
        s = line.strip()
        if s.startswith('gerekliDegisken'):
            in_block = True
            continue
        if in_block:
            if s.startswith('- degiskenAdi:'):
                cur_ad = s.split(':', 1)[1].strip()
                cur_dg = None
            elif s.startswith('degiskenAdi:'):
                cur_ad = s.split(':', 1)[1].strip()
            elif s.startswith('degiskenDegeri:'):
                raw = s.split(':', 1)[1].strip().strip('"')
                cur_dg = decode_yaml_str(raw)
            elif s.startswith('kontrol:'):
                if cur_ad and cur_dg:
                    skip = (cur_ad == 'mod' or 'tarot' in cur_ad.lower() or 'tarot' in cur_dg.lower())
                    if not skip:
                        conds.append({'degisken': cur_ad, 'deger': cur_dg})
                cur_ad = None
                cur_dg = None
            elif s and not s.startswith('-') and ':' in s and not s.startswith('degisken'):
                in_block = False
    return conds

results = []
uid = 0
POS_MAP = {
    'TarGecmis':  'gecmis',
    'TarSimdi':   'simdi',
    'TarGelecek': 'gelecek',
}

for pos_folder, pozisyon in POS_MAP.items():
    pos_path = os.path.join(BASE, pos_folder)
    for subfolder in sorted(os.listdir(pos_path)):
        sub_path = os.path.join(pos_path, subfolder)
        if not os.path.isdir(sub_path):
            continue
        ters = subfolder.startswith('Te')
        for fname in sorted(os.listdir(sub_path)):
            if not fname.endswith('.asset'):
                continue
            fpath = os.path.join(sub_path, fname)
            with open(fpath, encoding='utf-8', errors='replace') as f:
                content = f.read()
            lines = content.split('\n')
            metin = parse_aciklama(lines)
            kosullar = parse_conditions(content)
            if not metin:
                continue
            uid += 1
            results.append({
                'id': uid,
                'pozisyon': pozisyon,
                'kart': fname.replace('.asset', ''),
                'ters': ters,
                'metin': metin,
                'kosullar': kosullar,
            })

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump({'tarot_metinleri': results}, f, ensure_ascii=False, indent=2)

print(f'Toplam: {uid}')
print('gecmis:', sum(1 for r in results if r['pozisyon'] == 'gecmis'))
print('simdi:', sum(1 for r in results if r['pozisyon'] == 'simdi'))
print('gelecek:', sum(1 for r in results if r['pozisyon'] == 'gelecek'))
print('kosullu:', sum(1 for r in results if r['kosullar']))
print()
sample = next((r for r in results if r['kart'] == 'Adalet' and r['pozisyon'] == 'gecmis'), None)
if sample:
    print('Ornek (Adalet gecmis):')
    print(sample['metin'][:400])
