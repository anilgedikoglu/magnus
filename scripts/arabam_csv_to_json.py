# "Arabam Ne?" havuzu: ChatGPT'nin ürettiği CSV -> assets/data/arabam.json (2026-11-05)
# Kullanım: python -I scripts/arabam_csv_to_json.py <girdi.csv> assets/data/arabam.json
# Sütunlar: marka;model;segment;sinif;yakit;yayginlik;egilim;durum;yil
# Normalize eder, tekrarları atar, doğrular ve dağılımı raporlar.
import csv
import io
import json
import sys
from collections import Counter

SEG = {'sehir', 'kompakt', 'sedan', 'suv_kucuk', 'suv', 'suv_buyuk', 'mpv', 'pickup', 'spor', 'ust_sedan'}
SEG_MAP = {'şehir': 'sehir', 'city': 'sehir', 'hatchback': 'kompakt', 'compact': 'kompakt', 'suv küçük': 'suv_kucuk',
           'kucuk_suv': 'suv_kucuk', 'suv_orta': 'suv', 'buyuk_suv': 'suv_buyuk', 'van': 'mpv', 'ticari_binek': 'mpv',
           'coupe': 'spor', 'cabrio': 'spor', 'ust sedan': 'ust_sedan', 'lux_sedan': 'ust_sedan'}
FUEL = {'benzin': 'benzin', 'dizel': 'dizel', 'hibrit': 'hibrit', 'elektrik': 'elektrik', 'lpg': 'lpg',
        'hybrid': 'hibrit', 'plug-in hibrit': 'hibrit', 'phev': 'hibrit', 'mild hibrit': 'hibrit',
        'electric': 'elektrik', 'ev': 'elektrik', 'gasoline': 'benzin', 'petrol': 'benzin', 'diesel': 'dizel',
        'benzin-lpg': 'lpg', 'benzin/lpg': 'lpg'}
LEAN = {'kadin', 'erkek', 'notr'}
STATUS = {'eski', 'guncel', 'gelecek'}


def norm(s):
    return (s or '').strip()


# ChatGPT listesi tümünü "notr" verdi → Türkiye alıcı algısına göre kaba eğilim (yalnız notr olanlara).
import re
KADIN = re.compile(
    r"\b(500e?|500x|panda|mini|cooper|countryman|aceman|208|2008|clio|captur|yaris|aygo|i10|i20|picanto|"
    r"polo|t-cross|taigo|c3|c4 cactus|corsa|swift|ignis|fortwo|forfour|smart|ds 3|a1|q2|a-serisi|a 1[68]0|"
    r"a 200|gla|1 serisi|116|118|x1|jazz|ibiza|arona|fabia|kamiq|fiesta|puma|micra|juke|kona|stonic|"
    r"twingo|zoe|5 e-tech|ypsilon|e-c3|ami|tivoli|mg3|dolphin|atto)\b", re.I)
ERKEK = re.compile(
    r"\b(ranger|hilux|navara|l200|d-max|amarok|wrangler|defender|land cruiser|pick-?up|gladiator|"
    r"amg gt|\d\d amg|amg \d\d|m3|m4|m5|m8|x5 m|x6 m|rs ?3|rs ?4|rs ?5|rs ?6|rs ?7|rs ?q|gti|golf r|type r|wrx|sti|"
    r"mustang|challenger|charger|gt-r|giulia quadrifoglio|quadrifoglio|cupra formentor vz|vz5|i30 n|"
    r"focus st|st-line x|911|cayman|boxster|ferrari|lamborghini|aston|şahin|doğan|kartal|murat|"
    r"g-?serisi|g 63|g 400|range rover sport|levante|ghibli|grecale trofeo|supra|gr86|brz|mx-5)\b", re.I)


def lean_for(marka, model, segment):
    s = f'{marka} {model}'
    if segment in ('pickup',) or ERKEK.search(s) or marka.lower() in ('ferrari', 'lamborghini', 'aston martin', 'dodge'):
        return 'erkek'
    if KADIN.search(s) or marka.lower() in ('mini', 'smart'):
        return 'kadin'
    return 'notr'


def main(src, dst):
    raw = open(src, 'rb').read().decode('utf-8-sig')
    sample = raw[:2000]
    delim = ';' if sample.count(';') >= sample.count(',') else ','
    rows = list(csv.DictReader(io.StringIO(raw), delimiter=delim))
    out, seen, problems = [], set(), Counter()
    for r in rows:
        r = {norm(k).lower(): norm(v) for k, v in r.items() if k}
        marka, model = r.get('marka', ''), r.get('model', '')
        # "CLA CLA 180 AMG" / "Ami Ami" → baştaki tekrar eden kelimeyi teke indir
        # "AMG GT AMG GT 43" → baştaki 1-3 kelimelik tekrar da teke iner
        w = model.split()
        for k in (3, 2, 1):
            if len(w) >= 2 * k and [x.lower() for x in w[:k]] == [x.lower() for x in w[k:2 * k]]:
                w = w[k:]
                break
        model = ' '.join(w)
        if not marka or not model:
            problems['bos'] += 1
            continue
        seg = r.get('segment', '').lower().replace(' ', '_')
        seg = SEG_MAP.get(seg, seg)
        if seg not in SEG:
            problems['segment:' + seg] += 1
            seg = 'kompakt'
        try:
            sinif = max(1, min(7, int(float(r.get('sinif', '0')))))
        except ValueError:
            problems['sinif'] += 1
            continue
        yakit = FUEL.get(r.get('yakit', '').lower())
        if not yakit:
            problems['yakit:' + r.get('yakit', '')] += 1
            continue
        try:
            yay = max(1, min(10, int(float(r.get('yayginlik', '5')))))
        except ValueError:
            yay = 5
        eg = r.get('egilim', 'notr').lower().replace('ı', 'i').replace('ö', 'o')
        eg = eg if eg in LEAN else 'notr'
        if eg == 'notr':
            eg = lean_for(marka, model, seg)
        du = r.get('durum', 'guncel').lower().replace('ü', 'u')
        du = du if du in STATUS else 'guncel'
        yil = None
        if du == 'gelecek':
            try:
                yil = int(float(r.get('yil', '') or 2028))
            except ValueError:
                yil = 2028
        key = (marka.lower(), model.lower())
        if key in seen:
            problems['tekrar'] += 1
            continue
        seen.add(key)
        e = {'marka': marka, 'model': model, 'segment': seg, 'sinif': sinif, 'yakit': yakit,
             'yayginlik': yay, 'egilim': eg, 'durum': du}
        if yil is not None:
            e['yil'] = yil
        out.append(e)
    out.sort(key=lambda e: (e['sinif'], e['marka'].lower(), e['model'].lower()))
    for i, e in enumerate(out, 1):
        e['id'] = i
    data = {'arabalar': [{'id': e.pop('id'), **e} for e in out]}
    with open(dst, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=0)
    n = len(out)
    cls = Counter(e['sinif'] for e in out)
    print('satir', len(rows), '-> model', n)
    print('sinif', dict(sorted(cls.items())), 'sinif1-3 %', round(100 * sum(cls[k] for k in (1, 2, 3)) / n, 1),
          'sinif6-7 %', round(100 * (cls[6] + cls[7]) / n, 1))
    print('yakit', dict(Counter(e['yakit'] for e in out)))
    print('durum', dict(Counter(e['durum'] for e in out)))
    print('marka sayisi', len({e['marka'] for e in out}))
    print('sorunlar', dict(problems))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
