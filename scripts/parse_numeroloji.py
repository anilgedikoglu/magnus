"""
Numeroloji Unity .asset dosyalarını JSON'a dönüştürür.
Kaynak: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Numeroloji\Rapor
Çıktı:  C:\src\magnus_app\assets\data\numeroloji.json

Yapı:
  GENEL / BUGUN / BUYIL
    → 7 bölüm klasörü (ifadesayisi, ruhsayisi, ...)
      → 9 sayı klasörü (1-9)
        → tek .asset dosyası
"""

import os, sys, re, json, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

BASE = r"C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Numeroloji\Rapor"
OUT  = r"C:\src\magnus_app\assets\data\numeroloji.json"

# Bölüm klasör adı → JSON key (sıra önemli)
SECTION_KEYS = {
    '1ifadesayisi': 'ifadesayisi',
    '2ruhsayisi':   'ruhsayisi',
    '3yasamyolu':   'yasamyolusayisi',
    '4sessizbenlik':'sessizbenliksayisi',
    '5olgunluk':    'olgunluksayisi',
    '6dogumgunu':   'dogumgunusayisi',
    '7karmikborc':  'karmikborc',
}

TYPE_KEYS = {
    'GENEL': 'genel',
    'BUGUN': 'bugun',
    'BUYIL': 'yil',
}


def decode_escape(s):
    """\\uXXXX, \\xXX, \\n, \\" gibi escape'leri çöz (regex olmadan)."""
    result = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i+1]
            if nxt == 'n':
                result.append('\n'); i += 2
            elif nxt == '"':
                result.append('"'); i += 2
            elif nxt == '\\':
                result.append('\\'); i += 2
            elif nxt == 'u' and i + 5 < len(s):
                hex4 = s[i+2:i+6]
                if all(c in '0123456789abcdefABCDEF' for c in hex4):
                    result.append(chr(int(hex4, 16))); i += 6
                else:
                    result.append(s[i]); i += 1
            elif nxt == 'x' and i + 3 < len(s):
                hex2 = s[i+2:i+4]
                if all(c in '0123456789abcdefABCDEF' for c in hex2):
                    result.append(chr(int(hex2, 16))); i += 4
                else:
                    result.append(s[i]); i += 1
            else:
                result.append(s[i]); i += 1
        else:
            result.append(s[i]); i += 1
    return ''.join(result)


def extract_aciklama(content):
    """aciklama: bloğundan tek metin (liste maddelerini birleştir)."""
    # aciklama: ... aciklamaEng: arasındaki bloğu al
    m = re.search(r'aciklama:(.*?)(?:aciklamaEng:|$)', content, re.DOTALL | re.IGNORECASE)
    if not m:
        return ''
    block = m.group(1)

    # YAML liste maddeleri: - "..." veya - ''...''
    items = re.findall(r'- "([^"]*)"', block)
    if not items:
        items = re.findall(r"- '([^']*)'", block)

    texts = []
    for item in items:
        t = decode_escape(item).strip()
        # YAML satır devamlılığı: gerçek newline + boşluklar = boşluk
        t = re.sub(r'\n[ \t]+', ' ', t)
        # 3+ boş satır → 2
        t = re.sub(r'\n{3,}', '\n\n', t)
        # || eski sayfa ayracı → çift satır
        t = t.replace('||', '\n\n')
        t = t.strip()
        if t:
            texts.append(t)

    return '\n\n'.join(texts)


def parse_asset(filepath):
    with open(filepath, 'rb') as f:
        raw = f.read()
    content = raw.decode('utf-8', errors='replace')
    return extract_aciklama(content)


def get_section_key(folder_name):
    """Klasör adının başına göre JSON key döndür."""
    lower = folder_name.lower()
    for prefix, key in SECTION_KEYS.items():
        if lower.startswith(prefix):
            return key
    return None


def parse_type(type_dir):
    """Bir rapor türünün (GENEL/BUGUN/BUYIL) 7 bölümünü parse eder.
    Döner: {section_key: {1: 'metin', 2: 'metin', ..., 9: 'metin'}}
    """
    result = {}
    for section_folder in sorted(os.listdir(type_dir)):
        section_path = os.path.join(type_dir, section_folder)
        if not os.path.isdir(section_path):
            continue
        sec_key = get_section_key(section_folder)
        if not sec_key:
            print(f"  ATLA (eşleşme yok): {section_folder}")
            continue

        sec_data = {}
        for num_folder in sorted(os.listdir(section_path)):
            num_path = os.path.join(section_path, num_folder)
            if not os.path.isdir(num_path):
                continue
            # Klasör adının başındaki rakamı al (1-9)
            m = re.match(r'^(\d)', num_folder)
            if not m:
                continue
            num = int(m.group(1))
            if num < 1 or num > 9:
                continue

            # İçindeki tek .asset dosyasını bul
            assets = [f for f in os.listdir(num_path) if f.endswith('.asset')]
            if not assets:
                print(f"  UYARI: .asset yok → {num_path}")
                continue

            asset_path = os.path.join(num_path, assets[0])
            metin = parse_asset(asset_path)
            if not metin:
                print(f"  UYARI: metin boş → {asset_path}")
            sec_data[str(num)] = metin

        result[sec_key] = sec_data
        print(f"  {sec_key}: {len(sec_data)} sayı")
    return result


def main():
    output = {}
    for type_folder, type_key in TYPE_KEYS.items():
        type_dir = os.path.join(BASE, type_folder)
        if not os.path.isdir(type_dir):
            print(f"HATA: klasör yok → {type_dir}")
            continue
        print(f"\n[{type_folder}]")
        output[type_key] = parse_type(type_dir)

    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    # Özet
    total = sum(
        len(v)
        for t in output.values()
        for v in t.values()
    )
    print(f"\n✓ {OUT}")
    print(f"  3 tür × 7 bölüm × 9 sayı = {total} metin girişi (beklenen 189)")


if __name__ == '__main__':
    main()
