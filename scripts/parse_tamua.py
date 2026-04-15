# parse_tamua.py — Tamua .asset dosyalarini JSON'a donusturur
import os, json, re

BASE = "C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu1/Kehanet/Tamua/Sohbetler"
OUT  = "C:/src/magnus_app/assets/data/tamua.json"

KLASORLER = {
    "olacak":     "Olacak",
    "olacakh":    "OlacakH",
    "olacakl":    "OlacakL",
    "olmayacak":  "Olmayacak",
    "olmayacakh": "OlmayacakH",
    "olmayacakl": "OlmayacakL",
}

def decode_escapes(s):
    result = []
    i = 0
    while i < len(s):
        if s[i] == chr(92) and i + 1 < len(s):
            nx = s[i+1]
            if nx == 'u' and i + 5 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+6], 16)))
                    i += 6; continue
                except Exception:
                    pass
            elif nx == 'x' and i + 3 < len(s):
                try:
                    result.append(chr(int(s[i+2:i+4], 16)))
                    i += 4; continue
                except Exception:
                    pass
            elif nx == 'n':
                result.append('\n'); i += 2; continue
            elif nx == '"':
                result.append('"'); i += 2; continue
            elif nx == chr(92):
                result.append(chr(92)); i += 2; continue
        result.append(s[i])
        i += 1
    return ''.join(result)

def parse_aciklama(lines, start_idx):
    """
    aciklama: bloğunu okur. Hem tek satırlı hem çok satırlı YAML değerleri:
      - "İlk satır
        devam satırı!"
    Devam satırları 4+ boşlukla girintili (list item'ın devamı).
    """
    raw_parts = []
    in_item = False
    i = start_idx + 1
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        # Sonraki bilinen anahtara gelince dur
        if stripped.startswith('aciklamaEng:'):
            break
        # Yeni bir YAML anahtarı: satır başında az girintili ve ':' içeriyor
        leading = len(line) - len(line.lstrip(' '))
        if stripped and not stripped.startswith('-') and not stripped.startswith('"'):
            if leading <= 2 and ':' in stripped:
                break
        # List item başlangıcı
        if stripped.startswith('- '):
            raw_parts.append(stripped[2:])
            in_item = True
        elif stripped == '-':
            in_item = True
        # Devam satırı: 4+ girintili, list item içindeyiz
        elif in_item and leading >= 4 and stripped:
            raw_parts.append(stripped)
        i += 1
    raw = ' '.join(raw_parts).strip()
    # Başlangıç/bitiş çift tırnaklarını kaldır
    if len(raw) >= 2 and raw[0] == '"' and raw[-1] == '"':
        raw = raw[1:-1]
    text = decode_escapes(raw)
    text = re.sub(r'\n +', ' ', text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()

result = {}
global_id = 1

for anahtar, klasor_adi in KLASORLER.items():
    klasor_yolu = os.path.join(BASE, klasor_adi)
    dosyalar = sorted([f for f in os.listdir(klasor_yolu) if f.endswith('.asset')])
    metinler = []
    ses_index = 1  # klasör içindeki sıra → ses dosyası numarası
    for dosya in dosyalar:
        yol = os.path.join(klasor_yolu, dosya)
        with open(yol, encoding='utf-8', errors='replace') as f:
            lines = [l.rstrip('\n') for l in f.readlines()]
        for idx, line in enumerate(lines):
            if line.strip() == 'aciklama:':
                metin = parse_aciklama(lines, idx)
                if metin:
                    metinler.append({
                        "id": global_id,
                        "ses_index": ses_index,   # 1 → sektör.mp3, 2 → sektör2.mp3 …
                        "metin": metin,
                        "kosullar": []
                    })
                    global_id += 1
                    ses_index  += 1
                break
    result[anahtar] = metinler
    print(f"{anahtar}: {len(metinler)} metin")

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump({"tamua": result}, f, ensure_ascii=False, indent=2)

print(f"\nJSON kaydedildi: {OUT}")
print(f"Toplam metin: {global_id - 1}")
