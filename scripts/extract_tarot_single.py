# Source: C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Tarot\{AskKarti,DilekKarti,SansKarti}
# Output: C:\src\magnus_app\assets\data\tarot_single_texts.json

import os
import json
import re

BACKSLASH = chr(92)


def decode_yaml_escapes(s):
    result = []
    i = 0
    while i < len(s):
        ch = s[i]
        if ch == BACKSLASH and i + 1 < len(s):
            nxt = s[i + 1]
            if nxt == 'n':
                result.append('\n')
                i += 2
            elif nxt == '"':
                result.append('"')
                i += 2
            elif nxt == BACKSLASH:
                result.append(BACKSLASH)
                i += 2
            elif nxt == 'u' and i + 5 < len(s):
                hex_str = s[i + 2:i + 6]
                if all(c in '0123456789abcdefABCDEF' for c in hex_str):
                    result.append(chr(int(hex_str, 16)))
                    i += 6
                else:
                    result.append(ch)
                    i += 1
            elif nxt == 'x' and i + 3 < len(s):
                hex_str = s[i + 2:i + 4]
                if all(c in '0123456789abcdefABCDEF' for c in hex_str):
                    result.append(chr(int(hex_str, 16)))
                    i += 4
                else:
                    result.append(ch)
                    i += 1
            else:
                result.append(ch)
                i += 1
        else:
            result.append(ch)
            i += 1
    return ''.join(result)


def parse_aciklama(content):
    """Parse aciklama block, join YAML continuation lines, decode escapes."""
    lines = content.split('\n')
    in_aciklama = False
    aciklama_raw_lines = []

    for line in lines:
        stripped = line.strip()
        # Detect 'aciklama:' as a top-level key
        if not in_aciklama:
            if stripped == 'aciklama:' or stripped.startswith('aciklama: '):
                key = stripped.split(':')[0]
                if key == 'aciklama':
                    in_aciklama = True
                    rest = stripped[len('aciklama:'):].strip()
                    if rest:
                        aciklama_raw_lines.append(rest)
                    continue
        else:
            # Stop at aciklamaEng: or any new top-level key
            if stripped.startswith('aciklamaEng:'):
                break
            if line and line[0] not in (' ', '\t', '-', '"', "'") and ':' in line and not line[0].isdigit():
                # top-level key — stop
                key_candidate = line.split(':')[0].strip()
                if key_candidate and ' ' not in key_candidate and key_candidate != 'aciklama':
                    break
            aciklama_raw_lines.append(line)

    if not aciklama_raw_lines:
        return ''

    # Join YAML list items — handle '- "text with continuation"'
    joined_parts = []
    current = None

    for line in aciklama_raw_lines:
        stripped = line.strip()
        if stripped.startswith('- '):
            if current is not None:
                joined_parts.append(current)
            current = stripped[2:]  # remove '- '
        elif stripped == '-':
            if current is not None:
                joined_parts.append(current)
            current = ''
        else:
            if current is not None and stripped:
                current = current + ' ' + stripped
            elif current is not None and not stripped:
                current = current + '\n'

    if current is not None:
        joined_parts.append(current)

    raw = '\n'.join(joined_parts)

    # Strip surrounding quotes
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"'):
        raw = raw[1:-1]
    elif raw.startswith("'") and raw.endswith("'"):
        raw = raw[1:-1]

    # Decode escapes
    decoded = decode_yaml_escapes(raw)

    # Clean: reduce 3+ blank lines to 2
    decoded = re.sub(r'\n{3,}', '\n\n', decoded)
    decoded = decoded.strip()

    return decoded


def parse_gerekli_degiskenler(content):
    """Parse gerekliDegiskenler block; skip mod or tarot-related entries."""
    lines = content.split('\n')
    in_block = False
    kosullar = []
    current_cond = {}

    for line in lines:
        stripped = line.strip()
        if not in_block:
            if stripped.startswith('gerekliDegiskenler:'):
                key = stripped.split(':')[0].strip()
                if key == 'gerekliDegiskenler':
                    in_block = True
                    rest = stripped[len('gerekliDegiskenler:'):].strip()
                    if rest == '[]':
                        in_block = False
                    continue
        else:
            # New top-level key stops the block
            if line and line[0] not in (' ', '\t', '-') and stripped and ':' in stripped:
                if current_cond:
                    kosullar.append(current_cond)
                    current_cond = {}
                break

            if 'degiskenAdi:' in stripped and stripped.startswith('-'):
                if current_cond:
                    kosullar.append(current_cond)
                    current_cond = {}
                val = stripped.split('degiskenAdi:')[-1].strip()
                current_cond = {'degisken': val}
            elif stripped.startswith('degiskenDegeri:'):
                val = stripped[len('degiskenDegeri:'):].strip()
                if val.startswith('"') and val.endswith('"'):
                    val = val[1:-1]
                elif val.startswith("'") and val.endswith("'"):
                    val = val[1:-1]
                val = decode_yaml_escapes(val)
                current_cond['deger'] = val

    if current_cond and 'degisken' in current_cond:
        kosullar.append(current_cond)

    # Filter: skip mod or tarot-related
    filtered = []
    for k in kosullar:
        d = k.get('degisken', '')
        v = k.get('deger', '')
        if d == 'mod':
            continue
        if 'tarot' in d.lower():
            continue
        if 'tarot' in v.lower():
            continue
        filtered.append({'degisken': d, 'deger': v})

    return filtered


def main():
    base = r'C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Tarot'
    folders = {
        'ask': os.path.join(base, 'AskKarti'),
        'dilek': os.path.join(base, 'DilekKarti'),
        'sans': os.path.join(base, 'SansKarti'),
    }

    # Content subdirs inside each tarot type folder
    content_subdirs = ['Major', 'Degnek', 'Kilic', 'Kupa', 'Tilsim', 'Tepki']

    results = []
    entry_id = 1
    counts = {}

    for tur, folder in folders.items():
        tur_count = 0
        for subdir in content_subdirs:
            subdir_path = os.path.join(folder, subdir)
            if not os.path.exists(subdir_path):
                continue
            assets = sorted([f for f in os.listdir(subdir_path) if f.endswith('.asset')])
            for asset_file in assets:
                asset_path = os.path.join(subdir_path, asset_file)
                kart_name = asset_file.replace('.asset', '')
                with open(asset_path, encoding='utf-8', errors='replace') as fh:
                    content = fh.read()
                metin = parse_aciklama(content)
                if not metin:
                    print(f'  [SKIP empty metin] {tur}/{subdir}/{asset_file}')
                    continue
                kosullar = parse_gerekli_degiskenler(content)
                results.append({
                    'id': entry_id,
                    'tur': tur,
                    'kart': kart_name,
                    'metin': metin,
                    'kosullar': kosullar,
                })
                entry_id += 1
                tur_count += 1
        counts[tur] = tur_count
        print(f'{tur}: {tur_count} entries')

    print(f'Total: {sum(counts.values())} entries')

    # Show 3 samples
    for sample in results[:3]:
        print(f'\n--- Sample: id={sample["id"]} tur={sample["tur"]} kart={sample["kart"]} ---')
        print(f'  metin (first 300): {sample["metin"][:300]}')
        print(f'  kosullar: {sample["kosullar"]}')

    # Save
    out_path = r'C:\src\magnus_app\assets\data\tarot_single_texts.json'
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    output = {'tarot_single_metinleri': results}
    with open(out_path, 'w', encoding='utf-8') as fh:
        json.dump(output, fh, ensure_ascii=False, indent=2)
    print(f'\nSaved to: {out_path}')
    print(f'File size: {os.path.getsize(out_path):,} bytes')


if __name__ == '__main__':
    main()
