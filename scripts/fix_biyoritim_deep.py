"""
Deep fix for biyoritim.json: decode all escape sequences in ALL kosullar
deger/degisken values recursively, regardless of nesting depth.
"""

import json, os

DATA_DIR = r'C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb\assets\data'


def decode_escape_sequences(s):
    """Decode literal backslash-xXX and backslash-uXXXX in a string."""
    if not s:
        return s
    bs = chr(92)
    hexchars = set('0123456789ABCDEFabcdef')
    result = []
    i = 0
    while i < len(s):
        if i + 3 < len(s) and s[i] == bs and s[i+1] == 'x':
            h = s[i+2:i+4]
            if all(c in hexchars for c in h):
                result.append(chr(int(h, 16)))
                i += 4
                continue
        if i + 5 < len(s) and s[i] == bs and s[i+1] == 'u':
            h = s[i+2:i+6]
            if all(c in hexchars for c in h):
                result.append(chr(int(h, 16)))
                i += 6
                continue
        result.append(s[i])
        i += 1
    return ''.join(result)


def clean_value(s):
    """Decode escapes and strip surrounding double-quotes."""
    decoded = decode_escape_sequences(s)
    # Strip surrounding quotes if present
    while decoded.startswith('"') or decoded.endswith('"'):
        new = decoded.strip('"')
        if new == decoded:
            break
        decoded = new
    return decoded


def fix_kosullar_recursive(obj, fixed_list):
    """Recursively walk all objects and fix kosullar deger/degisken values."""
    bs = chr(92)
    if isinstance(obj, dict):
        # If this object has 'kosullar', fix it
        if 'kosullar' in obj and isinstance(obj['kosullar'], list):
            for k in obj['kosullar']:
                if isinstance(k, dict):
                    for field in ('deger', 'degisken'):
                        v = k.get(field, '')
                        if isinstance(v, str) and (bs in v or v.startswith('"') or v.endswith('"')):
                            new_v = clean_value(v)
                            if new_v != v:
                                fixed_list.append(f"{field}: {v!r} -> {new_v!r}")
                                k[field] = new_v
        # Recurse into all values
        for key, val in obj.items():
            fix_kosullar_recursive(val, fixed_list)
    elif isinstance(obj, list):
        for item in obj:
            fix_kosullar_recursive(item, fixed_list)


def main():
    fpath = os.path.join(DATA_DIR, 'biyoritim.json')
    with open(fpath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    fixed_list = []
    fix_kosullar_recursive(data, fixed_list)

    print(f"Fixed {len(fixed_list)} values:")
    for item in fixed_list[:30]:
        print(f"  {item}")
    if len(fixed_list) > 30:
        print(f"  ... and {len(fixed_list) - 30} more")

    if fixed_list:
        with open(fpath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("Saved.")

    # Verify
    with open(fpath, 'r', encoding='utf-8') as f:
        data2 = json.load(f)

    remaining = []
    def check_remaining(obj, path=''):
        bs = chr(92)
        if isinstance(obj, dict):
            for k, v in obj.items():
                check_remaining(v, f'{path}.{k}')
        elif isinstance(obj, list):
            for i, v in enumerate(obj):
                check_remaining(v, f'{path}[{i}]')
        elif isinstance(obj, str):
            if (bs + 'x') in obj or (bs + 'u') in obj or obj.startswith('"') or obj.endswith('"'):
                remaining.append((path, obj[:100]))

    check_remaining(data2)
    if remaining:
        print(f"\nWARNING: {len(remaining)} remaining issues:")
        for path, val in remaining[:10]:
            print(f"  {path}: {val!r}")
    else:
        print("\nVerification OK: no remaining escape sequences or stray quotes.")


if __name__ == '__main__':
    main()
