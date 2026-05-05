"""
Investigates and fixes the suspicious patterns found in:
- biyoritim.json: double-escaped \\u and \\x sequences
- kadercarki_renk.json:  control characters
- tarot_texts.json:  control characters
"""

import os
import json
import re

DATA_DIR = r'C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb\assets\data'


def show_context(text, pattern_pos, window=80):
    start = max(0, pattern_pos - window // 2)
    end = min(len(text), pattern_pos + window // 2)
    excerpt = text[start:end]
    return excerpt


def fix_double_escaped(text):
    """
    Fix double-escaped sequences like \\\\u0131 -> actual char
    and \\\\xE7 -> actual char.
    These are strings where escape sequences were escaped twice.
    e.g. the JSON contains the literal string: \\"kad\\\\u0131n\\"
    which when parsed = \"kad\\u0131n\" = still not the actual char.

    Actually we need to look at the raw JSON to understand the real issue.
    """
    pass


def analyze_biyoritim():
    fpath = os.path.join(DATA_DIR, 'biyoritim.json')
    with open(fpath, 'rb') as f:
        raw = f.read()

    text = raw.decode('utf-8', errors='replace')

    print("=== biyoritim.json analysis ===")
    print(f"File size: {len(raw)} bytes")

    # Find double-escaped sequences
    # Looking for \\\\u or \\\\x patterns in the RAW text
    pos = 0
    found = 0
    while pos < len(text) - 6:
        if text[pos:pos+6] == '\\\\u01':
            print(f"  Double-escaped \\u at pos {pos}: ...{text[max(0,pos-30):pos+40]}...")
            found += 1
            if found > 5:
                print("  (showing first 5 only)")
                break
        pos += 1

    found = 0
    pos = 0
    while pos < len(text) - 4:
        if text[pos:pos+3] == '\\\\x':
            print(f"  Double-escaped \\x at pos {pos}: ...{text[max(0,pos-30):pos+40]}...")
            found += 1
            if found > 5:
                print("  (showing first 5 only)")
                break
        pos += 1

    # Try parsing as JSON to see what the actual string values contain
    try:
        data = json.loads(text)
        # Find the problematic entries
        entries = data.get('biyoritim', [])
        print(f"\n  Total entries: {len(entries)}")
        for e in entries:
            metin = e.get('metin', '')
            if '\\u' in metin or '\\x' in metin:
                print(f"\n  Entry ID {e.get('id')}: Contains literal \\u or \\x in metin")
                print(f"  Metin: {metin[:200]!r}")
    except json.JSONDecodeError as ex:
        print(f"  JSON parse error: {ex}")
    print()


def analyze_kadercarki_renk():
    fpath = os.path.join(DATA_DIR, 'kadercarki_renk.json')
    with open(fpath, 'rb') as f:
        raw = f.read()

    text = raw.decode('utf-8', errors='replace')
    print("=== kadercarki_renk.json analysis ===")
    print(f"File size: {len(raw)} bytes")

    # Look for  (ETX control char)
    pos = 6580
    print(f"  Context around pos 6589: {text[6550:6650]!r}")

    # Check if it's actual  bytes or the literal 6-char sequence
    # In raw bytes,  = 0x03
    if b'\x03' in raw:
        count = raw.count(b'\x03')
        print(f"  Found {count} actual ETX (0x03) bytes in the file")

    # Check for literal 6-char  sequence
    literal_count = text.count('\\u0003')
    print(f"  Found {literal_count} literal '\\\\u0003' sequences in text")

    try:
        data = json.loads(text)
        entries = data.get('kadercarki_renk', data.get('renk', []))
        if not entries:
            # Try to find the key
            print(f"  JSON keys: {list(data.keys())}")
            for k, v in data.items():
                if isinstance(v, list) and len(v) > 0:
                    entries = v
                    break
        print(f"  Total entries: {len(entries)}")
        for e in entries:
            metin = e.get('metin', '')
            if '\x03' in metin or '\\u0003' in metin:
                print(f"  Entry ID {e.get('id')}: ETX chars in metin")
                print(f"  Metin: {metin[:300]!r}")
    except json.JSONDecodeError as ex:
        print(f"  JSON parse error: {ex}")
    print()


def analyze_tarot_texts():
    fpath = os.path.join(DATA_DIR, 'tarot_texts.json')
    with open(fpath, 'rb') as f:
        raw = f.read()

    text = raw.decode('utf-8', errors='replace')
    print("=== tarot_texts.json analysis ===")
    print(f"File size: {len(raw)} bytes")

    # Check for  sequences
    pos = 110972
    print(f"  Context around pos 110972: {text[110900:111050]!r}")
    print(f"  Context around pos 115374: {text[115300:115450]!r}")

    if b'\x03' in raw:
        count = raw.count(b'\x03')
        print(f"  Found {count} actual ETX (0x03) bytes in the file")

    literal_count = text.count('\\u0003')
    print(f"  Found {literal_count} literal '\\\\u0003' sequences in text")

    try:
        data = json.loads(text)
        # Find entries with ETX
        def find_etx(obj, path=""):
            results = []
            if isinstance(obj, dict):
                for k, v in obj.items():
                    results.extend(find_etx(v, f"{path}.{k}"))
            elif isinstance(obj, list):
                for i, v in enumerate(obj):
                    results.extend(find_etx(v, f"{path}[{i}]"))
            elif isinstance(obj, str):
                if '\x03' in obj:
                    results.append((path, obj[:200]))
            return results

        etx_entries = find_etx(data)
        print(f"  Entries with actual ETX char: {len(etx_entries)}")
        for path, val in etx_entries[:3]:
            print(f"  Path: {path}")
            print(f"  Value: {val!r}")
    except json.JSONDecodeError as ex:
        print(f"  JSON parse error: {ex}")
    print()


if __name__ == '__main__':
    analyze_biyoritim()
    analyze_kadercarki_renk()
    analyze_tarot_texts()
