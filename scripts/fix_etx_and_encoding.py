"""
Fixes:
1. kadercarki_renk.json and tarot_texts.json:
   - ETX (0x03) control chars in metin fields → strip them
   - Encoding issues (file may be Windows-1252, not UTF-8)

2. biyoritim.json:
   - Double-escaped \\x sequences in kosullar deger/degisken fields
   - The JSON structure uses nested escaping — need to understand and fix
"""

import os
import json

DATA_DIR = r'C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb\assets\data'


def try_decode(raw_bytes):
    """Try multiple encodings to decode bytes."""
    for enc in ('utf-8', 'utf-8-sig', 'windows-1252', 'latin-1'):
        try:
            return raw_bytes.decode(enc), enc
        except UnicodeDecodeError:
            continue
    return raw_bytes.decode('latin-1'), 'latin-1'


def strip_etx(text):
    """Remove ETX (0x03) control characters."""
    return text.replace('\x03', '')


def fix_kadercarki_renk():
    fpath = os.path.join(DATA_DIR, 'kadercarki_renk.json')
    with open(fpath, 'rb') as f:
        raw = f.read()

    text, enc = try_decode(raw)
    print(f"kadercarki_renk.json: decoded as {enc}")

    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        print(f"  JSON parse error with {enc}: {e}")
        # Try re-encoding
        for enc2 in ('utf-8', 'windows-1252', 'latin-1'):
            try:
                text2 = raw.decode(enc2)
                data = json.loads(text2)
                text = text2
                print(f"  Succeeded with {enc2}")
                break
            except Exception:
                continue
        else:
            print("  Could not parse JSON!")
            return False

    # Find the main list key
    main_key = None
    for k, v in data.items():
        if isinstance(v, list):
            main_key = k
            break

    if not main_key:
        print("  No list key found!")
        return False

    entries = data[main_key]
    fixed_count = 0
    for e in entries:
        metin = e.get('metin', '')
        if '\x03' in metin:
            new_metin = strip_etx(metin)
            print(f"  Entry {e.get('id')}: stripped {metin.count(chr(3))} ETX chars")
            print(f"    Before: ...{metin[:100]!r}...")
            print(f"    After:  ...{new_metin[:100]!r}...")
            e['metin'] = new_metin
            fixed_count += 1

    print(f"  Fixed {fixed_count} entries")

    if fixed_count > 0:
        out = json.dumps(data, ensure_ascii=False, indent=2)
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(out)
        print(f"  Saved (UTF-8)")
    print()
    return True


def fix_tarot_texts():
    fpath = os.path.join(DATA_DIR, 'tarot_texts.json')
    with open(fpath, 'rb') as f:
        raw = f.read()

    text, enc = try_decode(raw)
    print(f"tarot_texts.json: decoded as {enc}")

    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        print(f"  JSON parse error with {enc}: {e}")
        return False

    def fix_obj(obj):
        count = 0
        if isinstance(obj, dict):
            for k in list(obj.keys()):
                if isinstance(obj[k], str) and '\x03' in obj[k]:
                    obj[k] = strip_etx(obj[k])
                    count += 1
                else:
                    count += fix_obj(obj[k])
        elif isinstance(obj, list):
            for item in obj:
                count += fix_obj(item)
        return count

    fixed_count = fix_obj(data)
    print(f"  Fixed {fixed_count} strings with ETX chars")

    if fixed_count > 0:
        out = json.dumps(data, ensure_ascii=False, indent=2)
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(out)
        print(f"  Saved (UTF-8)")
    print()
    return True


def analyze_biyoritim():
    """
    Analyze biyoritim.json's double-escaped sequences.
    These are in kosullar values, not in display text.
    """
    fpath = os.path.join(DATA_DIR, 'biyoritim.json')
    with open(fpath, 'rb') as f:
        raw = f.read()

    text, enc = try_decode(raw)
    print(f"biyoritim.json: decoded as {enc}")
    print(f"  File size: {len(raw)} bytes")

    # Find the biyoritim key
    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        print(f"  JSON parse error: {e}")
        return

    main_key = None
    for k, v in data.items():
        if isinstance(v, list):
            main_key = k
            print(f"  Main key: {k}, entries: {len(v)}")
            break

    if not main_key:
        print(f"  Keys: {list(data.keys())}")
        return

    # Check kosullar values for double-escaped sequences
    entries = data[main_key]
    print(f"  Total entries: {len(entries)}")

    double_escaped = []
    for e in entries:
        kosullar = e.get('kosullar', [])
        for k in kosullar:
            deger = k.get('deger', '')
            degisken = k.get('degisken', '')
            if '\\x' in deger or '\\u' in deger or '\\x' in degisken or '\\u' in degisken:
                double_escaped.append({
                    'id': e.get('id'),
                    'degisken': degisken,
                    'deger': deger
                })

    print(f"  Entries with double-escaped kosullar values: {len(double_escaped)}")
    for item in double_escaped[:10]:
        print(f"    ID {item['id']}: degisken={item['degisken']!r}, deger={item['deger']!r}")

    if double_escaped:
        print()
        print("  These are kosullar filter values, not display text.")
        print("  The double-escaped sequences may be intentional from the Unity import.")
        print("  Checking if we should decode them...")

        # The values look like: "\"\\xE7okk\\xF6t\\xFC\""
        # After JSON parsing, these become: "\"\\xE7okk\\xF6t\\xFC\""
        # Actually in memory they are: "\çokköt\xFC" ???
        # Let's decode what \\xE7 = ç, \\xF6 = ö, \\xFC = ü
        # So "\\xE7okk\\xF6t\\xFC" → "çokkötü"
        # But the outer \" makes it: "\"çokkötü\""

        # Let's do the fix: decode \\xXX sequences in deger/degisken
        def decode_hex_escapes(s):
            """Decode \\xXX sequences in a string."""
            result = []
            i = 0
            while i < len(s):
                if i + 3 < len(s) and s[i] == '\\' and s[i+1] == 'x':
                    hex_part = s[i+2:i+4]
                    if all(c in '0123456789ABCDEFabcdef' for c in hex_part):
                        result.append(chr(int(hex_part, 16)))
                        i += 4
                        continue
                if i + 5 < len(s) and s[i] == '\\' and s[i+1] == 'u':
                    hex_part = s[i+2:i+6]
                    if all(c in '0123456789ABCDEFabcdef' for c in hex_part):
                        result.append(chr(int(hex_part, 16)))
                        i += 6
                        continue
                result.append(s[i])
                i += 1
            return ''.join(result)

        # Show what decoding would give
        print()
        print("  What decoding \\x sequences would give:")
        for item in double_escaped[:5]:
            d_decoded = decode_hex_escapes(item['deger'])
            dg_decoded = decode_hex_escapes(item['degisken'])
            print(f"    ID {item['id']}:")
            print(f"      degisken: {item['degisken']!r} → {dg_decoded!r}")
            print(f"      deger:    {item['deger']!r} → {d_decoded!r}")

        # Check if the outer quotes should also be stripped
        sample_deger = double_escaped[0]['deger']
        decoded = decode_hex_escapes(sample_deger)
        print()
        print(f"  Sample decoded: {sample_deger!r} → {decoded!r}")
        if decoded.startswith('"') and decoded.endswith('"'):
            print("  → Has outer quotes that should be stripped")
            decoded_stripped = decoded[1:-1]
            print(f"  → After stripping: {decoded_stripped!r}")
    print()


if __name__ == '__main__':
    fix_kadercarki_renk()
    fix_tarot_texts()
    analyze_biyoritim()
