"""
Deeper investigation of biyoritim.json structure and kadercarki_renk.json encoding issues.
"""

import os
import json

DATA_DIR = r'C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb\assets\data'


def check_biyoritim():
    fpath = os.path.join(DATA_DIR, 'biyoritim.json')
    with open(fpath, 'rb') as f:
        raw = f.read()

    text = raw.decode('utf-8', errors='replace')
    print("=== biyoritim.json deeper check ===")
    print(f"File size: {len(raw)} bytes")

    # Show start of file to understand structure
    print(f"\nFirst 500 chars:\n{text[:500]}")
    print(f"\n...\n")

    # Count occurrences of double-escaped sequences
    dbl_x = 0
    i = 0
    while i < len(text) - 3:
        if text[i] == '\\' and text[i+1] == 'x':
            dbl_x += 1
            i += 2
        else:
            i += 1
    print(f"Occurrences of \\x in parsed text: {dbl_x}")

    # Find raw bytes around pos 8314 (the suspicious \\x location)
    # Show the raw bytes
    print(f"\nRaw context around byte 8314:")
    seg = raw[8250:8400]
    print(f"  Hex: {seg.hex()}")
    try:
        print(f"  UTF-8: {seg.decode('utf-8', errors='replace')}")
    except:
        pass

    # Try to parse JSON
    try:
        data = json.loads(text)
        print(f"\nJSON keys: {list(data.keys())}")

        # The 'biyoritim' key returned empty list — let's see what b1 contains
        for k, v in data.items():
            if isinstance(v, list):
                print(f"Key '{k}': list with {len(v)} entries")
                if len(v) > 0:
                    print(f"  First entry keys: {list(v[0].keys()) if isinstance(v[0], dict) else type(v[0])}")
                    # Show first entry
                    print(f"  Entry 0: {json.dumps(v[0], ensure_ascii=False)[:300]}")
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")

    # Check raw for \\\\x pattern (double-escaped in raw bytes)
    raw_str = raw.decode('latin-1')  # lossless decode
    count_dbl = raw_str.count('\\\\x')
    print(f"\nDouble-escaped \\\\x count in raw (latin-1): {count_dbl}")

    count_sgl = raw_str.count('\\x')
    print(f"Single-escaped \\x count in raw (latin-1): {count_sgl}")

    # Find all \\x occurrences in raw
    pos = 0
    found = 0
    while found < 5:
        idx = raw_str.find('\\x', pos)
        if idx == -1:
            break
        print(f"\n  \\x at raw pos {idx}: ...{raw_str[max(0,idx-50):idx+50]}...")
        pos = idx + 1
        found += 1


def check_kadercarki_renk():
    fpath = os.path.join(DATA_DIR, 'kadercarki_renk.json')
    with open(fpath, 'rb') as f:
        raw = f.read()

    print("\n=== kadercarki_renk.json encoding check ===")
    # Check if it's valid UTF-8
    try:
        raw.decode('utf-8')
        print("File is valid UTF-8")
    except UnicodeDecodeError as e:
        print(f"NOT valid UTF-8: {e}")

    # Find replacement chars in the parsed text
    text = raw.decode('utf-8', errors='replace')
    replacement_count = text.count('�')
    print(f"Replacement chars (U+FFFD) in UTF-8 decode: {replacement_count}")

    if replacement_count > 0:
        # Find and show them
        idx = text.find('�')
        print(f"  First at pos {idx}: ...{text[max(0,idx-30):idx+50]!r}...")

    # Load the json after our ETX fix
    try:
        data = json.loads(text)
        for k, v in data.items():
            if isinstance(v, list):
                print(f"\nKey '{k}': {len(v)} entries")
                # Find entry 14
                for e in v:
                    if e.get('id') == 14:
                        print(f"Entry 14 metin: {e['metin'][:200]!r}")
                        break
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")

    # Check if the file previously had windows-1252 chars
    # by trying to decode as windows-1252
    try:
        text_1252 = raw.decode('windows-1252')
        repl_count = text_1252.count('�')
        print(f"\nAs windows-1252: {repl_count} replacement chars")
    except Exception:
        pass

    # Show the raw bytes around entry 14's problematic section
    idx_bytes = raw.find(b'\x03')
    if idx_bytes == -1:
        print("No \\x03 bytes remaining (already fixed)")
    else:
        print(f"Still has \\x03 at byte {idx_bytes}: {raw[max(0,idx_bytes-20):idx_bytes+20].hex()}")


if __name__ == '__main__':
    check_biyoritim()
    check_kadercarki_renk()
