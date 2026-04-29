"""
IChing asset dosyalarını JSON'a dönüştürür.
Kaynak: C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/IChing/Metinler/
Çıktı:  C:/src/magnus_app/assets/data/iching.json
"""

import os, re, json

BASE = r"C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/IChing/Metinler"
OUT  = r"C:/src/magnus_app/assets/data/iching.json"

BITIS = {'.', '!', '?', '...', '\u2026', '"', "'", ')'}

def decode_escapes(s):
    result = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i+1]
            if nxt == 'u' and i + 5 <= len(s):
                try:
                    result.append(chr(int(s[i+2:i+6], 16))); i += 6; continue
                except ValueError: pass
            elif nxt == 'x' and i + 3 <= len(s):
                try:
                    result.append(chr(int(s[i+2:i+4], 16))); i += 4; continue
                except ValueError: pass
            elif nxt == 'n':
                result.append('\n'); i += 2; continue
            elif nxt == '"':
                result.append('"'); i += 2; continue
            elif nxt == '\\':
                result.append('\\'); i += 2; continue
        result.append(s[i]); i += 1
    return ''.join(result)

def parse_aciklama(content):
    m = re.search(r'aciklama:(.*?)(?:aciklamaEng:|aciklamaBalonuYok:|gerekliDegisken|sohbetArkaplani)', content, re.DOTALL)
    if not m:
        return []
    block = m.group(1)
    items = re.findall(r'-\s+"((?:[^"\\]|\\.)*)"', block)
    if items:
        return items
    # Cok satirli format
    raw_lines = block.split('\n')
    current = None
    results = []
    for line in raw_lines:
        s = line.strip()
        if s.startswith('- "'):
            if current is not None:
                results.append(current)
            current = s[3:]
            if current.endswith('"'):
                current = current[:-1]
                results.append(current); current = None
        elif current is not None and s:
            current += ' ' + s
    if current is not None:
        results.append(current)
    return results

def temizle(raw):
    t = decode_escapes(raw)
    t = re.sub(r'\n[ \t]+', ' ', t)
    t = t.replace('\r', '')
    t = t.strip().strip('"')
    t = re.sub(r'<sprite=\d+>', '', t).strip()
    t = re.sub(r'\n{3,}', '\n\n', t).strip()
    return t

dosyalar = sorted([f for f in os.listdir(BASE) if f.endswith('.asset')])
metinler = []
id_sayac = 1
sorunlu  = []

for dosya in dosyalar:
    fp = os.path.join(BASE, dosya)
    try:
        with open(fp, 'rb') as fh:
            raw = fh.read().decode('utf-8', errors='replace')
    except Exception as e:
        print(f"  HATA {dosya}: {e}"); continue

    items = parse_aciklama(raw)
    for item in items:
        metin = temizle(item)
        if len(metin) < 20:
            continue
        son = metin.rstrip()[-1] if metin.rstrip() else ''
        if son not in BITIS:
            sorunlu.append((id_sayac, metin[-80:]))
            continue
        metinler.append({'id': id_sayac, 'metin': metin, 'kosullar': []})
        id_sayac += 1

if sorunlu:
    print(f"UYARI: {len(sorunlu)} kesik metin atlandi:")
    for sid, parca in sorunlu[:5]:
        print(f"  [{sid}] ...{repr(parca)}")

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump({'iching': metinler}, f, ensure_ascii=False, indent=2)

print(f"Tamamlandi: {len(metinler)} metin -> {OUT}")
