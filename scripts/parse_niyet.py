# Niyet .asset dosyalarini JSON'a donusturur.
# Kaynak: C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/Niyet/Metinler/
# Cikti:  C:/src/magnus_app/assets/data/niyet.json

import os
import json
import re

SRC_DIR = "C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/Niyet/Metinler"
OUT_FILE = "C:/src/magnus_app/assets/data/niyet.json"


def resolve_yaml_escapes(s):
    # YAML / Unity string icindeki kacis dizilerini karakter dongusuyle cozer.
    # Python 3.14'te regex \u hata verir - dongu kullaniyoruz.
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
                hex4 = s[i + 2: i + 6]
                if all(c in '0123456789abcdefABCDEF' for c in hex4):
                    result.append(chr(int(hex4, 16)))
                    i += 6
                else:
                    result.append(s[i])
                    i += 1
            elif nxt == 'x' and i + 3 < len(s):
                hex2 = s[i + 2: i + 4]
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


def extract_aciklama_block(content):
    # aciklama: blogunu (aciklama: ile aciklamaEng: arasini) ceker,
    # YAML list item satirlarini birlestir ve temizler.
    lines = content.splitlines()

    in_aciklama = False
    raw_lines = []

    for line in lines:
        if line.strip().startswith('aciklama:'):
            in_aciklama = True
            continue
        if in_aciklama:
            # aciklamaEng: veya başka bir üst düzey alan — dur
            if line.startswith('  ') and not line.startswith('   ') and line.strip() and not line.strip().startswith('-'):
                # Başka bir 2-space alan başladı
                break
            if not line.startswith(' ') and line.strip():
                break
            # aciklamaEng geldi mi?
            stripped = line.strip()
            if stripped.startswith('aciklamaEng:'):
                break
            raw_lines.append(line)

    if not raw_lines:
        return ""

    # Tüm satırları birleştir — YAML line continuation
    # YAML'da uzun string satır sonuna " ile bölünür ve devamı boşlukla başlar
    joined = ' '.join(ln.strip() for ln in raw_lines if ln.strip())

    # Liste işaretini kaldır: baştaki "- " veya '- '
    if joined.startswith('- '):
        joined = joined[2:]

    # Başlangıç / bitiş tırnaklarını kaldır
    if (joined.startswith('"') and joined.endswith('"')) or \
       (joined.startswith("'") and joined.endswith("'")):
        joined = joined[1:-1]

    # YAML escape'lerini çöz
    resolved = resolve_yaml_escapes(joined)

    # 3+ boş satırı 2'ye indir, baş/son boşluk temizle
    import re as _re
    resolved = _re.sub(r'\n{3,}', '\n\n', resolved)
    resolved = resolved.strip()

    return resolved


def extract_kosullar(content):
    # gerekliDegiskenler: blogunu okur ve kosullar listesi dondurur.
    # mod=niyet gibi sistem degiskenlerini filtreler.
    lines = content.splitlines()
    in_block = False
    kosullar = []
    current = {}

    for line in lines:
        stripped = line.strip()

        if stripped.startswith('gerekliDegiskenler:') or stripped.startswith('gerekliDegisken:'):
            in_block = True
            continue

        if in_block:
            # Blok bitti mi? (başka bir aynı düzey alan)
            if line.startswith('  ') and not line.startswith('   ') and stripped and not stripped.startswith('-') and not stripped.startswith('degisken'):
                if current:
                    kosullar.append(current)
                    current = {}
                break
            if not line.startswith(' ') and stripped:
                if current:
                    kosullar.append(current)
                    current = {}
                break

            if stripped.startswith('- degiskenAdi:'):
                if current:
                    kosullar.append(current)
                current = {'degisken': stripped.split(':', 1)[1].strip()}
            elif stripped.startswith('degiskenDegeri:'):
                current['deger'] = stripped.split(':', 1)[1].strip()
            elif stripped.startswith('kontrol:'):
                pass  # kullanmıyoruz

    if current and 'degisken' in current:
        kosullar.append(current)

    # "mod: niyet" gibi sistem/dahili değişkenleri filtrele — sadece kullanıcı profil değişkenlerini al
    # (mod, sohbet, vs. sistem değişkenleri — isteğe göre değiştirilebilir)
    USER_VARS = {'medeni_durum', 'meslek', 'cinsiyet', 'yas', 'cocuk', 'egitim',
                 'gelir', 'il', 'ilce', 'din', 'mezhep', 'selamlama'}
    filtered = [k for k in kosullar if k.get('degisken') in USER_VARS]

    return filtered


def natural_sort_key(filename):
    # 'Niyet 12.asset' gibi dosyalari dogal sirayla siralamak icin.
    parts = re.split(r'(\d+)', filename)
    return [int(p) if p.isdigit() else p.lower() for p in parts]


def main():
    files = sorted(
        [f for f in os.listdir(SRC_DIR) if f.endswith('.asset')],
        key=natural_sort_key
    )
    print(f"Toplam .asset dosyası: {len(files)}")

    results = []
    skipped = 0

    for idx, filename in enumerate(files):
        path = os.path.join(SRC_DIR, filename)
        with open(path, encoding='utf-8', errors='replace') as f:
            content = f.read()

        metin = extract_aciklama_block(content)
        if not metin:
            skipped += 1
            print(f"  [ATLANDI] {filename} — aciklama boş")
            continue

        kosullar = extract_kosullar(content)

        entry = {
            "id": len(results) + 1,
            "metin": metin,
            "kosullar": kosullar
        }
        results.append(entry)

    print(f"\nDönüştürülen: {len(results)}, Atlanan: {skipped}")

    output = {"niyet": results}

    with open(OUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"\nJSON yazıldı: {OUT_FILE}")
    print(f"Toplam metin: {len(results)}\n")

    # İlk 3 örnek
    print("=== İlk 3 Örnek ===")
    for entry in results[:3]:
        print(f"\n--- ID {entry['id']} ---")
        print(f"kosullar: {entry['kosullar']}")
        preview = entry['metin'][:200]
        print(f"metin: {preview}{'...' if len(entry['metin']) > 200 else ''}")


if __name__ == '__main__':
    main()
