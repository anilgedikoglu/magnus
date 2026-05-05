"""Final verification of fixed JSON files."""
import json, os

files = ['biyoritim.json', 'kadercarki_renk.json', 'tarot_texts.json']
DATA_DIR = r'C:\src\magnus_app\.claude\worktrees\exciting-swanson-a016eb\assets\data'

for fname in files:
    fpath = os.path.join(DATA_DIR, fname)
    with open(fpath, 'rb') as f:
        raw = f.read()

    # Check for ETX bytes
    etx_count = raw.count(b'\x03')
    # Check for replacement chars (U+FFFD in UTF-8)
    repl_count = raw.count(b'\xef\xbf\xbd')
    # Verify valid UTF-8
    try:
        text = raw.decode('utf-8')
        utf8_ok = True
    except Exception:
        utf8_ok = False

    # Verify valid JSON
    try:
        data = json.loads(raw.decode('utf-8'))
        json_ok = True
    except Exception as e:
        json_ok = False

    # Check for literal backslash-x in the text (not as Python string, but as actual chars)
    # backslash = chr(92), x = 'x'
    bs = chr(92)
    bx_count = text.count(bs + 'x')
    bu_count = 0
    i = 0
    hexchars = set('0123456789ABCDEFabcdef')
    while i < len(text) - 5:
        if text[i] == bs and text[i+1] == 'u':
            if all(c in hexchars for c in text[i+2:i+6]):
                bu_count += 1
                i += 6
                continue
        i += 1

    print(f'{fname}:')
    print(f'  UTF-8 valid: {utf8_ok}, JSON valid: {json_ok}')
    print(f'  ETX (0x03) bytes: {etx_count}')
    print(f'  Replacement chars (U+FFFD): {repl_count}')
    print(f'  Literal backslash-x sequences: {bx_count}')
    print(f'  Literal backslash-uXXXX sequences: {bu_count}')

    # For biyoritim, show kosullar values
    if fname == 'biyoritim.json' and json_ok:
        all_kosullar = []
        for key, entries in data.items():
            if not isinstance(entries, list):
                continue
            for e in entries:
                for k in e.get('kosullar', []):
                    for field in ('deger', 'degisken'):
                        v = k.get(field, '')
                        if v:
                            all_kosullar.append(v)
        unique = sorted(set(all_kosullar))
        print(f'  Unique kosullar values ({len(unique)}): {unique}')

    print()
