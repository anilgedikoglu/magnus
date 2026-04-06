import os, json

def decode_unity(s):
    # Manual decode of Unity YAML unicode escapes
    result = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i+1 < len(s):
            next_c = s[i+1]
            if next_c == 'u' and i+5 < len(s):
                hex_str = s[i+2:i+6]
                if all(c in '0123456789abcdefABCDEF' for c in hex_str):
                    result.append(chr(int(hex_str, 16)))
                    i += 6
                    continue
            elif next_c == 'x' and i+3 < len(s):
                hex_str = s[i+2:i+4]
                if all(c in '0123456789abcdefABCDEF' for c in hex_str):
                    result.append(chr(int(hex_str, 16)))
                    i += 4
                    continue
            elif next_c == '"':
                result.append('"')
                i += 2
                continue
            elif next_c == 'n':
                result.append('\n')
                i += 2
                continue
            elif next_c == '\\':
                result.append('\\')
                i += 2
                continue
        result.append(s[i])
        i += 1
    return ''.join(result)

def extract_aciklama(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find aciklama block
    idx = content.find('  aciklama:\n')
    if idx < 0:
        return None

    block_start = idx + len('  aciklama:\n')
    block_end = block_start
    lines = content[block_start:].split('\n')

    entries, current = [], None
    for line in lines:
        if line.startswith('  - '):
            if current is not None:
                entries.append(current)
            current = line[4:]
        elif line.startswith('    ') and current is not None:
            current += ' ' + line.strip()
        elif current is not None and not line.startswith(' '):
            break
    if current:
        entries.append(current)

    results = []
    for e in entries:
        e = e.strip()
        if e.startswith('"') and e.endswith('"'):
            e = e[1:-1]
        d = decode_unity(e)
        if len(d) > 5:
            results.append(d)
    return results

# Extract özlü sözler
base1 = "C:/src/magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/Ozlusoz/OzluSozler"
base2 = "C:/src/magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/Motivasyon/Motivasyonlar"

ozlu = []
for f in sorted(os.listdir(base1)):
    if f.endswith('.asset') and not f.endswith('.meta'):
        r = extract_aciklama(os.path.join(base1, f))
        if r: ozlu.extend(r)

motiv = []
for f in sorted(os.listdir(base2)):
    if f.endswith('.asset') and not f.endswith('.meta'):
        r = extract_aciklama(os.path.join(base2, f))
        if r: motiv.extend(r)

# Extract olumlamalar - walk all subdirs
base3 = "C:/src/magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/Olumlama/Olumlamalar"
olumlama_by_category = {}
for dirpath, dirnames, filenames in os.walk(base3):
    cat = os.path.basename(dirpath)
    texts = []
    for f in sorted(filenames):
        if f.endswith('.asset') and not f.endswith('.meta'):
            r = extract_aciklama(os.path.join(dirpath, f))
            if r: texts.extend(r)
    if texts:
        olumlama_by_category[cat] = texts

out = {
    "ozlu_sozler": ozlu,
    "motivasyonlar": motiv,
    "olumlamalar": olumlama_by_category
}
with open("C:/src/magnus_app/assets/data/ozlusoz_motivasyon.json", 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

print(f"Ozlu: {len(ozlu)}, Motiv: {len(motiv)}, Olumlama cats: {len(olumlama_by_category)}")
print("Olumlama keys:", list(olumlama_by_category.keys())[:10])
# Write readable sample
with open("C:/src/magnus_app/extract_sample.txt", 'w', encoding='utf-8') as f:
    f.write("=== OZLU SOZLER (first 3) ===\n")
    for s in ozlu[:3]:
        f.write(s + "\n---\n")
    f.write("\n=== MOTIVASYONLAR (first 3) ===\n")
    for s in motiv[:3]:
        f.write(s + "\n---\n")
    f.write("\n=== OLUMLAMALAR KEYS ===\n")
    for k,v in list(olumlama_by_category.items())[:5]:
        f.write(f"{k}: {v[0][:100]}\n---\n")
print("Sample written to extract_sample.txt")
