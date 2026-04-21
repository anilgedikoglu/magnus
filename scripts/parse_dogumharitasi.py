import sys, io, os, json, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

BASE = 'C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/DogumHaritasi/Metinler'

def decode_escape(s):
    result = []
    i = 0
    while i < len(s):
        ch = s[i]
        if ch == chr(92) and i+1 < len(s):
            c = s[i+1]
            if c == 'u' and i+5 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+6], 16)))
                    i += 6; continue
                except: pass
            elif c == 'x' and i+3 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+4], 16)))
                    i += 4; continue
                except: pass
            elif c == 'n':  result.append('\n'); i += 2; continue
            elif c == '"':  result.append('"');  i += 2; continue
            elif c == chr(92): result.append(chr(92)); i += 2; continue
        result.append(s[i]); i += 1
    return ''.join(result)

def extract_aciklama(content):
    lines = content.split('\n')
    in_aciklama = False
    items = []
    buf = []

    for line in lines:
        if re.match(r'\s*aciklama:', line) and 'Eng' not in line:
            in_aciklama = True
            buf = []; continue
        if re.match(r'\s*aciklamaEng:', line):
            if buf:
                text = ' '.join(buf).strip()
                if text.startswith('"'): text = text[1:]
                if text.endswith('"'):   text = text[:-1]
                items.append(decode_escape(text))
                buf = []
            in_aciklama = False; continue
        if not in_aciklama: continue

        stripped = line.strip()
        if stripped.startswith('- "') or stripped.startswith("- '"):
            if buf:
                text = ' '.join(buf).strip()
                if text.startswith('"'): text = text[1:]
                if text.endswith('"'):   text = text[:-1]
                items.append(decode_escape(text))
            buf = [stripped[2:]]
        elif stripped.startswith('- '):
            if buf:
                text = ' '.join(buf).strip()
                if text.startswith('"'): text = text[1:]
                if text.endswith('"'):   text = text[:-1]
                items.append(decode_escape(text))
            buf = [stripped[2:]]
        else:
            if buf: buf.append(stripped)

    if buf and in_aciklama:
        text = ' '.join(buf).strip()
        if text.startswith('"'): text = text[1:]
        if text.endswith('"'):   text = text[:-1]
        items.append(decode_escape(text))
    return items

def parse_folder(folder_name):
    folder = os.path.join(BASE, folder_name)
    entries = []
    uid = 1
    for f in sorted(os.listdir(folder)):
        if not f.endswith('.asset'): continue
        with open(os.path.join(folder, f), encoding='utf-8', errors='replace') as fh:
            content = fh.read()
        texts = extract_aciklama(content)
        for t in texts:
            t = t.strip()
            t = re.sub(r'<sprite=\d+>', '', t).strip()
            if t:
                entries.append({'id': uid, 'metin': t, 'kosullar': []})
                uid += 1
    return entries

folders = {
    'giris':   'Giris',
    'hisler':  '1Hisler',
    'olaylar': '2Olaylar',
    'fizik':   '3FizikSaglik',
    'veda':    'Veda',
}

result = {}
for key, folder in folders.items():
    result[key] = parse_folder(folder)
    print(f'{key}: {len(result[key])} metin')

out_path = 'C:/src/magnus_app/assets/data/dogumharitasi.json'
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, indent=2)
print(f'Kaydedildi: {out_path}')
