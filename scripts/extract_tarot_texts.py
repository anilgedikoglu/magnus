"""
Tarot .asset dosyalarindan metin cikarip tarot_texts.json'a kaydeder.
Kaynak: C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/Tarot/KlasikTarot/
Cikti:  C:/src/magnus_app/assets/data/tarot_texts.json
"""

import os
import json

BASE_DIR = r"C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Tarot\KlasikTarot"
OUTPUT_PATH = r"C:\src\magnus_app\assets\data\tarot_texts.json"

# Skip variable names that are internal Unity session-tracking, not demographic filters
SKIP_DEGISKEN_ADI = {"mod", "tarot modu"}

# Position folders mapping
POSITION_MAP = {
    "TarGecmis": "gecmis",
    "TarSimdi": "simdi",
    "TarGelecek": "gelecek",
}

# Subfolder prefix → ters flag
def is_ters(subdir_name):
    return subdir_name.startswith("Te")


def decode_unity_escapes(s):
    # Decode backslash-uXXXX, backslash-xXX, backslash-n, backslash-quote char by char (Python 3.14 regex-safe)
    result = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == '\\' and i + 1 < len(s):
            nc = s[i + 1]
            if nc == 'u' and i + 5 < len(s):
                hex_str = s[i+2:i+6]
                if all(h in '0123456789abcdefABCDEF' for h in hex_str):
                    result.append(chr(int(hex_str, 16)))
                    i += 6
                    continue
            if nc == 'x' and i + 3 < len(s):
                hex_str = s[i+2:i+4]
                if all(h in '0123456789abcdefABCDEF' for h in hex_str):
                    result.append(chr(int(hex_str, 16)))
                    i += 4
                    continue
            if nc == 'n':
                result.append('\n')
                i += 2
                continue
            if nc == '"':
                result.append('"')
                i += 2
                continue
            if nc == '\\':
                result.append('\\')
                i += 2
                continue
        result.append(c)
        i += 1
    return ''.join(result)


def parse_aciklama(lines, start_idx):
    """
    Parse aciklama block starting at the line index of 'aciklama:'.
    Collects lines until aciklamaEng: or another top-level key.
    Returns decoded text string.
    """
    collected = []
    i = start_idx + 1
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        # Stop at aciklamaEng or any new top-level key (no leading spaces)
        if stripped.startswith('aciklamaEng:'):
            break
        # Also stop at other top-level keys (not indented)
        if line and line[0] not in (' ', '\t', '-', "'", '"') and ':' in line:
            break
        collected.append(line)
        i += 1

    # Join all collected lines — strip each to collapse YAML continuation indentation
    raw = ' '.join(line.strip() for line in collected if line.strip())

    # The aciklama block is a YAML list with one string item: starts with "- "
    # Strip leading "- "
    raw = raw.strip()
    if raw.startswith('- '):
        raw = raw[2:].strip()

    # Strip surrounding quotes
    if (raw.startswith('"') and raw.endswith('"')) or \
       (raw.startswith("'") and raw.endswith("'")):
        raw = raw[1:-1]

    # Decode escape sequences
    text = decode_unity_escapes(raw)

    # YAML continuation: real newline + spaces → single space
    # (already joined above; handle internal \n sequences)
    # Normalize: 3+ blank lines → 2
    import re
    text = re.sub(r'\n{3,}', '\n\n', text)
    text = text.strip()
    return text


def parse_gerekli_degiskenler(lines, start_idx):
    """
    Parse gerekliDegiskenler block, returning list of {degisken, deger} dicts.
    Skips entries where degiskenAdi is in SKIP_DEGISKEN_ADI.
    """
    kosullar = []
    i = start_idx + 1
    current_adi = None
    current_deger = None

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Stop if we hit a non-indented key or empty structure
        if line and line[0] not in (' ', '\t', '-') and ':' in stripped:
            break

        if stripped.startswith('- degiskenAdi:'):
            # Save previous if valid
            if current_adi and current_adi not in SKIP_DEGISKEN_ADI and current_deger is not None:
                kosullar.append({"degisken": current_adi, "deger": current_deger})
            current_adi = stripped.split(':', 1)[1].strip()
            current_deger = None
        elif stripped.startswith('degiskenAdi:'):
            if current_adi and current_adi not in SKIP_DEGISKEN_ADI and current_deger is not None:
                kosullar.append({"degisken": current_adi, "deger": current_deger})
            current_adi = stripped.split(':', 1)[1].strip()
            current_deger = None
        elif stripped.startswith('degiskenDegeri:'):
            raw_val = stripped.split(':', 1)[1].strip()
            # Strip surrounding quotes if present
            if len(raw_val) >= 2 and raw_val[0] in ('"', "'") and raw_val[-1] == raw_val[0]:
                raw_val = raw_val[1:-1]
            # Decode escape sequences in condition values too
            current_deger = decode_unity_escapes(raw_val)
        i += 1

    # Don't forget the last entry
    if current_adi and current_adi not in SKIP_DEGISKEN_ADI and current_deger is not None:
        kosullar.append({"degisken": current_adi, "deger": current_deger})

    return kosullar


def process_asset_file(filepath, pozisyon, ters, kart_name):
    """Read and parse a single .asset file. Returns dict or None."""
    try:
        with open(filepath, encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"  ERROR reading {filepath}: {e}")
        return None

    metin = None
    kosullar = []

    for idx, line in enumerate(lines):
        stripped = line.strip()
        if stripped == 'aciklama:':
            try:
                metin = parse_aciklama(lines, idx)
            except Exception as e:
                print(f"  ERROR parsing aciklama in {filepath}: {e}")
                metin = None
        elif stripped in ('gerekliDegiskenler:', 'gerekliDegisken:'):
            try:
                kosullar = parse_gerekli_degiskenler(lines, idx)
            except Exception as e:
                print(f"  ERROR parsing degiskenler in {filepath}: {e}")
                kosullar = []

    if not metin:
        return None

    return {
        "pozisyon": pozisyon,
        "kart": kart_name,
        "ters": ters,
        "metin": metin,
        "kosullar": kosullar,
    }


def main():
    all_entries = []
    counts = {"gecmis": 0, "simdi": 0, "gelecek": 0}
    skipped = 0

    for pos_folder, pozisyon in POSITION_MAP.items():
        pos_path = os.path.join(BASE_DIR, pos_folder)
        if not os.path.isdir(pos_path):
            print(f"WARNING: {pos_path} not found, skipping.")
            continue

        subdirs = sorted(os.listdir(pos_path))
        for subdir in subdirs:
            subdir_path = os.path.join(pos_path, subdir)
            if not os.path.isdir(subdir_path):
                continue
            # Skip .meta etc
            ters = is_ters(subdir)
            asset_files = sorted(f for f in os.listdir(subdir_path) if f.endswith('.asset'))

            for asset_file in asset_files:
                kart_name = os.path.splitext(asset_file)[0]
                filepath = os.path.join(subdir_path, asset_file)
                result = process_asset_file(filepath, pozisyon, ters, kart_name)
                if result:
                    all_entries.append(result)
                    counts[pozisyon] += 1
                else:
                    skipped += 1

    # Assign sequential IDs
    for i, entry in enumerate(all_entries, start=1):
        entry["id"] = i

    # Reorder keys for clean output
    output_entries = []
    for e in all_entries:
        output_entries.append({
            "id": e["id"],
            "pozisyon": e["pozisyon"],
            "kart": e["kart"],
            "ters": e["ters"],
            "metin": e["metin"],
            "kosullar": e["kosullar"],
        })

    output = {"tarot_metinleri": output_entries}

    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print("\n=== TAROT EXTRACTION COMPLETE ===")
    print(f"  gecmis : {counts['gecmis']} texts")
    print(f"  simdi  : {counts['simdi']} texts")
    print(f"  gelecek: {counts['gelecek']} texts")
    print(f"  TOTAL  : {sum(counts.values())} texts")
    print(f"  Skipped (no metin): {skipped}")
    print(f"  Saved to: {OUTPUT_PATH}")

    # Show a few sample entries
    print("\n--- Sample entries ---")
    for e in output_entries[:2]:
        preview = e['metin'][:80].replace('\n', ' ')
        print(f"  [{e['id']}] {e['pozisyon']} | {e['kart']} | ters={e['ters']} | kosullar={e['kosullar']}")
        print(f"       metin: {preview}...")


if __name__ == "__main__":
    main()
