import os, re, json, sys

src = r"C:\src\magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\JaponFali\Metinler"
out = r"C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb\assets\data\japonfali.json"

BS = chr(92)

def decode_escapes(s):
    result = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == BS and i+1 < len(s):
            nx = s[i+1]
            if nx == 'n':   result.append('\n'); i += 2
            elif nx == 't': result.append('\t'); i += 2
            elif nx == '"': result.append('"'); i += 2
            elif nx == BS:  result.append(BS); i += 2
            elif nx == 'x' and i+3 < len(s):
                try:    result.append(chr(int(s[i+2:i+4], 16))); i += 4
                except: result.append(c); i += 1
            elif nx == 'u' and i+5 < len(s):
                try:    result.append(chr(int(s[i+2:i+6], 16))); i += 6
                except: result.append(c); i += 1
            else: result.append(c); i += 1
        else: result.append(c); i += 1
    return ''.join(result)

files = sorted([f for f in os.listdir(src) if f.endswith('.asset') and not f.endswith('.meta')])
print(f"Toplam dosya: {len(files)}")

metinler = []
idx = 1

for fname in files:
    fpath = os.path.join(src, fname)
    with open(fpath, 'r', encoding='utf-8', errors='replace') as fh:
        content = fh.read()

    # aciklama: ile aciklamaEng: arasındaki bloğu al
    ac_match = re.search(r'aciklama:\s*\n([\s\S]*?)aciklamaEng:', content)
    if not ac_match:
        # aciklamaEng yoksa, aciklama: den sonraki YAML key'e kadar al
        ac_match = re.search(r'aciklama:\s*\n([\s\S]*?)\n  \w+:', content)
    if not ac_match:
        print(f"  ATLANDI: {fname}")
        continue

    block = ac_match.group(1)

    # Büyük string içindeki tüm içeriği al: ilk " ve son " arasını bul
    # YAML multiline string: - "......."
    m = re.search(r'-\s*"([\s\S]+?)"\s*$', block, re.MULTILINE)
    if not m:
        # Son satıra kadar dene
        m = re.search(r'-\s*"([\s\S]+)"', block)
    if not m:
        print(f"  STR bulunamadi: {fname}")
        continue

    raw = m.group(1)
    # YAML satır devamlılığı birleştir
    raw = re.sub(r'\n[ \t]+', ' ', raw)
    metin = decode_escapes(raw)
    metin = re.sub(r'\n{3,}', '\n\n', metin)
    metin = metin.strip()

    if len(metin) < 40:
        print(f"  KISA ({idx}): {metin[:60]}")
        continue

    son = metin.rstrip()[-1] if metin.rstrip() else ''
    if son not in {'.', '!', '?', chr(8230), '"', "'", ')'}:
        sys.stdout.buffer.write(f"  UYARI [{idx}] son={repr(son)}: ...{metin[-60:]}\n".encode('utf-8', errors='replace'))

    metinler.append({"id": idx, "metin": metin, "kosullar": []})
    idx += 1

print(f"\nToplam metin: {len(metinler)}")
if metinler:
    sys.stdout.buffer.write(f"Ilk metin: {metinler[0]['metin'][:120]}\n".encode('utf-8', errors='replace'))
    sys.stdout.buffer.write(f"Son metin: {metinler[-1]['metin'][-80:]}\n".encode('utf-8', errors='replace'))

with open(out, 'w', encoding='utf-8') as fh:
    json.dump({"japonfali": metinler}, fh, ensure_ascii=False, indent=2)
print(f"\nKaydedildi: {out}")
