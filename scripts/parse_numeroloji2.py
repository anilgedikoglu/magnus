import os, sys, re, json, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

BASE = r"C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Numeroloji\Rapor"
OUT  = r"C:\src\magnus_app\assets\data\numeroloji.json"

SECTION_KEYS = {
    '1ifadesayisi': 'ifadesayisi',
    '2ruhsayisi':   'ruhsayisi',
    '3yasamyolu':   'yasamyolusayisi',
    '4sessizbenlik':'sessizbenliksayisi',
    '5olgunluk':    'olgunluksayisi',
    '6dogumgunu':   'dogumgunusayisi',
    '7karmikborc':  'karmikborc',
}
TYPE_KEYS = {'GENEL': 'genel', 'BUGUN': 'bugun', 'BUYIL': 'yil'}

# Escape'li tırnak dahil tüm karakterleri yakalar: (?:[^"\\]|\\.)*
ITEM_RE = re.compile(r'- "((?:[^"\\]|\\.)*)"')

def decode_escape(s):
    result = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == '\\' and i + 1 < len(s):
            nxt = s[i+1]
            if nxt == 'n':
                result.append('\n'); i += 2
            elif nxt == '"':
                result.append('"'); i += 2
            elif nxt == '\\':
                result.append('\\'); i += 2
            elif nxt == 'u' and i + 5 < len(s):
                h = s[i+2:i+6]
                if all(x in '0123456789abcdefABCDEF' for x in h):
                    result.append(chr(int(h, 16))); i += 6
                else:
                    result.append(c); i += 1
            elif nxt == 'x' and i + 3 < len(s):
                h = s[i+2:i+4]
                if all(x in '0123456789abcdefABCDEF' for x in h):
                    result.append(chr(int(h, 16))); i += 4
                else:
                    result.append(c); i += 1
            else:
                result.append(c); i += 1
        else:
            result.append(c); i += 1
    return ''.join(result)


def extract_aciklama(content):
    m = re.search(r'aciklama:(.*?)(?:aciklamaEng:|$)', content, re.DOTALL | re.IGNORECASE)
    if not m:
        return ''
    block = m.group(1)
    items = ITEM_RE.findall(block)
    texts = []
    for raw in items:
        t = decode_escape(raw).strip()
        t = re.sub(r'\n[ \t]+', ' ', t)
        t = re.sub(r'\n{3,}', '\n\n', t)
        t = t.replace('||', '\n\n').strip()
        if t:
            texts.append(t)
    return '\n\n'.join(texts)


def parse_asset(fp):
    with open(fp, 'rb') as f:
        raw = f.read()
    return extract_aciklama(raw.decode('utf-8', errors='replace'))


def get_sec_key(folder):
    lower = folder.lower()
    for prefix, key in SECTION_KEYS.items():
        if lower.startswith(prefix):
            return key
    return None


def parse_type(type_dir):
    result = {}
    for sf in sorted(os.listdir(type_dir)):
        sp = os.path.join(type_dir, sf)
        if not os.path.isdir(sp):
            continue
        sk = get_sec_key(sf)
        if not sk:
            continue
        sec = {}
        for nf in sorted(os.listdir(sp)):
            np_ = os.path.join(sp, nf)
            if not os.path.isdir(np_):
                continue
            m2 = re.match(r'^(\d)', nf)
            if not m2:
                continue
            num = int(m2.group(1))
            if num < 1 or num > 9:
                continue
            assets = [f for f in os.listdir(np_) if f.endswith('.asset')]
            if not assets:
                continue
            sec[str(num)] = parse_asset(os.path.join(np_, assets[0]))
        result[sk] = sec
    return result


output = {}
for tf, tk in TYPE_KEYS.items():
    td = os.path.join(BASE, tf)
    output[tk] = parse_type(td)

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

# Kontrol: kısa veya ters eğik çizgiyle biten metinler
bs = chr(92)
dq = chr(34)
sorunlu = 0
for tk, tval in output.items():
    for sk, sval in tval.items():
        for num, metin in sval.items():
            if metin.endswith(bs) or metin.endswith(dq) or len(metin) < 30:
                sorunlu += 1
                print(f"  [{tk}/{sk}/{num}] son 80: {metin[-80:]!r}")

total = sum(len(v) for t in output.values() for v in t.values())
print(f"Toplam: {total} giris, {sorunlu} sorunlu")
