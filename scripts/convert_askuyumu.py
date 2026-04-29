"""
Aşk Uyumu — Unity .asset → Flutter JSON dönüştürücü
Kaynak: C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/AskUyumu/
Çıktı:  C:/src/magnus_app/assets/data/askuyumu.json
"""

import os
import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

SRC_ROOT = "C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/AskUyumu"
OUT_FILE = "C:/src/magnus_app/assets/data/askuyumu.json"

# ─── Burç tespiti ────────────────────────────────────────────────────────────

_BURC_MAP = {
    'akrep': 'Akrep', 'aslan': 'Aslan', 'balik': 'Balık',
    'basak': 'Başak', 'boga': 'Boğa', 'koc': 'Koç',
    'kova': 'Kova', 'oglak': 'Oğlak', 'terazi': 'Terazi',
    'yay': 'Yay', 'yengec': 'Yengeç', 'ikizler': 'İkizler',
}

def _norm(s):
    return s.lower().replace('ğ','g').replace('ş','s').replace('ç','c') \
                    .replace('ı','i').replace('ö','o').replace('ü','u')

def extract_burc(filename):
    """Dosya adından burç adını çıkarır (içerik eşleşmesi)."""
    name = _norm(filename.replace('.asset', ''))
    for key, val in _BURC_MAP.items():
        if key in name:
            return val
    return None

# ─── decode_escapes ──────────────────────────────────────────────────────────

def decode_escapes(s):
    result = []; i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i + 1]
            if nxt == 'u' and i + 5 <= len(s):
                try:
                    result.append(chr(int(s[i+2:i+6], 16))); i += 6; continue
                except Exception:
                    pass
            elif nxt == 'x' and i + 3 <= len(s):
                try:
                    result.append(chr(int(s[i+2:i+4], 16))); i += 4; continue
                except Exception:
                    pass
            elif nxt == 'n':
                result.append('\n'); i += 2; continue
            elif nxt == '"':
                result.append('"'); i += 2; continue
            elif nxt == '\\':
                result.append('\\'); i += 2; continue
        result.append(s[i]); i += 1
    return ''.join(result)

# ─── parse_asset: bir .asset dosyasından içerik metni döndür ────────────────

def parse_asset(filepath):
    """Tek bir .asset dosyasını parse eder; metin listesi döndürür."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            raw = f.read()
    except Exception:
        return []

    m = re.search(r'aciklama:(.*?)aciklamaEng:', raw, re.DOTALL)
    if not m:
        return []
    block = m.group(1)

    items = re.findall(r'-\s+"((?:[^"\\\r\n]|\\[^\r\n]|[\r\n])*?)"', block)
    results = []
    for item in items:
        t = decode_escapes(item)
        t = re.sub(r'\n[ \t]+', ' ', t)
        t = t.replace('\r', '')
        t = t.strip().strip('"')
        # Barmenu prefix
        t = re.sub(r'^\{\{barmenu\}\}', '', t).strip()
        if not t:
            continue
        # Parse JSON payload
        try:
            data = json.loads(t)
            content = data['bars'][0]['explanations'][0]['content']
            content = content.strip()
            # sprite referanslarını kaldır (metin sonundaki emoji işaretçileri)
            content = re.sub(r'\s*<sprite=\d+>?', '', content).strip()
            if len(content) < 20:
                continue
            results.append(content)
        except Exception:
            continue
    return results

# ─── parse_asset_plain: JSON olmayan düz aciklama metinleri (uyum dosyaları) ─

def parse_asset_plain(filepath):
    """Uyum .asset dosyaları için — düz metin (JSON değil) okur."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            raw = f.read()
    except Exception:
        return []

    m = re.search(r'aciklama:(.*?)aciklamaEng:', raw, re.DOTALL)
    if not m:
        return []
    block = m.group(1)

    items = re.findall(r'-\s+"((?:[^"\\\r\n]|\\[^\r\n]|[\r\n])*?)"', block)
    results = []
    for item in items:
        t = decode_escapes(item)
        t = re.sub(r'\n[ \t]+', ' ', t)
        t = t.replace('\r', '')
        t = t.strip().strip('"')
        if len(t) < 20:
            continue
        results.append(t)
    return results

# ─── ID counter ──────────────────────────────────────────────────────────────

_id_counter = 0

def next_id():
    global _id_counter
    _id_counter += 1
    return _id_counter

# ─── Bar categories ──────────────────────────────────────────────────────────

BAR_DIRS = {
    'ask':       'BarAskUyumu',
    'aile':      'BarAileUyumu',
    'maddi':     'BarMaddiUyum',
    'ten':       'BarTenUyumu',
    'vizyon':    'BarVizyonUyumu',
    'iletisim':  'BarIletisimUyumu',
}
RANGES = ['0-25', '25-50', '50-75', '75-100']

def collect_bars():
    bars = {}
    total_files = 0
    total_errors = 0

    for key, dirname in BAR_DIRS.items():
        bars[key] = {}
        bar_dir = os.path.join(SRC_ROOT, dirname)
        if not os.path.isdir(bar_dir):
            print(f"  UYARI: {bar_dir} bulunamadı")
            for r in RANGES:
                bars[key][r] = []
            continue

        for rng in RANGES:
            rng_dir = os.path.join(bar_dir, rng)
            entries = []
            if not os.path.isdir(rng_dir):
                bars[key][rng] = []
                continue

            files = [f for f in os.listdir(rng_dir) if f.endswith('.asset')]
            for fname in sorted(files):
                total_files += 1
                fpath = os.path.join(rng_dir, fname)
                texts = parse_asset(fpath)
                if not texts:
                    total_errors += 1
                for t in texts:
                    entries.append({"id": next_id(), "metin": t})
            bars[key][rng] = entries

    return bars, total_files, total_errors

# ─── Uyum categories ─────────────────────────────────────────────────────────

UYUM_DIRS = {
    'evli': {
        'folder': 'UyumDosyalarEvli',
        'subdirs': [
            'UyEsBurclarEvli',
            'UyOkulBurclarEvli',
            'UySevgiliBurclarEvli',
            'UyTanidikBurclarEvli',
            'UyisBurclarEvli',
        ],
        'skip_suffix': None,
    },
    'iliskisivar': {
        'folder': 'UyumDosyalariliskisivar',
        'subdirs': None,  # dinamik — "YOK" ile biten dizinleri atla
        'skip_suffix': 'YOK',
    },
    'iliskisiyok': {
        'folder': 'UyumDosyalariliskisiyok',
        'subdirs': None,
        'skip_suffix': 'YOK',
    },
}

def collect_uyum():
    uyum = {}
    total_files = 0
    total_errors = 0

    for key, cfg in UYUM_DIRS.items():
        folder = os.path.join(SRC_ROOT, cfg['folder'])
        entries = []

        if not os.path.isdir(folder):
            print(f"  UYARI: {folder} bulunamadı")
            uyum[key] = []
            continue

        # Alt klasörleri belirle
        if cfg['subdirs'] is not None:
            subdirs = cfg['subdirs']
        else:
            # dinamik liste — "YOK" ile bitenleri atla
            subdirs = []
            try:
                for d in os.listdir(folder):
                    dpath = os.path.join(folder, d)
                    if os.path.isdir(dpath):
                        if cfg['skip_suffix'] and d.endswith(cfg['skip_suffix']):
                            continue
                        subdirs.append(d)
            except Exception:
                pass

        for subdir in subdirs:
            subpath = os.path.join(folder, subdir)
            if not os.path.isdir(subpath):
                continue
            files = [f for f in os.listdir(subpath) if f.endswith('.asset')]
            for fname in sorted(files):
                total_files += 1
                fpath = os.path.join(subpath, fname)
                texts = parse_asset(fpath)
                if not texts:
                    total_errors += 1
                burc = extract_burc(fname)
                for t in texts:
                    entry = {"id": next_id(), "metin": t}
                    if burc:
                        entry["burc"] = burc
                    entries.append(entry)

        uyum[key] = entries

    return uyum, total_files, total_errors

# ─── Anlam kontrolü ──────────────────────────────────────────────────────────

BITIS_NOKTALARI = {'.', '!', '?', '…', '"', "'", ')', '}', ':'}

def check_texts(all_entries):
    sorunlu = []
    for entry in all_entries:
        metin = entry['metin']
        son = metin.rstrip()
        son_char = son[-1] if son else ''
        if son_char not in BITIS_NOKTALARI:
            sorunlu.append((entry['id'], metin[-120:]))
    return sorunlu

# ─── MAIN ─────────────────────────────────────────────────────────────────────

def main():
    print("=== Aşk Uyumu dönüştürücü ===\n")

    print("Bar metinleri toplanıyor...")
    bars, bar_files, bar_errors = collect_bars()

    print("Uyum metinleri toplanıyor...")
    uyum, uyum_files, uyum_errors = collect_uyum()

    # İstatistikler
    total_bar_entries = sum(
        len(entries)
        for cat in bars.values()
        for entries in cat.values()
    )
    total_uyum_entries = sum(len(v) for v in uyum.values())
    print(f"\nBar: {bar_files} dosya işlendi, {bar_errors} hatalı, {total_bar_entries} metin")
    print(f"Uyum: {uyum_files} dosya işlendi, {uyum_errors} hatalı, {total_uyum_entries} metin")

    # Detay
    print("\nBar dağılımı:")
    for key, ranges in bars.items():
        for rng, entries in ranges.items():
            print(f"  bars.{key}.{rng}: {len(entries)} metin")

    print("\nUyum dağılımı:")
    for key, entries in uyum.items():
        print(f"  uyum.{key}: {len(entries)} metin")

    # Anlam kontrolü
    all_entries = (
        [e for cat in bars.values() for rng_list in cat.values() for e in rng_list]
        + [e for v in uyum.values() for e in v]
    )
    sorunlu = check_texts(all_entries)
    if sorunlu:
        print(f"\nUYARI: {len(sorunlu)} kesilmiş/sorunlu metin:")
        for eid, parca in sorunlu[:20]:
            print(f"  [{eid}] ...{parca!r}")
    else:
        print("\nAnlam kontrolü: Tüm metinler düzgün bitiyor. ✓")

    # JSON kaydet
    output = {"bars": bars, "uyum": uyum}
    os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)
    with open(OUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"\nKaydedildi: {OUT_FILE}")
    print(f"Toplam ID sayısı: {_id_counter}")

if __name__ == '__main__':
    main()
