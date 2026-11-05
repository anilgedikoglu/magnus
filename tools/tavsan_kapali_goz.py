# Tavşan Falı: göz kırpma için "kapalı göz" katmanı üretir (Anıl, 2026-11-06).
#   python -I tools/tavsan_kapali_goz.py <proje_kökü>
# Girdi : assets/images/tavsanfali/tavsan.png (505x640)
# Çıktı : assets/images/tavsanfali/tavsan_goz_kapali.png (aynı boyut, yalnız göz bölgeleri dolu)
# Yöntem: göz elipsi, iki göz arasındaki temiz kürkten kaydırılmış kopya ile doldurulur;
# renk/parlaklık gözün hemen dışındaki halkaya eşlenir; kenar yumuşatılır; kapak kıvrımı
# gölgesi + kirpik çizgisi (göz yüksekliğinin ~%58'i) çizilir.
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

root = sys.argv[1]
src = Image.open(os.path.join(root, 'assets/images/tavsanfali/tavsan.png')).convert('RGBA')
A = np.asarray(src).astype(np.float32)
H, W = A.shape[:2]
out = np.zeros_like(A)

# (merkez x, merkez y, yarıçap x, yarıçap y, kürk kaynağı x kayması) — görsel pikseli
EYES = [(201.5, 240.5, 24.5, 27.0, +48), (310.0, 240.5, 22.0, 27.0, -48)]
DY = 12  # kürk kaynağı biraz aşağıdan (ortadaki zincir ucunu almasın)

yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
for cx, cy, rx, ry, shift in EYES:
    d = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
    inside = d <= 1.0
    ring = (d > 1.15) & (d <= 1.6)
    # Kürk kaynağı: yatay kaydırılmış kopya (iki göz arası temiz kürk).
    up = np.roll(np.roll(A, -shift, axis=1), -DY, axis=0)   # üst yarı: zincir ucundan uzak
    lo = np.roll(A, -shift, axis=1)                          # alt yarı: burun pembesinden uzak
    wlo = np.clip((yy - cy + 4) / 8, 0, 1)[..., None]
    patch = up * (1 - wlo) + lo * wlo
    # Renk eşleme: halka ortalaması / kaynak ortalaması (kanal kanal).
    ring_mean = A[ring][:, :3].mean(axis=0)
    src_mean = patch[inside][:, :3].mean(axis=0)
    gain = ring_mean / np.maximum(src_mean, 1)
    fill = patch.copy()
    fill[..., :3] = np.clip(patch[..., :3] * gain, 0, 255)
    # Hafif dikey gölge: göz çukuru (üst ve kirpik çevresi biraz koyu).
    t = np.clip((yy - (cy - ry)) / (2 * ry), 0, 1)
    shade = 1.0 - 0.10 * np.exp(-((t - 0.58) / 0.12) ** 2) - 0.05 * (1 - t)
    fill[..., :3] *= shade[..., None]
    # Yumuşak maske (elips + 1.6 px bulanık kenar).
    m = Image.new('L', (W, H), 0)
    ImageDraw.Draw(m).ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
    m = np.asarray(m.filter(ImageFilter.GaussianBlur(2.4))).astype(np.float32) / 255
    # Düz (premultiplied DEĞİL) alfa: renk = dolgu, saydamlık = maske (yoksa kenar koyulaşır).
    out[..., :3] = np.where(m[..., None] > 0, fill[..., :3], out[..., :3])
    out[..., 3] = np.maximum(out[..., 3], m * 255)

img = Image.fromarray(out.astype(np.uint8), 'RGBA')
# Kirpik çizgisi: aşağı kavisli yay, dış köşede kısa kirpikler. 4x çizip küçült (yumuşak kenar).
S = 4
big = Image.new('RGBA', (W * S, H * S), (0, 0, 0, 0))
dr = ImageDraw.Draw(big)
for i, (cx, cy, rx, ry, _) in enumerate(EYES):
    y0 = cy - ry + 2 * ry * 0.58
    pts = []
    for k in range(41):
        u = -1 + 2 * k / 40
        x = cx + u * rx * 0.80
        y = y0 + (1 - u * u) * ry * 0.20
        pts.append((x * S, y * S))
    dr.line(pts, fill=(58, 30, 66, 235), width=int(2.6 * S), joint='curve')
    # dış köşe kirpikleri (sol gözde solda, sağ gözde sağda)
    side = -1 if i == 0 else 1
    for j in range(3):
        u = side * (0.62 + 0.14 * j)
        x = cx + u * rx * 0.80
        y = y0 + (1 - u * u) * ry * 0.20
        dr.line([(x * S, y * S), ((x + side * 2.2) * S, (y + 3.2 + j * 0.6) * S)],
                fill=(58, 30, 66, 210), width=int(1.3 * S))
lash = big.resize((W, H), Image.LANCZOS)
img.alpha_composite(lash)
dst = os.path.join(root, 'assets/images/tavsanfali/tavsan_goz_kapali.png')
img.save(dst, optimize=True)
print('yazildi', dst, os.path.getsize(dst))
