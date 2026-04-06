"""
Extracts and prepares all content data for Magnus Flutter app.
Run: python3 build_data.py
"""
import os, json, re, shutil
from xml.etree import ElementTree as ET

UNITY = "C:/src/magnus/Assets"
FLUTTER = "C:/src/magnus_app"

# ── Helper ─────────────────────────────────────────────────────────────────────

def decode_unity(s):
    result = []
    i = 0
    while i < len(s):
        ch = s[i]
        if ch == chr(92) and i+1 < len(s):  # backslash
            nc = s[i+1]
            if nc == 'u' and i+5 < len(s):
                h = s[i+2:i+6]
                if all(c in '0123456789abcdefABCDEF' for c in h):
                    result.append(chr(int(h, 16))); i += 6; continue
            elif nc == 'x' and i+3 < len(s):
                h = s[i+2:i+4]
                if all(c in '0123456789abcdefABCDEF' for c in h):
                    result.append(chr(int(h, 16))); i += 4; continue
            elif nc == '"': result.append('"'); i += 2; continue
            elif nc == 'n': result.append('\n'); i += 2; continue
            elif nc == chr(92): result.append(chr(92)); i += 2; continue
        result.append(ch); i += 1
    return ''.join(result)

def strip_tags(s):
    return re.sub(r'<[^>]+>', '', s).strip()

def is_valid_text(s):
    bad = ['fileID:', 'degiskenAdi:', 'kontrol:', '{file', 'kazimaTipi']
    for b in bad:
        if b in s:
            return False
    if len(s) < 10:
        return False
    # Always require at least one Turkish character — rejects English texts
    turkish_chars = sum(1 for c in s if c in 'çğıöşüÇĞİÖŞÜ')
    if turkish_chars == 0:
        return False
    return True

def extract_aciklama(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    idx = content.find('  aciklama:\n')
    if idx < 0:
        return []
    # Explicitly stop before aciklamaEng to avoid English texts
    end_idx = content.find('  aciklamaEng:\n', idx)
    block = content[idx + len('  aciklama:\n'): end_idx if end_idx > idx else idx + 50000]
    lines = block.split('\n')
    entries, current = [], None
    for line in lines:
        if line.startswith('  - '):
            if current is not None:
                entries.append(current)
            current = line[4:]
        elif line.startswith('    ') and current is not None:
            current += ' ' + line.strip()
        elif current is not None and line and not line.startswith(' '):
            break
    if current:
        entries.append(current)
    results = []
    for e in entries:
        e = e.strip()
        if e.startswith('"') and e.endswith('"'):
            e = e[1:-1]
        d = strip_tags(decode_unity(e))
        if is_valid_text(d):
            results.append(d)
    return results

def collect_dir(dirpath):
    texts = []
    for fname in sorted(os.listdir(dirpath)):
        if fname.endswith('.asset') and not fname.endswith('.meta'):
            r = extract_aciklama(os.path.join(dirpath, fname))
            texts.extend(r)
    return texts

# ── 1. Özlü Sözler ────────────────────────────────────────────────────────────
print("Extracting özlü sözler...")
ozlu_base = f"{UNITY}/Resources/Editor/OnlineDOSYALAR/AnaMenu2/Ozlusoz/OzluSozler"
ozlu = collect_dir(ozlu_base)
print(f"  -> {len(ozlu)} entries")

# ── 2. Motivasyon ─────────────────────────────────────────────────────────────
print("Extracting motivasyon...")
motiv_base = f"{UNITY}/Resources/Editor/OnlineDOSYALAR/AnaMenu2/Motivasyon/Motivasyonlar"
motiv = collect_dir(motiv_base)
print(f"  -> {len(motiv)} entries")

# ── 3. Olumlamalar ────────────────────────────────────────────────────────────
print("Extracting olumlamalar...")
olum_base = f"{UNITY}/Resources/Editor/OnlineDOSYALAR/AnaMenu2/Olumlama/Olumlamalar"
cat_map = {
    "Olumlamalar": "genel", "bugun": "genel", "hayatta": "genel",
    "kadin": "kadin", "kadin-calisiyor": "kadin", "kadin-evli": "kadin",
    "kadin-iliskisivar": "kadin", "kadin-iliskisiyok": "kadin", "kadin-ogrenci": "kadin",
    "erkek": "erkek", "erkek-evli": "erkek", "erkek-ogrenci": "erkek",
    "evli": "evli", "iliskisivar": "iliskisivar", "iliskisiyok": "iliskisiyok",
    "ogrenci": "ogrenci", "ogrenci-iliskisivar": "ogrenci", "ogrenci-iliskisiyok": "ogrenci",
    "yeniayrilmis": "iliskisiyok", "isariyor": "genel", "lgbt": "genel"
}
olumlama = {k: [] for k in set(cat_map.values())}
for dirpath, _, filenames in os.walk(olum_base):
    cat_dir = os.path.basename(dirpath)
    target = cat_map.get(cat_dir)
    if target is None:
        continue
    for f in sorted(filenames):
        if f.endswith('.asset') and not f.endswith('.meta'):
            r = extract_aciklama(os.path.join(dirpath, f))
            if r:
                olumlama[target].extend(r)
total_olum = sum(len(v) for v in olumlama.values())
print(f"  -> {total_olum} entries across {len(olumlama)} categories")

# ── 4. Coffee fortune from words.xml ─────────────────────────────────────────
print("Parsing words.xml...")
coffee_texts = []
tree = ET.parse(f"{UNITY}/words.xml")
root = tree.getroot()
for table in root.findall('.//table[@name="words"]'):
    metin = table.findtext('column[@name="metin"]')
    iliski = table.findtext('column[@name="iliski"]') or ''
    cinsiyet = table.findtext('column[@name="cinsiyet"]') or ''
    meslek = table.findtext('column[@name="meslek"]') or ''
    status = table.findtext('column[@name="status"]') or '0'
    if status == '1' and metin and len(metin) > 20:
        coffee_texts.append({
            "text": metin,
            "iliski": iliski,
            "cinsiyet": cinsiyet,
            "meslek": meslek
        })
print(f"  -> {len(coffee_texts)} coffee fortune entries")

# ── 5. Save combined JSON ─────────────────────────────────────────────────────
print("Saving JSON files...")
os.makedirs(f"{FLUTTER}/assets/data", exist_ok=True)

with open(f"{FLUTTER}/assets/data/ozlusoz_motivasyon.json", 'w', encoding='utf-8') as f:
    json.dump({"ozlu_sozler": ozlu, "motivasyonlar": motiv, "olumlamalar": olumlama},
              f, ensure_ascii=False, indent=2)

with open(f"{FLUTTER}/assets/data/coffee_words.json", 'w', encoding='utf-8') as f:
    json.dump({"fortunes": coffee_texts}, f, ensure_ascii=False, indent=2)

print(f"  -> Saved ozlusoz_motivasyon.json and coffee_words.json")

# ── 6. Copy key images ────────────────────────────────────────────────────────
print("Copying images...")
img_src = f"{UNITY}/Images"
img_dst = f"{FLUTTER}/assets/images"
os.makedirs(img_dst, exist_ok=True)

copy_list = [
    ("magnusSplashScreenLogo.jpg", "splash_logo.jpg"),
    ("MagnusLogoYazi.png", "magnus_logo.png"),
    ("MagnusLogoYaziPreferredSizeNew.png", "magnus_logo_text.png"),
    ("appLogoCircle64.png", "app_logo_circle.png"),
    ("NewAppIconCircle64.png", "app_icon_circle.png"),
    ("fincan.png", "cup.png"),
    ("cup.png", "cup2.png"),
    ("ArinmaBg.jpg", "arinma_bg.jpg"),
    ("ArinmaBg.jpg", "olumlama_bg.jpg"),
    ("InboxBackgroundTest.jpg", "ozlusoz_bg.jpg"),
    ("ozluSozArkaplan.png", "ozlusoz_bg.png"),
    ("ozluSozIntroBg.jpg", "ozlusoz_intro_bg.jpg"),
    ("MagnusFoto.jpg", "magnus_foto.jpg"),
    ("burclarWheel512.png", "burclar_wheel.png"),
    ("IlkAcilisLogo.jpg", "ilk_acilis_logo.jpg"),
    ("TarotCardWithShadow.png", "tarot_card.png"),
    ("TartKartKapali.jpg", "tarot_card_back.jpg"),
    ("moon-icon.png", "moon_icon.png"),
    ("planetIcon.png", "planet_icon.png"),
    ("ascendentIcon.png", "ascendent_icon.png"),
]

copied = 0
for src_name, dst_name in copy_list:
    src = os.path.join(img_src, src_name)
    dst = os.path.join(img_dst, dst_name)
    if os.path.exists(src):
        shutil.copy2(src, dst)
        copied += 1
    else:
        print(f"  WARNING: {src_name} not found")

print(f"  -> Copied {copied}/{len(copy_list)} images")
print("\nDone!")
