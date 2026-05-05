"""
Fix biyoritim.json kosullar deger/degisken fields:
  - Decode \\xXX sequences → actual chars
  - Decode \\uXXXX sequences → actual chars
  - Strip surrounding double-quotes if present (e.g. "\"çokkötü\"" → "çokkötü")
"""

import os
import json

DATA_DIR = r'C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb\assets\data'


def decode_escape_sequences(s):
    """Decode \\xXX and \\uXXXX sequences in a string."""
    if not s:
        return s
    result = []
    i = 0
    while i < len(s):
        # Check for \\xXX
        if i + 3 < len(s) and s[i] == '\\' and s[i+1] == 'x':
            hex_part = s[i+2:i+4]
            if all(c in '0123456789ABCDEFabcdef' for c in hex_part):
                result.append(chr(int(hex_part, 16)))
                i += 4
                continue
        # Check for \\uXXXX
        if i + 5 < len(s) and s[i] == '\\' and s[i+1] == 'u':
            hex_part = s[i+2:i+6]
            if all(c in '0123456789ABCDEFabcdef' for c in hex_part):
                result.append(chr(int(hex_part, 16)))
                i += 6
                continue
        result.append(s[i])
        i += 1
    return ''.join(result)


def clean_kosul_value(s):
    """Decode escape sequences and strip outer double-quotes."""
    decoded = decode_escape_sequences(s)
    # Strip surrounding quotes if present
    if decoded.startswith('"') and decoded.endswith('"') and len(decoded) >= 2:
        decoded = decoded[1:-1]
    return decoded


def fix_biyoritim():
    fpath = os.path.join(DATA_DIR, 'biyoritim.json')
    with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
        text = f.read()

    data = json.loads(text)

    total_fixed = 0
    for key, entries in data.items():
        if not isinstance(entries, list):
            continue
        for entry in entries:
            kosullar = entry.get('kosullar', [])
            for kosul in kosullar:
                changed = False
                for field in ('deger', 'degisken'):
                    val = kosul.get(field, '')
                    if '\\x' in val or '\\u' in val:
                        new_val = clean_kosul_value(val)
                        if new_val != val:
                            print(f"  Key '{key}' entry {entry.get('id')}: {field}: {val!r} -> {new_val!r}")
                            kosul[field] = new_val
                            total_fixed += 1
                            changed = True

    print(f"\nTotal fields fixed: {total_fixed}")

    if total_fixed > 0:
        out = json.dumps(data, ensure_ascii=False, indent=2)
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(out)
        print("Saved.")

    # Verify: re-read and check
    with open(fpath, 'r', encoding='utf-8') as f:
        verify_data = json.load(f)

    remaining = 0
    for key, entries in verify_data.items():
        if not isinstance(entries, list):
            continue
        for entry in entries:
            for kosul in entry.get('kosullar', []):
                for field in ('deger', 'degisken'):
                    if '\\x' in kosul.get(field, '') or '\\u' in kosul.get(field, ''):
                        remaining += 1
                        print(f"  REMAINING: {kosul.get(field)!r}")

    if remaining == 0:
        print("Verification OK: no remaining \\x or \\u in kosullar values.")
    else:
        print(f"WARNING: {remaining} remaining issues.")


if __name__ == '__main__':
    print("=== Fixing biyoritim.json kosullar values ===")
    fix_biyoritim()
