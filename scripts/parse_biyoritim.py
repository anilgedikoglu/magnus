#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, json, re, sys

BASE = r'C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Biyoritim'
OUT  = r'C:\src\magnus_app\assets\data\biyoritim.json'

def decode_yaml_str(s):
    result = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == chr(92) and i + 1 < len(s):  # backslash
            nc = s[i+1]
            if nc == 'u' and i + 5 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+6], 16)))
                    i += 6
                    continue
                except: pass
            elif nc == 'x' and i + 3 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+4], 16)))
                    i += 4
                    continue
                except: pass
            elif nc == 'n':
                result.append('\n')
                i += 2
                continue
            elif nc == '"':
                result.append('"')
                i += 2
                continue
            elif nc == chr(92):
                result.append(chr(92))
                i += 2
                continue
        result.append(c)
        i += 1
    return ''.join(result)

def extract_from_asset(filepath):
    with open(filepath, encoding='utf-8', errors='replace') as f:
        raw = f.read()

    # --- aciklama block ---
    aciklama_match = re.search(r'^  aciklama:\n(.*?)^  aciklamaEng:', raw, re.MULTILINE | re.DOTALL)
    if not aciklama_match:
        return [], []
    aciklama_block = aciklama_match.group(1)

    # --- kosullar ---
    kosullar = []
    dv_match = re.search(r'gerekliDegiskenler:\n(.*?)(?:\n  [a-zA-Z]|\Z)', raw, re.DOTALL)
    if dv_match:
        block = dv_match.group(1)
        entries = re.findall(r'degiskenAdi:\s*(\S+).*?degiskenDegeri:\s*(\S+)', block, re.DOTALL)
        for adi, degeri in entries:
            adi = adi.strip()
            degeri = degeri.strip()
            if adi not in ('mod', 'yasmin', 'yasmax'):
                kosullar.append({'degisken': adi, 'deger': degeri})

    # --- YAML list items (handle multi-line YAML strings) ---
    # Join continuation lines first
    lines = aciklama_block.split('\n')
    joined_items = []
    current = None
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('- "') or stripped.startswith("- '"):
            if current is not None:
                joined_items.append(current)
            current = stripped[2:].strip()  # remove '- '
        elif current is not None and stripped:
            # continuation
            current = current.rstrip() + ' ' + stripped
        else:
            if current is not None and not stripped:
                pass  # blank line, keep accumulating
    if current is not None:
        joined_items.append(current)

    texts = []
    for item in joined_items:
        # Remove wrapping quotes
        if (item.startswith('"') and item.endswith('"')) or (item.startswith("'") and item.endswith("'")):
            item = item[1:-1]
        decoded = decode_yaml_str(item)

        # Extract from {{barmenu}} JSON
        bm_idx = decoded.find('{{barmenu}}')
        if bm_idx >= 0:
            json_str = decoded[bm_idx + len('{{barmenu}}'):].strip()
            try:
                data = json.loads(json_str)
                for bar in data.get('bars', []):
                    for exp in bar.get('explanations', []):
                        content = exp.get('content', '').strip()
                        if content:
                            texts.append(content)
            except Exception as e:
                # fallback
                texts.append(decoded)
        else:
            texts.append(decoded)

    return texts, kosullar

def load_folder(folder_path):
    """Load all .asset files in folder, return list of {id, metin, kosullar}"""
    entries = []
    files = sorted([f for f in os.listdir(folder_path) if f.endswith('.asset')])
    uid = 1
    for fname in files:
        path = os.path.join(folder_path, fname)
        texts, kosullar = extract_from_asset(path)
        for t in texts:
            t = t.strip()
            if t:
                entries.append({'id': uid, 'metin': t, 'kosullar': kosullar})
                uid += 1
    return entries

def load_ranged_folder(folder_path):
    """Load .asset files with 0-25 / 25-50 / 50-75 / 75-100 prefix."""
    ranges = ['0-25', '25-50', '50-75', '75-100']
    result = {}
    uid_counter = [1]
    for r in ranges:
        entries = []
        files = sorted([f for f in os.listdir(folder_path)
                       if f.startswith(r + ' ') and f.endswith('.asset')])
        for fname in files:
            path = os.path.join(folder_path, fname)
            texts, kosullar = extract_from_asset(path)
            for t in texts:
                t = t.strip()
                if t:
                    entries.append({'id': uid_counter[0], 'metin': t, 'kosullar': kosullar})
                    uid_counter[0] += 1
        result[r] = entries
        print(f'  {os.path.basename(folder_path)} [{r}]: {len(entries)} metin')
    return result

# ── Collect all data ──────────────────────────────────────────────────────────
output = {}

print('B1...')
output['b1'] = load_folder(os.path.join(BASE, 'B1'))
print(f'  B1: {len(output["b1"])} metin')

for key, folder in [
    ('b2a', 'B2Aduygusal'),
    ('b2b', 'B2Bfiziksel'),
    ('b2c', 'B2Centelektuel'),
    ('b3a', 'B3Aasktasans'),
    ('b3b', 'B3Bparadasans'),
]:
    print(f'{folder}...')
    output[key] = load_ranged_folder(os.path.join(BASE, folder))

print('B4Cakra...')
output['b4'] = load_folder(os.path.join(BASE, 'B4Cakra'))
print(f'  B4: {len(output["b4"])} metin')

print('B5CinTakvimi...')
output['b5'] = load_folder(os.path.join(BASE, 'B5CinTakvimi'))
print(f'  B5: {len(output["b5"])} metin')

# ── Write JSON ────────────────────────────────────────────────────────────────
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f'\nTamam! -> {OUT}')

# Stats
for key in ['b1', 'b4', 'b5']:
    print(f'  {key}: {len(output[key])} entries')
for key in ['b2a', 'b2b', 'b2c', 'b3a', 'b3b']:
    total = sum(len(v) for v in output[key].values())
    print(f'  {key}: {total} entries total')
