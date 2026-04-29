"""
Kader Çarkı asset dosyalarını JSON'a dönüştürür.
Kaynak: C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/KaderCarki/
Çıktı:  C:/src/magnus_app/assets/data/kadercarki_<kategori>.json
"""

import os, re, json

BASE = r"C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/KaderCarki"
OUT  = r"C:/src/magnus_app/assets/data"

KATEGORILER = [
    ("1 Alev",   "alev"),
    ("2 Hayvan", "hayvan"),
    ("3 Kure",   "kure"),
    ("4 Renk",   "renk"),
    ("5 Tas",    "tas"),
    ("6 Zar",    "zar"),
]

BITIS = {'.', '!', '?', '…', '"', "'", ')'}

# ── Unicode / escape çözücü ───────────────────────────────────────────────────
def decode_escapes(s):
    result = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i+1]
            if nxt == 'u' and i + 5 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+6], 16))); i += 6; continue
                except ValueError: pass
            elif nxt == 'x' and i + 3 < len(s):
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

# ── Aciklama bloğunu parse et ─────────────────────────────────────────────────
def parse_aciklama(content):
    m = re.search(r'aciklama:(.*?)(?:aciklamaEng:|aciklamaBalonuYok:)', content, re.DOTALL)
    if not m:
        return []
    block = m.group(1)
    items = re.findall(r'-\s+"((?:[^"\\]|\\.)*)"', block)
    if not items:
        # Çok satırlı format
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
    return items

# ── gerekliDegiskenler → kosullar ────────────────────────────────────────────
def parse_kosullar(content):
    m = re.search(r'gerekliDegiskenler:(.*?)(?:\n  \w|\Z)', content, re.DOTALL)
    if not m:
        return []
    block = m.group(1)
    kosullar = []
    entries = re.findall(
        r'degiskenAdi:\s*"?(.*?)"?\s*\n\s*degiskenDegeri:\s*"?(.*?)"?\s*\n\s*kontrol:',
        block, re.DOTALL
    )
    for degisken, deger in entries:
        degisken = decode_escapes(degisken.strip())
        deger    = decode_escapes(deger.strip())
        # mod: wheelspin fal X → sadece kategori işareti, filtrele
        if degisken == 'mod' and degisken.startswith('wheelspin'):
            continue
        if degisken == 'mod':
            continue
        kosullar.append({'degisken': degisken, 'deger': deger})
    return kosullar

# ── Metin temizle ─────────────────────────────────────────────────────────────
def temizle(raw):
    t = decode_escapes(raw)
    # YAML satır devamlılığı: gerçek newline + boşluklar → boşluk
    t = re.sub(r'\n[ \t]+', ' ', t)
    # Başlangıç / bitiş tırnak kaldır
    t = t.strip().strip('"')
    # <sprite=X> temizle
    t = re.sub(r'<sprite=\d+>', '', t).strip()
    # 3+ boş satır → 2
    t = re.sub(r'\n{3,}', '\n\n', t).strip()
    return t

# ── Ana döngü ─────────────────────────────────────────────────────────────────
for klasor, anahtar in KATEGORILER:
    path = os.path.join(BASE, klasor)
    dosyalar = [f for f in os.listdir(path) if f.endswith('.asset')]
    dosyalar.sort()

    metinler = []
    id_sayac = 1
    sorunlu  = []

    for dosya in dosyalar:
        fp = os.path.join(path, dosya)
        try:
            with open(fp, 'rb') as fh:
                raw = fh.read().decode('utf-8', errors='replace')
        except Exception as e:
            print(f"  HATA {dosya}: {e}"); continue

        items    = parse_aciklama(raw)
        kosullar = parse_kosullar(raw)

        for item in items:
            metin = temizle(item)
            if len(metin) < 20:
                continue
            son = metin.rstrip()[-1] if metin.rstrip() else ''
            if son not in BITIS:
                sorunlu.append((id_sayac, metin[-80:]))
                continue
            metinler.append({'id': id_sayac, 'metin': metin, 'kosullar': kosullar})
            id_sayac += 1

    if sorunlu:
        print(f"[{anahtar}] UYARI {len(sorunlu)} kesilmis metin atlandi:")
        for sid, parca in sorunlu[:5]:
            print(f"  [{sid}] ...{repr(parca)}")

    out_path = os.path.join(OUT, f"kadercarki_{anahtar}.json")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump({f"kadercarki_{anahtar}": metinler}, f, ensure_ascii=False, indent=2)

    print(f"[{anahtar}] {len(metinler)} metin -> {out_path}")

print("\nTamamlandi.")
