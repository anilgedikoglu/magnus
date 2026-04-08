import os, json, re

BS = chr(92)  # backslash

def decode_yaml_str(raw):
    out = []
    i = 0
    while i < len(raw):
        c = raw[i]
        if c == BS and i + 1 < len(raw):
            n = raw[i+1]
            if n == 'u' and i + 5 < len(raw):
                out.append(chr(int(raw[i+2:i+6], 16)))
                i += 6; continue
            elif n == 'x' and i + 3 < len(raw):
                out.append(chr(int(raw[i+2:i+4], 16)))
                i += 4; continue
            elif n == 'n': out.append('\n'); i += 2; continue
            elif n == '"': out.append('"'); i += 2; continue
            elif n == BS: out.append(BS); i += 2; continue
        out.append(c); i += 1
    return ''.join(out)

def parse_aciklama(path):
    with open(path, encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    # aciklama: bloğunu bul, bir sonraki anahtar satırına kadar al
    in_block = False
    parts = []
    for line in lines:
        stripped = line.strip()
        if stripped == 'aciklama:':
            in_block = True
            continue
        if in_block:
            # Bir sonraki top-level field'e gelince dur
            if stripped.startswith('aciklamaEng:') or (stripped and not stripped.startswith('-') and not stripped.startswith('"') and ':' in stripped and not stripped.startswith('- ')):
                break
            if stripped.startswith('- '):
                parts.append(stripped[2:])
            elif stripped and parts:  # devam satırı
                parts.append(stripped)

    if not parts:
        return None

    raw = ' '.join(parts)
    # Baş/son tırnakları temizle
    raw = raw.strip()
    if raw.startswith('"') and '"' in raw[1:]:
        raw = raw[1:raw.rfind('"')]
    elif raw.startswith("'") and "'" in raw[1:]:
        raw = raw[1:raw.rfind("'")]

    text = decode_yaml_str(raw)
    text = text.strip()
    return text if text else None

# ─── 1. Tek kart tepkileri (ask kaynak; dilek/sans aynı metinleri kullanıyor) ──
single_tepki = {}
base = r'C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/Tarot/AskKarti/Tepki'
for fname in os.listdir(base):
    if not fname.endswith('.asset'):
        continue
    key = fname[:-6]  # uzantısız = JSON kart adı
    text = parse_aciklama(os.path.join(base, fname))
    if text:
        single_tepki[key] = text

print(f"Tek kart tepki: {len(single_tepki)} kart")
for k, v in list(single_tepki.items())[:2]:
    print(f"  {k}: {v[:60]}")

with open('C:/src/magnus_app/assets/data/tarot_single_tepki.json', 'w', encoding='utf-8') as f:
    json.dump(single_tepki, f, ensure_ascii=False, indent=2)

# ─── 2. Klasik tarot tepkileri (pozisyon + ters) ──────────────────────────────
klasik_base = r'C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/Tarot/KlasikTarot/TarKartTepki'
klasik_tepki = {}
for pozisyon in ['Gecmis', 'Simdi', 'Gelecek']:
    folder = os.path.join(klasik_base, pozisyon)
    klasik_tepki[pozisyon.lower()] = {}
    for fname in os.listdir(folder):
        if not fname.endswith('Tepki.asset'):
            continue
        key = fname[:-len('Tepki.asset')].lower()
        text = parse_aciklama(os.path.join(folder, fname))
        if text:
            klasik_tepki[pozisyon.lower()][key] = text

for poz, cards in klasik_tepki.items():
    print(f"Klasik tepki [{poz}]: {len(cards)} kart")

with open('C:/src/magnus_app/assets/data/tarot_klasik_tepki.json', 'w', encoding='utf-8') as f:
    json.dump(klasik_tepki, f, ensure_ascii=False, indent=2)

print("Bitti!")
